CREATE OR REPLACE PACKAGE acc_identity_repository_pkg AS
  FUNCTION find_active(
    p_provider IN VARCHAR2,
    p_issuer   IN VARCHAR2,
    p_subject  IN VARCHAR2
  ) RETURN BEX_ACCOUNT_IDENTITY%ROWTYPE;

  PROCEDURE insert_identity(
    p_account_id     IN NUMBER,
    p_provider       IN VARCHAR2,
    p_issuer         IN VARCHAR2,
    p_subject        IN VARCHAR2,
    p_email          IN VARCHAR2,
    p_email_verified IN CHAR,
    p_created_by     IN NUMBER
  );

  PROCEDURE register_login(
    p_identity_id    IN NUMBER,
    p_email          IN VARCHAR2,
    p_email_verified IN CHAR,
    p_updated_by     IN NUMBER
  );
END acc_identity_repository_pkg;
/
