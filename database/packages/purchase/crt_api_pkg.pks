CREATE OR REPLACE PACKAGE crt_api_pkg AS
  PROCEDURE get_or_create_cart(
    p_actor_id NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE get_cart(
    p_cart_public_id VARCHAR2,p_actor_id NUMBER,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE add_item(
    p_cart_public_id VARCHAR2,p_body CLOB,p_actor_id NUMBER,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE update_item(
    p_cart_public_id VARCHAR2,p_item_public_id VARCHAR2,p_body CLOB,p_actor_id NUMBER,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE remove_item(
    p_cart_public_id VARCHAR2,p_item_public_id VARCHAR2,p_actor_id NUMBER,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
END crt_api_pkg;
/
