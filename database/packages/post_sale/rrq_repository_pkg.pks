CREATE OR REPLACE PACKAGE rrq_repository_pkg AS
  TYPE t_row IS RECORD(rrq_id NUMBER,rrq_public_id CHAR(32),ord_id NUMBER,str_id NUMBER,pfl_id NUMBER,
    reason_code VARCHAR2(50),description VARCHAR2(2000),status VARCHAR2(20),result VARCHAR2(50),
    priority VARCHAR2(20),severity VARCHAR2(20),source VARCHAR2(50),requested_at TIMESTAMP,
    decided_at TIMESTAMP,closed_at TIMESTAMP,store_response VARCHAR2(2000));
  TYPE t_rows IS TABLE OF t_row INDEX BY PLS_INTEGER;
  PROCEDURE insert_row(p t_row,p_actor NUMBER,o_id OUT NUMBER);
  FUNCTION by_public(p VARCHAR2) RETURN t_row;FUNCTION by_id(p NUMBER) RETURN t_row;
  FUNCTION list_by_store(p_store NUMBER) RETURN t_rows;
  PROCEDURE update_state(p_id NUMBER,p_status VARCHAR2,p_result VARCHAR2,p_profile NUMBER,p_actor NUMBER);
  PROCEDURE update_response(p_id NUMBER,p_response VARCHAR2,p_actor NUMBER);
END rrq_repository_pkg;
/
