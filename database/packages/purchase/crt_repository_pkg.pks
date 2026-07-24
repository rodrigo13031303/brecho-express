CREATE OR REPLACE PACKAGE crt_repository_pkg AS
  TYPE t_cart IS RECORD(crt_id NUMBER,crt_public_id CHAR(32),pfl_id NUMBER,
    crt_status VARCHAR2(20),crt_expires_at TIMESTAMP,crt_created_at TIMESTAMP,crt_updated_at TIMESTAMP);
  TYPE t_item IS RECORD(cti_id NUMBER,cti_public_id CHAR(32),crt_id NUMBER,
    prd_id NUMBER,str_id NUMBER,cti_quantity NUMBER,cti_unit_price NUMBER,
    cti_status VARCHAR2(20),cti_created_at TIMESTAMP,cti_updated_at TIMESTAMP);
  TYPE t_items IS TABLE OF t_item INDEX BY PLS_INTEGER;
  PROCEDURE insert_cart(p_public CHAR,p_profile NUMBER,p_expires TIMESTAMP,p_actor NUMBER,o_id OUT NUMBER);
  FUNCTION get_cart_by_id(p_id NUMBER) RETURN t_cart;
  FUNCTION get_cart_by_public(p VARCHAR2) RETURN t_cart;
  FUNCTION get_active_by_profile(p_profile NUMBER) RETURN t_cart;
  PROCEDURE lock_cart(p_id NUMBER);
  PROCEDURE update_cart_status(p_id NUMBER,p_status VARCHAR2,p_actor NUMBER);
  PROCEDURE insert_item(p_public CHAR,p_cart NUMBER,p_product NUMBER,p_store NUMBER,
    p_qty NUMBER,p_price NUMBER,p_actor NUMBER,o_id OUT NUMBER);
  FUNCTION get_item_by_public(p VARCHAR2) RETURN t_item;
  FUNCTION list_items(p_cart NUMBER,p_status VARCHAR2 DEFAULT NULL) RETURN t_items;
  PROCEDURE update_item_qty(p_id NUMBER,p_qty NUMBER,p_price NUMBER,p_actor NUMBER);
  PROCEDURE update_item_status(p_id NUMBER,p_status VARCHAR2,p_actor NUMBER);
END crt_repository_pkg;
/
