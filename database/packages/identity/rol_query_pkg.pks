CREATE OR REPLACE PACKAGE rol_query_pkg AS
  TYPE t_record IS RECORD(role_id NUMBER,public_id CHAR(32),code VARCHAR2(50),name VARCHAR2(100),description VARCHAR2(500),status VARCHAR2(20));
  TYPE t_records IS TABLE OF t_record INDEX BY PLS_INTEGER;e_not_found EXCEPTION;e_inactive EXCEPTION;
  FUNCTION get_by_code(p_code VARCHAR2,p_require_active BOOLEAN DEFAULT TRUE)RETURN t_record;
  FUNCTION list_active RETURN t_records;
END rol_query_pkg;
/
