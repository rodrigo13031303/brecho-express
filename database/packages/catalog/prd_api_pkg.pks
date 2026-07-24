CREATE OR REPLACE PACKAGE prd_api_pkg AS
  PROCEDURE create_product(
    p_store_public_id VARCHAR2,p_request_body CLOB,p_actor_id NUMBER,
    o_status_code OUT PLS_INTEGER,o_response_body OUT NOCOPY CLOB
  );
  PROCEDURE get_product(
    p_product_public_id VARCHAR2,
    o_status_code OUT PLS_INTEGER,o_response_body OUT NOCOPY CLOB
  );
  PROCEDURE get_product_by_slug(
    p_store_public_id VARCHAR2,p_slug VARCHAR2,
    o_status_code OUT PLS_INTEGER,o_response_body OUT NOCOPY CLOB
  );
  PROCEDURE list_store_products(
    p_store_public_id VARCHAR2,p_status VARCHAR2,p_actor_id NUMBER,
    o_status_code OUT PLS_INTEGER,o_response_body OUT NOCOPY CLOB
  );
  PROCEDURE list_public_products(
    p_category_public_id VARCHAR2,
    p_brand_public_id VARCHAR2,
    p_condition VARCHAR2,
    o_status_code OUT PLS_INTEGER,o_response_body OUT NOCOPY CLOB
  );
  PROCEDURE patch_product(
    p_product_public_id VARCHAR2,p_store_public_id VARCHAR2,
    p_request_body CLOB,p_actor_id NUMBER,
    o_status_code OUT PLS_INTEGER,o_response_body OUT NOCOPY CLOB
  );
  PROCEDURE change_status(
    p_product_public_id VARCHAR2,p_store_public_id VARCHAR2,
    p_new_status VARCHAR2,p_actor_id NUMBER,
    o_status_code OUT PLS_INTEGER,o_response_body OUT NOCOPY CLOB
  );
END prd_api_pkg;
/
