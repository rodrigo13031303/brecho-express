CREATE OR REPLACE PACKAGE shp_repository_pkg AS
  TYPE t_row IS RECORD(shp_id NUMBER,shp_public_id CHAR(32),ord_id NUMBER,str_id NUMBER,
    adr_id NUMBER,dlp_id NUMBER,shp_tracking_code VARCHAR2(100),
    shp_estimated_delivery_at TIMESTAMP,shp_delivered_at TIMESTAMP,shp_status VARCHAR2(20),
    shp_created_at TIMESTAMP,shp_updated_at TIMESTAMP);
  TYPE t_item IS RECORD(shi_id NUMBER,shi_public_id CHAR(32),shp_id NUMBER,ori_id NUMBER,
    prd_id NUMBER,shi_quantity NUMBER,shi_status VARCHAR2(20));
  TYPE t_items IS TABLE OF t_item INDEX BY PLS_INTEGER;
  PROCEDURE insert_row(p t_row,p_actor NUMBER,o_id OUT NUMBER);
  PROCEDURE insert_item(p t_item,p_actor NUMBER,o_id OUT NUMBER);
  FUNCTION by_public(p VARCHAR2) RETURN t_row;FUNCTION by_id(p NUMBER) RETURN t_row;
  FUNCTION list_items(p_shipment NUMBER) RETURN t_items;
  PROCEDURE update_status(p_id NUMBER,p_status VARCHAR2,p_tracking VARCHAR2,p_actor NUMBER);
END shp_repository_pkg;
/
