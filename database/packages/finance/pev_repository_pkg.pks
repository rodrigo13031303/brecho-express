CREATE OR REPLACE PACKAGE pev_repository_pkg AS
  TYPE t_row IS RECORD(pev_id NUMBER,pev_public_id CHAR(32),pay_id NUMBER,
    pev_event_type VARCHAR2(50),pev_external_event_id VARCHAR2(100),pev_event_at TIMESTAMP,
    pev_raw_payload CLOB,pev_status VARCHAR2(20),pev_created_at TIMESTAMP,pev_updated_at TIMESTAMP);
  PROCEDURE insert_row(p t_row,p_actor NUMBER,o_id OUT NUMBER);
  FUNCTION by_id(p NUMBER) RETURN t_row;FUNCTION by_external(p_pay NUMBER,p_external VARCHAR2) RETURN t_row;
  PROCEDURE update_status(p_id NUMBER,p_status VARCHAR2,p_actor NUMBER);
END pev_repository_pkg;
/
