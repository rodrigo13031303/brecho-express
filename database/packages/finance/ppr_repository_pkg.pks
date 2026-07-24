CREATE OR REPLACE PACKAGE ppr_repository_pkg AS
  TYPE t_row IS RECORD(ppr_id NUMBER,ppr_public_id CHAR(32),ppr_code VARCHAR2(50),
    ppr_name VARCHAR2(100),ppr_status VARCHAR2(20),ppr_created_at TIMESTAMP,ppr_updated_at TIMESTAMP);
  TYPE t_rows IS TABLE OF t_row INDEX BY PLS_INTEGER;
  PROCEDURE insert_row(p t_row,p_actor NUMBER,o_id OUT NUMBER);
  FUNCTION by_public(p VARCHAR2) RETURN t_row;FUNCTION by_id(p NUMBER) RETURN t_row;
  FUNCTION list_rows(p_status VARCHAR2) RETURN t_rows;
END ppr_repository_pkg;
/
