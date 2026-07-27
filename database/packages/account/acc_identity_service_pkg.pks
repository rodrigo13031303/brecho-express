CREATE OR REPLACE PACKAGE acc_identity_service_pkg AS
  e_invalid_claims      EXCEPTION;
  e_existing_email      EXCEPTION;
  e_account_unavailable EXCEPTION;

  FUNCTION authenticate_google(
    p_issuer         IN VARCHAR2,
    p_subject        IN VARCHAR2,
    p_email          IN VARCHAR2,
    p_email_verified IN CHAR
  ) RETURN BEX_ACCOUNT%ROWTYPE;
END acc_identity_service_pkg;
/
