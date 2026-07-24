CREATE OR REPLACE PACKAGE ste_repository_pkg AS
  TYPE t_row IS RECORD(id NUMBER,public_id CHAR(32),store_id NUMBER,event_name VARCHAR2(200),description VARCHAR2(1000),
    start_at TIMESTAMP,end_at TIMESTAMP,status VARCHAR2(20));
  TYPE t_rows IS TABLE OF t_row INDEX BY PLS_INTEGER;
  PROCEDURE insert_row(p t_row,p_actor NUMBER,o_id OUT NUMBER);FUNCTION by_id(p NUMBER)RETURN t_row;FUNCTION by_public(p VARCHAR2)RETURN t_row;
  FUNCTION list_store(p_store NUMBER)RETURN t_rows;PROCEDURE update_status(p_id NUMBER,p_status VARCHAR2,p_actor NUMBER);
END ste_repository_pkg;
/
