CREATE OR REPLACE PACKAGE BODY acc_identity_repository_pkg AS
  FUNCTION find_active(
    p_provider IN VARCHAR2,
    p_issuer   IN VARCHAR2,
    p_subject  IN VARCHAR2
  ) RETURN BEX_ACCOUNT_IDENTITY%ROWTYPE IS
    l_identity BEX_ACCOUNT_IDENTITY%ROWTYPE;
  BEGIN
    SELECT *
      INTO l_identity
      FROM BEX_ACCOUNT_IDENTITY
     WHERE AID_PROVIDER = p_provider
       AND AID_ISSUER = p_issuer
       AND AID_SUBJECT = p_subject
       AND AID_STATUS = 'ACTIVE';
    RETURN l_identity;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN l_identity;
  END find_active;

  PROCEDURE insert_identity(
    p_account_id     IN NUMBER,
    p_provider       IN VARCHAR2,
    p_issuer         IN VARCHAR2,
    p_subject        IN VARCHAR2,
    p_email          IN VARCHAR2,
    p_email_verified IN CHAR,
    p_created_by     IN NUMBER
  ) IS
  BEGIN
    INSERT INTO BEX_ACCOUNT_IDENTITY(
      AID_PUBLIC_ID,
      ACC_ID,
      AID_PROVIDER,
      AID_ISSUER,
      AID_SUBJECT,
      AID_EMAIL,
      AID_EMAIL_VERIFIED,
      AID_LAST_LOGIN_AT,
      AID_CREATED_BY,
      AID_UPDATED_BY
    )
    VALUES(
      LOWER(RAWTOHEX(SYS_GUID())),
      p_account_id,
      p_provider,
      p_issuer,
      p_subject,
      p_email,
      p_email_verified,
      SYSTIMESTAMP,
      p_created_by,
      p_created_by
    );
  END insert_identity;

  PROCEDURE register_login(
    p_identity_id    IN NUMBER,
    p_email          IN VARCHAR2,
    p_email_verified IN CHAR,
    p_updated_by     IN NUMBER
  ) IS
  BEGIN
    UPDATE BEX_ACCOUNT_IDENTITY
       SET AID_EMAIL = p_email,
           AID_EMAIL_VERIFIED = p_email_verified,
           AID_LAST_LOGIN_AT = SYSTIMESTAMP,
           AID_UPDATED_AT = SYSTIMESTAMP,
           AID_UPDATED_BY = p_updated_by
     WHERE AID_ID = p_identity_id
       AND AID_STATUS = 'ACTIVE';
  END register_login;
END acc_identity_repository_pkg;
/
