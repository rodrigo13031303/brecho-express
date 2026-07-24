CREATE OR REPLACE PACKAGE pur_service_pkg AS
  TYPE t_item_record IS RECORD(item_public_id CHAR(32),product_public_id CHAR(32),
    store_public_id CHAR(32),requested_quantity NUMBER,confirmed_quantity NUMBER,
    unit_price NUMBER,reject_reason VARCHAR2(500),status VARCHAR2(30));
  TYPE t_item_table IS TABLE OF t_item_record INDEX BY PLS_INTEGER;
  TYPE t_record IS RECORD(request_public_id CHAR(32),profile_public_id CHAR(32),
    status VARCHAR2(30),requested_at TIMESTAMP,confirmed_at TIMESTAMP,
    response_at TIMESTAMP,expires_at TIMESTAMP,items t_item_table);
  e_request_not_found EXCEPTION;e_item_not_found EXCEPTION;e_forbidden EXCEPTION;
  e_invalid_response EXCEPTION;e_request_closed EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_request_not_found,-20690);PRAGMA EXCEPTION_INIT(e_item_not_found,-20691);
  PRAGMA EXCEPTION_INIT(e_forbidden,-20692);PRAGMA EXCEPTION_INIT(e_invalid_response,-20693);
  PRAGMA EXCEPTION_INIT(e_request_closed,-20694);
  FUNCTION checkout(p_cart_public_id VARCHAR2,p_actor_id NUMBER) RETURN t_record;
  FUNCTION get_request(p_public_id VARCHAR2,p_actor_id NUMBER) RETURN t_record;
  FUNCTION respond_item(p_request_public_id VARCHAR2,p_item_public_id VARCHAR2,
    p_store_public_id VARCHAR2,p_confirmed_quantity NUMBER,p_reject_reason VARCHAR2,
    p_actor_id NUMBER) RETURN t_record;
END pur_service_pkg;
/
