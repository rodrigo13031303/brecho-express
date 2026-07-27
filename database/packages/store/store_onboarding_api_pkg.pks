CREATE OR REPLACE PACKAGE store_onboarding_api_pkg AUTHID DEFINER AS
  PROCEDURE create_complete_store(
    p_account_public_id IN VARCHAR2,
    p_request_body IN CLOB,
    p_actor_id IN NUMBER,
    o_status_code OUT PLS_INTEGER,
    o_response_body OUT NOCOPY CLOB
  );
END store_onboarding_api_pkg;
/