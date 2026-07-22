CREATE OR REPLACE PACKAGE pfl_api_pkg AS
  -- Fronteira JSON oficial dos casos de uso externos de PROFILE.
  -- Pressupoe Core Context inicializado pelo handler ORDS.

  PROCEDURE create_profile(
    p_account_public_id IN  VARCHAR2,
    p_request_body      IN  CLOB,
    p_actor_id          IN  NUMBER,
    o_status_code       OUT PLS_INTEGER,
    o_response_body     OUT NOCOPY CLOB
  );

  PROCEDURE get_profile(
    p_profile_public_id IN  VARCHAR2,
    p_actor_id          IN  NUMBER,
    o_status_code       OUT PLS_INTEGER,
    o_response_body     OUT NOCOPY CLOB
  );

  PROCEDURE get_profile_by_account(
    p_account_public_id IN  VARCHAR2,
    p_actor_id          IN  NUMBER,
    o_status_code       OUT PLS_INTEGER,
    o_response_body     OUT NOCOPY CLOB
  );

  PROCEDURE update_profile(
    p_profile_public_id IN  VARCHAR2,
    p_request_body      IN  CLOB,
    p_actor_id          IN  NUMBER,
    o_status_code       OUT PLS_INTEGER,
    o_response_body     OUT NOCOPY CLOB
  );
END pfl_api_pkg;
/
