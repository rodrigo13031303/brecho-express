CREATE OR REPLACE PACKAGE acc_repository_pkg AS
  -- Camada de persistencia da entidade ACCOUNT.
  -- Recebe valores preparados e executa somente SQL sobre BEX_ACCOUNT.

  PROCEDURE insert_account(
    p_public_id           IN BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE,
    p_email               IN BEX_ACCOUNT.ACC_EMAIL%TYPE,
    p_email_verified_at   IN BEX_ACCOUNT.ACC_EMAIL_VERIFIED_AT%TYPE,
    p_credential          IN BEX_ACCOUNT.ACC_PASSWORD_HASH%TYPE,
    p_password_changed_at IN BEX_ACCOUNT.ACC_PASSWORD_CHANGED_AT%TYPE,
    p_status              IN BEX_ACCOUNT.ACC_STATUS%TYPE,
    p_last_login_at       IN BEX_ACCOUNT.ACC_LAST_LOGIN_AT%TYPE,
    p_created_by          IN BEX_ACCOUNT.ACC_CREATED_BY%TYPE,
    p_updated_by          IN BEX_ACCOUNT.ACC_UPDATED_BY%TYPE
  );

  PROCEDURE update_account(
    p_account_id        IN NUMBER,
    p_email             IN VARCHAR2,
    p_email_verified_at IN TIMESTAMP,
    p_status            IN VARCHAR2,
    p_updated_by        IN NUMBER
  );

  PROCEDURE update_password(
    p_account_id IN NUMBER,
    p_credential IN VARCHAR2
  );

  FUNCTION get_by_id(
    p_account_id IN NUMBER
  ) RETURN BEX_ACCOUNT%ROWTYPE;

  FUNCTION get_by_public_id(
    p_public_id IN BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE
  ) RETURN BEX_ACCOUNT%ROWTYPE;

  FUNCTION get_by_email(
    p_email IN VARCHAR2
  ) RETURN BEX_ACCOUNT%ROWTYPE;

  FUNCTION email_exists(
    p_email IN VARCHAR2
  ) RETURN BOOLEAN;
END acc_repository_pkg;
/
