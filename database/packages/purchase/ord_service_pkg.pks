CREATE OR REPLACE PACKAGE ord_service_pkg AS
  TYPE t_item_record IS RECORD(item_public_id CHAR(32),product_public_id CHAR(32),
    store_public_id CHAR(32),quantity NUMBER,unit_price NUMBER,discount_amount NUMBER,total_price NUMBER);
  TYPE t_item_table IS TABLE OF t_item_record INDEX BY PLS_INTEGER;
  TYPE t_record IS RECORD(order_public_id CHAR(32),order_number VARCHAR2(50),
    profile_public_id CHAR(32),subtotal_amount NUMBER,discount_amount NUMBER,
    shipping_amount NUMBER,total_amount NUMBER,status VARCHAR2(20),paid_at TIMESTAMP,
    created_at TIMESTAMP,items t_item_table);
  TYPE t_settlement_item IS RECORD(store_id NUMBER,base_amount NUMBER);
  TYPE t_settlement_items IS TABLE OF t_settlement_item INDEX BY PLS_INTEGER;
  TYPE t_settlement_source IS RECORD(order_id NUMBER,items t_settlement_items);
  e_not_found EXCEPTION;e_forbidden EXCEPTION;e_invalid EXCEPTION;e_conflict EXCEPTION;
  FUNCTION create_paid_order(p_request_public VARCHAR2,p_discount NUMBER,p_shipping NUMBER,
    p_paid_at TIMESTAMP,p_actor NUMBER) RETURN t_record;
  FUNCTION get_order(p_public VARCHAR2,p_actor NUMBER) RETURN t_record;
  FUNCTION get_internal(p_public VARCHAR2) RETURN ord_repository_pkg.t_order;
  FUNCTION item_internal(p_public VARCHAR2) RETURN ord_repository_pkg.t_item;
  FUNCTION change_status_internal(p_public VARCHAR2,p_status VARCHAR2,p_actor NUMBER) RETURN t_record;
  FUNCTION settlement_source(p_order_id NUMBER) RETURN t_settlement_source;
END ord_service_pkg;
/
