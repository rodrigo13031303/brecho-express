CREATE OR REPLACE PACKAGE str_api_pkg AS
  -- Fronteira JSON oficial dos casos de uso externos de STORE.
  -- Pressupoe Core Context inicializado pelo handler ORDS.

  PROCEDURE create_store(
    p_account_public_id IN  VARCHAR2,
    p_request_body      IN  CLOB,
    p_actor_id          IN  NUMBER,
    o_status_code       OUT PLS_INTEGER,
    o_response_body     OUT NOCOPY CLOB
  );

  PROCEDURE get_store(
    p_store_public_id IN  VARCHAR2,
    p_actor_id        IN  NUMBER,
    o_status_code     OUT PLS_INTEGER,
    o_response_body   OUT NOCOPY CLOB
  );

  PROCEDURE get_store_by_slug(
    p_slug            IN  VARCHAR2,
    p_actor_id        IN  NUMBER,
    o_status_code     OUT PLS_INTEGER,
    o_response_body   OUT NOCOPY CLOB
  );

  PROCEDURE list_stores_by_account(
    p_account_public_id IN  VARCHAR2,
    p_actor_id          IN  NUMBER,
    o_status_code       OUT PLS_INTEGER,
    o_response_body     OUT NOCOPY CLOB
  );

  PROCEDURE update_store(
    p_store_public_id IN  VARCHAR2,
    p_request_body    IN  CLOB,
    p_actor_id        IN  NUMBER,
    o_status_code     OUT PLS_INTEGER,
    o_response_body   OUT NOCOPY CLOB
  );

  PROCEDURE activate_store(
    p_store_public_id IN  VARCHAR2,
    p_actor_id        IN  NUMBER,
    o_status_code     OUT PLS_INTEGER,
    o_response_body   OUT NOCOPY CLOB
  );

  PROCEDURE close_store(
    p_store_public_id IN  VARCHAR2,
    p_actor_id        IN  NUMBER,
    o_status_code     OUT PLS_INTEGER,
    o_response_body   OUT NOCOPY CLOB
  );

  PROCEDURE check_slug_availability(
    p_slug          IN  VARCHAR2,
    p_actor_id      IN  NUMBER,
    o_status_code   OUT PLS_INTEGER,
    o_response_body OUT NOCOPY CLOB
  );
END str_api_pkg;
/
