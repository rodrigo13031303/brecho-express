CREATE OR REPLACE PACKAGE acc_auth_api_pkg AS
  PROCEDURE login(
    p_request_body IN CLOB,p_ip IN VARCHAR2,p_user_agent IN VARCHAR2,
    o_status_code OUT PLS_INTEGER,o_response_body OUT NOCOPY CLOB
  );
  PROCEDURE logout(
    p_session_public_id IN VARCHAR2,p_actor_id IN NUMBER,
    o_status_code OUT PLS_INTEGER,o_response_body OUT NOCOPY CLOB
  );
END acc_auth_api_pkg;
/
