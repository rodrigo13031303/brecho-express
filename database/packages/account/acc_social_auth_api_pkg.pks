CREATE OR REPLACE PACKAGE acc_social_auth_api_pkg AS
  PROCEDURE login_google_verified(
    p_issuer         IN VARCHAR2,
    p_subject        IN VARCHAR2,
    p_email          IN VARCHAR2,
    p_email_verified IN CHAR,
    p_ip             IN VARCHAR2,
    p_user_agent     IN VARCHAR2,
    o_status_code    OUT PLS_INTEGER,
    o_response_body  OUT NOCOPY CLOB
  );

  PROCEDURE login_google_verified(
    p_issuer         IN VARCHAR2,
    p_subject        IN VARCHAR2,
    p_email          IN VARCHAR2,
    p_email_verified IN CHAR,
    p_name           IN VARCHAR2,
    p_ip             IN VARCHAR2,
    p_user_agent     IN VARCHAR2,
    o_status_code    OUT PLS_INTEGER,
    o_response_body  OUT NOCOPY CLOB
  );
END acc_social_auth_api_pkg;
/
