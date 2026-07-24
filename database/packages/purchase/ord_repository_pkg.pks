CREATE OR REPLACE PACKAGE ord_repository_pkg AS
  TYPE t_order IS RECORD(ord_id NUMBER,ord_public_id CHAR(32),pur_id NUMBER,pfl_id NUMBER,
    ord_number VARCHAR2(50),ord_subtotal_amount NUMBER,ord_discount_amount NUMBER,
    ord_shipping_amount NUMBER,ord_total_amount NUMBER,ord_status VARCHAR2(20),
    ord_paid_at TIMESTAMP,ord_created_at TIMESTAMP,ord_updated_at TIMESTAMP);
  TYPE t_item IS RECORD(ori_id NUMBER,ori_public_id CHAR(32),ord_id NUMBER,prd_id NUMBER,
    str_id NUMBER,ori_quantity NUMBER,ori_unit_price NUMBER,ori_discount_amount NUMBER,
    ori_total_price NUMBER,ori_status VARCHAR2(20));
  TYPE t_items IS TABLE OF t_item INDEX BY PLS_INTEGER;
  PROCEDURE insert_order(p t_order,p_actor NUMBER,o_id OUT NUMBER);
  PROCEDURE insert_item(p t_item,p_actor NUMBER,o_id OUT NUMBER);
  FUNCTION by_public(p VARCHAR2) RETURN t_order;FUNCTION by_id(p NUMBER) RETURN t_order;
  FUNCTION item_by_public(p VARCHAR2) RETURN t_item;FUNCTION item_by_id(p NUMBER) RETURN t_item;
  FUNCTION list_items(p_order NUMBER) RETURN t_items;
  PROCEDURE update_status(p_id NUMBER,p_status VARCHAR2,p_actor NUMBER);
END ord_repository_pkg;
/
