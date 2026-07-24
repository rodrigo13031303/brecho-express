CREATE OR REPLACE PACKAGE shp_service_pkg AS
  TYPE t_public_ids IS TABLE OF VARCHAR2(32) INDEX BY PLS_INTEGER;
  TYPE t_item_record IS RECORD(item_public_id CHAR(32),order_item_public_id CHAR(32),
    product_public_id CHAR(32),quantity NUMBER,status VARCHAR2(20));
  TYPE t_item_table IS TABLE OF t_item_record INDEX BY PLS_INTEGER;
  TYPE t_record IS RECORD(shipment_public_id CHAR(32),order_public_id CHAR(32),
    store_public_id CHAR(32),address_public_id CHAR(32),delivery_profile_public_id CHAR(32),
    tracking_code VARCHAR2(100),estimated_delivery_at TIMESTAMP,delivered_at TIMESTAMP,
    status VARCHAR2(20),items t_item_table);
  e_not_found EXCEPTION;e_forbidden EXCEPTION;e_invalid EXCEPTION;e_conflict EXCEPTION;
  FUNCTION create_shipment(p_order_public VARCHAR2,p_store_public VARCHAR2,p_address_public VARCHAR2,
    p_delivery_public VARCHAR2,p_items t_public_ids,p_estimated TIMESTAMP,p_actor NUMBER) RETURN t_record;
  FUNCTION get_shipment(p_public VARCHAR2,p_actor NUMBER) RETURN t_record;
  FUNCTION change_status(p_public VARCHAR2,p_status VARCHAR2,p_tracking VARCHAR2,p_actor NUMBER) RETURN t_record;
END shp_service_pkg;
/
