CREATE OR REPLACE PACKAGE prl_repository_pkg AS
  TYPE t_row IS RECORD(id NUMBER,public_id CHAR(32),profile_id NUMBER,role_id NUMBER,status VARCHAR2(20),granted_at TIMESTAMP,expires_at TIMESTAMP);
  TYPE t_rows IS TABLE OF t_row INDEX BY PLS_INTEGER;
  PROCEDURE insert_row(p t_row,p_actor NUMBER,o_id OUT NUMBER);FUNCTION by_id(p NUMBER)RETURN t_row;
  FUNCTION by_profile_role(p_profile NUMBER,p_role NUMBER)RETURN t_row;
  FUNCTION list_profile(p_profile NUMBER)RETURN t_rows;
  PROCEDURE activate(p_id NUMBER,p_expires TIMESTAMP,p_actor NUMBER);PROCEDURE deactivate(p_id NUMBER,p_actor NUMBER);
END prl_repository_pkg;
/
