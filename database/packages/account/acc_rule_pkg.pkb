CREATE OR REPLACE PACKAGE BODY acc_rule_pkg AS
  ------------------------------------------------------------------------------
  -- Constantes privadas
  ------------------------------------------------------------------------------

  c_email_max_length    CONSTANT PLS_INTEGER := 255;
  c_password_min_length CONSTANT PLS_INTEGER := 8;
  c_password_max_length CONSTANT PLS_INTEGER := 128;
  c_public_id_length    CONSTANT PLS_INTEGER := 32;

  c_status_pending_email CONSTANT VARCHAR2(30) :=
    'PENDING_EMAIL_VERIFICATION';
  c_status_active   CONSTANT VARCHAR2(30) := 'ACTIVE';
  c_status_blocked  CONSTANT VARCHAR2(30) := 'BLOCKED';
  c_status_disabled CONSTANT VARCHAR2(30) := 'DISABLED';

  ------------------------------------------------------------------------------
  -- Helpers privados
  ------------------------------------------------------------------------------

  FUNCTION normalize_status(
    p_status IN VARCHAR2
  ) RETURN VARCHAR2 IS
  BEGIN
    RETURN UPPER(TRIM(p_status));
  END normalize_status;

  ------------------------------------------------------------------------------
  -- Normalização
  ------------------------------------------------------------------------------

  -- Apenas normaliza o e-mail. Não valida e é idempotente.
  FUNCTION normalize_email(
    p_email IN VARCHAR2
  ) RETURN VARCHAR2 IS
  BEGIN
    RETURN LOWER(TRIM(p_email));
  END normalize_email;

  ------------------------------------------------------------------------------
  -- Predicados
  ------------------------------------------------------------------------------

  FUNCTION is_valid_email(
    p_email IN VARCHAR2
  ) RETURN BOOLEAN IS
    l_email       VARCHAR2(32767);
    l_at_position PLS_INTEGER;
    l_local_part VARCHAR2(32767);
    l_domain     VARCHAR2(32767);
  BEGIN
    l_email := normalize_email(p_email);

    IF l_email IS NULL
       OR LENGTH(l_email) > c_email_max_length
       OR REGEXP_LIKE(l_email, '[[:space:]]') THEN
      RETURN FALSE;
    END IF;

    l_at_position := INSTR(l_email, '@');

    IF l_at_position <= 1
       OR l_at_position = LENGTH(l_email)
       OR INSTR(l_email, '@', l_at_position + 1) > 0 THEN
      RETURN FALSE;
    END IF;

    l_local_part := SUBSTR(l_email, 1, l_at_position - 1);
    l_domain := SUBSTR(l_email, l_at_position + 1);

    -- Validação simplificada utilizada pelo domínio.
    -- Não pretende implementar integralmente todos os RFCs de e-mail.
    IF SUBSTR(l_local_part, 1, 1) = '.'
       OR SUBSTR(l_local_part, -1, 1) = '.'
       OR INSTR(l_local_part, '..') > 0
       OR NOT REGEXP_LIKE(
                l_local_part,
                '^[A-Z0-9.!#$%&''*+/=?^_`{|}~-]+$',
                'i'
              ) THEN
      RETURN FALSE;
    END IF;

    IF INSTR(l_domain, '.') = 0
       OR SUBSTR(l_domain, 1, 1) = '.'
       OR SUBSTR(l_domain, -1, 1) = '.'
       OR INSTR(l_domain, '..') > 0
       OR NOT REGEXP_LIKE(
                l_domain,
                '^[A-Z0-9]([A-Z0-9-]*[A-Z0-9])?([.][A-Z0-9]([A-Z0-9-]*[A-Z0-9])?)+$',
                'i'
              ) THEN
      RETURN FALSE;
    END IF;

    RETURN TRUE;
  END is_valid_email;

  FUNCTION is_valid_public_id(
    p_public_id IN VARCHAR2
  ) RETURN BOOLEAN IS
  BEGIN
    RETURN p_public_id IS NOT NULL
       AND LENGTH(p_public_id) = c_public_id_length
       AND REGEXP_LIKE(p_public_id, '^[0-9A-F]{32}$', 'i');
  END is_valid_public_id;

  FUNCTION is_valid_status(
    p_status IN VARCHAR2
  ) RETURN BOOLEAN IS
    l_status VARCHAR2(30);
  BEGIN
    l_status := normalize_status(p_status);

    RETURN l_status IS NOT NULL
       AND l_status IN (
             c_status_pending_email,
             c_status_active,
             c_status_blocked,
             c_status_disabled
           );
  END is_valid_status;

  ------------------------------------------------------------------------------
  -- Validações
  ------------------------------------------------------------------------------

  PROCEDURE validate_email(
    p_email IN VARCHAR2
  ) IS
  BEGIN
    IF NOT is_valid_email(p_email) THEN
      RAISE e_invalid_email;
    END IF;
  END validate_email;

  PROCEDURE validate_password(
    p_password IN VARCHAR2
  ) IS
  BEGIN
    IF p_password IS NULL
       OR LENGTH(p_password) < c_password_min_length
       OR LENGTH(p_password) > c_password_max_length THEN
      RAISE e_invalid_password;
    END IF;
  END validate_password;

  PROCEDURE validate_public_id(
    p_public_id IN VARCHAR2
  ) IS
  BEGIN
    IF NOT is_valid_public_id(p_public_id) THEN
      RAISE e_invalid_public_id;
    END IF;
  END validate_public_id;

  PROCEDURE validate_status(
    p_status IN VARCHAR2
  ) IS
  BEGIN
    IF NOT is_valid_status(p_status) THEN
      RAISE e_invalid_status;
    END IF;
  END validate_status;

  ------------------------------------------------------------------------------
  -- Predicados de estado
  ------------------------------------------------------------------------------

  FUNCTION is_active(
    p_status IN VARCHAR2
  ) RETURN BOOLEAN IS
    l_status VARCHAR2(30);
  BEGIN
    l_status := normalize_status(p_status);

    RETURN l_status IS NOT NULL
       AND l_status = c_status_active;
  END is_active;

  FUNCTION is_blocked(
    p_status IN VARCHAR2
  ) RETURN BOOLEAN IS
    l_status VARCHAR2(30);
  BEGIN
    l_status := normalize_status(p_status);

    RETURN l_status IS NOT NULL
       AND l_status = c_status_blocked;
  END is_blocked;

  FUNCTION is_disabled(
    p_status IN VARCHAR2
  ) RETURN BOOLEAN IS
    l_status VARCHAR2(30);
  BEGIN
    l_status := normalize_status(p_status);

    RETURN l_status IS NOT NULL
       AND l_status = c_status_disabled;
  END is_disabled;

  ------------------------------------------------------------------------------
  -- Transições de status
  ------------------------------------------------------------------------------

  -- Representa a matriz oficial de transições do domínio ACCOUNT.
  PROCEDURE validate_status_transition(
    p_current_status IN VARCHAR2,
    p_new_status     IN VARCHAR2
  ) IS
    l_current_status VARCHAR2(30);
    l_new_status     VARCHAR2(30);
  BEGIN
    validate_status(p_current_status);
    validate_status(p_new_status);

    l_current_status := normalize_status(p_current_status);
    l_new_status := normalize_status(p_new_status);

    IF l_current_status = l_new_status THEN
      RETURN;
    END IF;

    IF (l_current_status = c_status_pending_email
        AND l_new_status = c_status_active)
       OR (l_current_status = c_status_active
           AND l_new_status = c_status_blocked)
       OR (l_current_status = c_status_blocked
           AND l_new_status = c_status_active)
       OR (l_current_status = c_status_active
           AND l_new_status = c_status_disabled)
       OR (l_current_status = c_status_blocked
           AND l_new_status = c_status_disabled)
       OR (l_current_status = c_status_disabled
           AND l_new_status = c_status_active) THEN
      RETURN;
    END IF;

    RAISE e_invalid_status_transition;
  END validate_status_transition;

  ------------------------------------------------------------------------------
  -- Asserções
  ------------------------------------------------------------------------------

  -- Recebem resultados produzidos por outra camada.
  -- Nunca executam consultas nem acessam persistência.
  PROCEDURE assert_email_available(
    p_exists IN BOOLEAN
  ) IS
  BEGIN
    IF p_exists IS NULL THEN
      RAISE VALUE_ERROR;
    ELSIF p_exists THEN
      RAISE e_email_already_used;
    END IF;
  END assert_email_available;

  PROCEDURE assert_account_exists(
    p_exists IN BOOLEAN
  ) IS
  BEGIN
    IF p_exists IS NULL THEN
      RAISE VALUE_ERROR;
    ELSIF NOT p_exists THEN
      RAISE e_account_not_found;
    END IF;
  END assert_account_exists;
END acc_rule_pkg;
/
