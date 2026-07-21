CREATE OR REPLACE PACKAGE pfl_rule_pkg AS
  -- PROFILE representa os dados pessoais e de apresentação associados a uma
  -- ACCOUNT. Esta package preserva exclusivamente as invariantes do domínio
  -- PROFILE e nunca executa persistência ou altera estado.
  -- O domínio é independente de transporte, JSON, ORDS e clientes externos.

  -- Exceções conhecidas do domínio PROFILE.
  -- A camada superior será responsável por traduzi-las para erros públicos.

  e_invalid_display_name  EXCEPTION;
  e_invalid_full_name     EXCEPTION;
  e_invalid_birth_date    EXCEPTION;
  e_invalid_locale_code   EXCEPTION;
  e_invalid_timezone_name EXCEPTION;

  -- Normalização
  -- Produz representações canônicas e idempotentes dos nomes do domínio.

  FUNCTION normalize_display_name(
    p_display_name IN VARCHAR2
  ) RETURN VARCHAR2;

  FUNCTION normalize_full_name(
    p_full_name IN VARCHAR2
  ) RETURN VARCHAR2;

  -- Validações
  -- Protegem as invariantes dos dados pessoais e de apresentação do PROFILE.

  PROCEDURE validate_display_name(
    p_display_name IN VARCHAR2
  );

  PROCEDURE validate_full_name(
    p_full_name IN VARCHAR2
  );

  PROCEDURE validate_birth_date(
    p_birth_date IN DATE
  );

  PROCEDURE validate_locale_code(
    p_locale_code IN VARCHAR2
  );

  PROCEDURE validate_timezone_name(
    p_timezone_name IN VARCHAR2
  );
END pfl_rule_pkg;
/
