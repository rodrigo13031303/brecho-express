CREATE OR REPLACE PACKAGE acc_rule_pkg AS
  -- ACCOUNT representa a identidade técnica da plataforma.
  -- PROFILE representa a identidade da pessoa.
  -- Esta package preserva as invariantes do Aggregate ACCOUNT e nunca altera
  -- estado persistente. Alterações de estado pertencem aos casos de uso
  -- implementados em ACC_API_PKG.
  -- O domínio é independente de transporte, autenticação, JWT, OAuth, ORDS e
  -- Flutter.

  -- Exceções conhecidas do domínio ACCOUNT.
  -- ACC_API_PKG será responsável por traduzi-las para erros públicos.

  e_account_not_found         EXCEPTION;
  e_email_already_used        EXCEPTION;
  e_invalid_email             EXCEPTION;
  e_invalid_password          EXCEPTION;
  e_invalid_public_id         EXCEPTION;
  e_invalid_status            EXCEPTION;
  e_invalid_status_transition EXCEPTION;

  -- Normalização
  -- Produz representações canônicas e idempotentes de valores do domínio.

  FUNCTION normalize_email(
    p_email IN VARCHAR2
  ) RETURN VARCHAR2;

  -- Validações
  -- Protegem invariantes e lançam exceções conhecidas para valores inválidos.

  PROCEDURE validate_email(
    p_email IN VARCHAR2
  );

  PROCEDURE validate_password(
    p_password IN VARCHAR2
  );

  PROCEDURE validate_public_id(
    p_public_id IN VARCHAR2
  );

  PROCEDURE validate_status(
    p_status IN VARCHAR2
  );

  PROCEDURE validate_status_transition(
    p_current_status IN VARCHAR2,
    p_new_status     IN VARCHAR2
  );

  -- Predicados
  -- Apenas respondem perguntas do domínio, sem persistência ou efeitos laterais.

  FUNCTION is_valid_email(
    p_email IN VARCHAR2
  ) RETURN BOOLEAN;

  FUNCTION is_valid_public_id(
    p_public_id IN VARCHAR2
  ) RETURN BOOLEAN;

  FUNCTION is_valid_status(
    p_status IN VARCHAR2
  ) RETURN BOOLEAN;

  FUNCTION is_active(
    p_status IN VARCHAR2
  ) RETURN BOOLEAN;

  FUNCTION is_blocked(
    p_status IN VARCHAR2
  ) RETURN BOOLEAN;

  FUNCTION is_disabled(
    p_status IN VARCHAR2
  ) RETURN BOOLEAN;

  -- Asserções
  -- Avaliam resultados produzidos por outras camadas; não executam consultas
  -- nem persistência.

  PROCEDURE assert_email_available(
    p_exists IN BOOLEAN
  );

  PROCEDURE assert_account_exists(
    p_exists IN BOOLEAN
  );
END acc_rule_pkg;
/
