CREATE OR REPLACE PACKAGE pur_repository_pkg AS
  TYPE t_request IS RECORD(pur_id NUMBER,pur_public_id CHAR(32),pfl_id NUMBER,
    pur_status VARCHAR2(30),pur_requested_at TIMESTAMP,pur_confirmed_at TIMESTAMP,
    pur_response_at TIMESTAMP,pur_expires_at TIMESTAMP,pur_created_at TIMESTAMP,pur_updated_at TIMESTAMP);
  TYPE t_item IS RECORD(pri_id NUMBER,pri_public_id CHAR(32),pur_id NUMBER,prd_id NUMBER,
    str_id NUMBER,pri_requested_quantity NUMBER,pri_confirmed_quantity NUMBER,
    pri_unit_price NUMBER,pri_reject_reason VARCHAR2(500),pri_status VARCHAR2(30));
  TYPE t_items IS TABLE OF t_item INDEX BY PLS_INTEGER;
  PROCEDURE insert_request(p_public CHAR,p_profile NUMBER,p_expires TIMESTAMP,p_actor NUMBER,o_id OUT NUMBER);
  PROCEDURE insert_item(p_public CHAR,p_request NUMBER,p_product NUMBER,p_store NUMBER,
    p_qty NUMBER,p_price NUMBER,p_actor NUMBER,o_id OUT NUMBER);
  FUNCTION get_request_by_id(p_id NUMBER) RETURN t_request;
  FUNCTION get_request_by_public(p VARCHAR2) RETURN t_request;
  FUNCTION get_item_by_public(p VARCHAR2) RETURN t_item;
  FUNCTION list_items(p_request NUMBER) RETURN t_items;
  PROCEDURE lock_request(p_id NUMBER);PROCEDURE lock_item(p_id NUMBER);
  PROCEDURE respond_item(p_id NUMBER,p_qty NUMBER,p_reason VARCHAR2,p_status VARCHAR2,p_actor NUMBER);
  PROCEDURE update_request_status(p_id NUMBER,p_status VARCHAR2,p_actor NUMBER);
END pur_repository_pkg;
/
