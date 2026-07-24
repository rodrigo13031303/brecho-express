CREATE OR REPLACE PACKAGE crt_service_pkg AS
  TYPE t_item_record IS RECORD(item_public_id CHAR(32),product_public_id CHAR(32),
    store_public_id CHAR(32),quantity NUMBER,unit_price NUMBER,status VARCHAR2(20));
  TYPE t_item_table IS TABLE OF t_item_record INDEX BY PLS_INTEGER;
  TYPE t_cart_record IS RECORD(cart_public_id CHAR(32),profile_public_id CHAR(32),
    status VARCHAR2(20),expires_at TIMESTAMP,created_at TIMESTAMP,updated_at TIMESTAMP,
    items t_item_table);
  TYPE t_checkout_item IS RECORD(product_id NUMBER,store_id NUMBER,
    requested_quantity NUMBER,unit_price NUMBER);
  TYPE t_checkout_items IS TABLE OF t_checkout_item INDEX BY PLS_INTEGER;
  TYPE t_checkout IS RECORD(cart_id NUMBER,profile_id NUMBER,items t_checkout_items);
  e_cart_not_found EXCEPTION;e_item_not_found EXCEPTION;e_forbidden EXCEPTION;
  e_invalid_quantity EXCEPTION;e_cart_closed EXCEPTION;e_item_conflict EXCEPTION;e_empty_cart EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_cart_not_found,-20680);PRAGMA EXCEPTION_INIT(e_item_not_found,-20681);
  PRAGMA EXCEPTION_INIT(e_forbidden,-20682);PRAGMA EXCEPTION_INIT(e_invalid_quantity,-20683);
  PRAGMA EXCEPTION_INIT(e_cart_closed,-20684);PRAGMA EXCEPTION_INIT(e_item_conflict,-20685);
  PRAGMA EXCEPTION_INIT(e_empty_cart,-20686);
  FUNCTION get_or_create_active(p_actor_id NUMBER) RETURN t_cart_record;
  FUNCTION get_cart(p_cart_public_id VARCHAR2,p_actor_id NUMBER) RETURN t_cart_record;
  FUNCTION add_item(p_cart_public_id VARCHAR2,p_product_public_id VARCHAR2,
    p_quantity NUMBER,p_actor_id NUMBER) RETURN t_cart_record;
  FUNCTION update_item(p_cart_public_id VARCHAR2,p_item_public_id VARCHAR2,
    p_quantity NUMBER,p_actor_id NUMBER) RETURN t_cart_record;
  FUNCTION remove_item(p_cart_public_id VARCHAR2,p_item_public_id VARCHAR2,
    p_actor_id NUMBER) RETURN t_cart_record;
  FUNCTION prepare_checkout(p_cart_public_id VARCHAR2,p_actor_id NUMBER) RETURN t_checkout;
  PROCEDURE complete_checkout(p_cart_id NUMBER,p_actor_id NUMBER);
END crt_service_pkg;
/
