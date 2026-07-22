CREATE OR REPLACE PACKAGE BODY acc_repository_pkg AS
  ------------------------------------------------------------------------------
  -- Insercao
  ------------------------------------------------------------------------------

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
  ) IS
  BEGIN
    INSERT INTO BEX_ACCOUNT
    (
      ACC_PUBLIC_ID,
      ACC_EMAIL,
      ACC_EMAIL_VERIFIED_AT,
      ACC_PASSWORD_HASH,
      ACC_PASSWORD_CHANGED_AT,
      ACC_STATUS,
      ACC_LAST_LOGIN_AT,
      ACC_CREATED_BY,
      ACC_UPDATED_BY
    )
    VALUES
    (
      p_public_id,
      p_email,
      p_email_verified_at,
      p_credential,
      p_password_changed_at,
      p_status,
      p_last_login_at,
      p_created_by,
      p_updated_by
    );
  END insert_account;

  ------------------------------------------------------------------------------
  -- Atualizacoes
  ------------------------------------------------------------------------------

  PROCEDURE update_account(
    p_account_id        IN NUMBER,
    p_email             IN VARCHAR2,
    p_email_verified_at IN TIMESTAMP,
    p_status            IN VARCHAR2,
    p_updated_by        IN NUMBER
  ) IS
  BEGIN
    UPDATE BEX_ACCOUNT
       SET ACC_EMAIL = p_email,
           ACC_EMAIL_VERIFIED_AT = p_email_verified_at,
           ACC_STATUS = p_status,
           ACC_UPDATED_AT = SYSTIMESTAMP,
           ACC_UPDATED_BY = p_updated_by
     WHERE ACC_ID = p_account_id;
  END update_account;

  PROCEDURE update_password(
    p_account_id IN NUMBER,
    p_credential IN VARCHAR2
  ) IS
  BEGIN
    UPDATE BEX_ACCOUNT
       SET ACC_PASSWORD_HASH = p_credential,
           ACC_PASSWORD_CHANGED_AT = SYSTIMESTAMP,
           ACC_UPDATED_AT = SYSTIMESTAMP
     WHERE ACC_ID = p_account_id;
  END update_password;

  ------------------------------------------------------------------------------
  -- Consultas
  ------------------------------------------------------------------------------

  FUNCTION get_by_id(
    p_account_id IN NUMBER
  ) RETURN BEX_ACCOUNT%ROWTYPE IS
    l_account BEX_ACCOUNT%ROWTYPE;
  BEGIN
    SELECT *
      INTO l_account
      FROM BEX_ACCOUNT
     WHERE ACC_ID = p_account_id;

    RETURN l_account;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN l_account;
  END get_by_id;

  FUNCTION get_by_public_id(
    p_public_id IN BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE
  ) RETURN BEX_ACCOUNT%ROWTYPE IS
    l_account BEX_ACCOUNT%ROWTYPE;
  BEGIN
    SELECT *
      INTO l_account
      FROM BEX_ACCOUNT
     WHERE ACC_PUBLIC_ID = p_public_id;

    RETURN l_account;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN l_account;
  END get_by_public_id;

  FUNCTION get_by_email(
    p_email IN VARCHAR2
  ) RETURN BEX_ACCOUNT%ROWTYPE IS
    l_account BEX_ACCOUNT%ROWTYPE;
  BEGIN
    SELECT *
      INTO l_account
      FROM BEX_ACCOUNT
     WHERE ACC_EMAIL = p_email;

    RETURN l_account;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN l_account;
  END get_by_email;

  FUNCTION email_exists(
    p_email IN VARCHAR2
  ) RETURN BOOLEAN IS
    l_exists PLS_INTEGER;
  BEGIN
    SELECT 1
      INTO l_exists
      FROM BEX_ACCOUNT
     WHERE ACC_EMAIL = p_email;

    RETURN TRUE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN FALSE;
  END email_exists;
END acc_repository_pkg;
/
