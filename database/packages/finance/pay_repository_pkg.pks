CREATE OR REPLACE PACKAGE pay_repository_pkg AS
  TYPE t_row IS RECORD(pay_id NUMBER,pay_public_id CHAR(32),pur_id NUMBER,ord_id NUMBER,ppr_id NUMBER,
    pay_external_id VARCHAR2(100),pay_amount NUMBER,pay_method VARCHAR2(20),pay_status VARCHAR2(20),
    pay_approved_at TIMESTAMP,pay_created_at TIMESTAMP,pay_updated_at TIMESTAMP);
  PROCEDURE insert_row(p t_row,p_actor NUMBER,o_id OUT NUMBER);
  FUNCTION by_public(p VARCHAR2) RETURN t_row;FUNCTION by_id(p NUMBER) RETURN t_row;
  PROCEDURE lock_row(p_id NUMBER);
  PROCEDURE update_state(p_id NUMBER,p_status VARCHAR2,p_order NUMBER,p_actor NUMBER);
END pay_repository_pkg;
/
