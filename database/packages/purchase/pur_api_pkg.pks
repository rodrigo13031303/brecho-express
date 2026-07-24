CREATE OR REPLACE PACKAGE pur_api_pkg AS
  PROCEDURE checkout(
    p_cart_public_id VARCHAR2,p_actor_id NUMBER,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE get_request(
    p_request_public_id VARCHAR2,p_actor_id NUMBER,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE respond_item(
    p_request_public_id VARCHAR2,p_item_public_id VARCHAR2,
    p_store_public_id VARCHAR2,p_body CLOB,p_actor_id NUMBER,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
END pur_api_pkg;
/
