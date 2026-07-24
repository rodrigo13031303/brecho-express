CREATE OR REPLACE PACKAGE bcf_repository_pkg AS
  TYPE t_row IS RECORD(id NUMBER,public_id CHAR(32),code VARCHAR2(100),module_code VARCHAR2(50),name VARCHAR2(150),
    description VARCHAR2(1000),value_text VARCHAR2(4000),value_number NUMBER,value_boolean CHAR(1),unit_code VARCHAR2(50),status VARCHAR2(20));
  TYPE t_rows IS TABLE OF t_row INDEX BY PLS_INTEGER;
  PROCEDURE insert_row(p t_row,p_actor NUMBER,o_id OUT NUMBER);
  FUNCTION by_code(p_code VARCHAR2) RETURN t_row;
  FUNCTION list_module(p_module VARCHAR2) RETURN t_rows;
  PROCEDURE update_row(p_code VARCHAR2,p_text VARCHAR2,p_number NUMBER,p_boolean CHAR,p_unit VARCHAR2,p_status VARCHAR2,p_actor NUMBER);
END bcf_repository_pkg;
/
