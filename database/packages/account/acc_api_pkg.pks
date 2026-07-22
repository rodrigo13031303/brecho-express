CREATE OR REPLACE PACKAGE acc_api_pkg AS
  -- Fronteira JSON oficial dos casos de uso externos de ACCOUNT.
  -- Pressupoe Core Context inicializado pelo handler ORDS.

  PROCEDURE create_account(
    p_request_body  IN  CLOB,
    o_status_code   OUT PLS_INTEGER,
    o_response_body OUT NOCOPY CLOB
  );
END acc_api_pkg;
/
