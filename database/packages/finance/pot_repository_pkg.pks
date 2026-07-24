CREATE OR REPLACE PACKAGE pot_repository_pkg AS
  TYPE t_row IS RECORD(pot_id NUMBER,pot_public_id CHAR(32),str_id NUMBER,pot_amount NUMBER,
    pot_pix_key VARCHAR2(200),pot_pix_key_type VARCHAR2(20),pot_requested_at TIMESTAMP,
    pot_approved_at TIMESTAMP,pot_paid_at TIMESTAMP,pot_rejected_at TIMESTAMP,
    pot_reject_reason VARCHAR2(1000),pot_status VARCHAR2(20));
  PROCEDURE insert_row(p t_row,p_actor NUMBER,o_id OUT NUMBER);
  FUNCTION by_public(p VARCHAR2) RETURN t_row;FUNCTION by_id(p NUMBER) RETURN t_row;
  PROCEDURE lock_row(p_id NUMBER);PROCEDURE update_state(p_id NUMBER,p_status VARCHAR2,p_reason VARCHAR2,p_actor NUMBER);
END pot_repository_pkg;
/
