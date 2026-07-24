CREATE OR REPLACE PACKAGE pim_api_pkg AS
  PROCEDURE add_image(p_product_public_id VARCHAR2,p_store_public_id VARCHAR2,
    p_body CLOB,p_actor_id NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE get_image(p_image_public_id VARCHAR2,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE list_images(p_product_public_id VARCHAR2,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE update_image(p_image_public_id VARCHAR2,p_store_public_id VARCHAR2,
    p_body CLOB,p_actor_id NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE deactivate_image(p_image_public_id VARCHAR2,p_store_public_id VARCHAR2,
    p_actor_id NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
END pim_api_pkg;
/
