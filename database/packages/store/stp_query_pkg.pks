CREATE OR REPLACE PACKAGE stp_query_pkg AS
  TYPE t_record IS RECORD(public_id CHAR(32),code VARCHAR2(50),name VARCHAR2(100),description VARCHAR2(500),price NUMBER,status VARCHAR2(20));
  TYPE t_records IS TABLE OF t_record INDEX BY PLS_INTEGER;e_not_found EXCEPTION;
  FUNCTION get_plan(p_code VARCHAR2)RETURN t_record;FUNCTION list_active RETURN t_records;
END stp_query_pkg;
/
