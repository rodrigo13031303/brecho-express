CREATE OR REPLACE PACKAGE ord_runtime_pkg AS
  PROCEDURE begin_anonymous_request;

  PROCEDURE begin_authenticated_request(
    p_authorization      IN VARCHAR2,
    o_authenticated      OUT BOOLEAN,
    o_account_id         OUT NUMBER,
    o_session_public_id  OUT VARCHAR2,
    o_status_code        OUT PLS_INTEGER,
    o_response_body      OUT NOCOPY CLOB
  );

  PROCEDURE write_json_response(
    p_body IN CLOB
  );

  PROCEDURE clear_request_context;
END ord_runtime_pkg;
/
