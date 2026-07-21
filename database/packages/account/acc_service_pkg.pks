CREATE OR REPLACE PACKAGE acc_service_pkg AS
  -- Casos de uso da entidade ACCOUNT.
  -- Coordena regras, credenciais e persistencia sem executar SQL ou controlar
  -- transacoes.

  FUNCTION create_account(
    p_email      IN VARCHAR2,
    p_password   IN VARCHAR2,
    p_created_by IN NUMBER DEFAULT NULL
  ) RETURN BEX_ACCOUNT%ROWTYPE;

  PROCEDURE change_password(
    p_account_id IN NUMBER,
    p_password   IN VARCHAR2
  );

  FUNCTION get_account(
    p_account_id IN NUMBER
  ) RETURN BEX_ACCOUNT%ROWTYPE;

  FUNCTION email_available(
    p_email IN VARCHAR2
  ) RETURN BOOLEAN;
END acc_service_pkg;
/
