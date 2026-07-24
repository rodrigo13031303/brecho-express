CREATE OR REPLACE PACKAGE ntf_repository_pkg AS
  TYPE t_row IS RECORD(id NUMBER,public_id CHAR(32),profile_id NUMBER,notification_type VARCHAR2(80),title VARCHAR2(200),body VARCHAR2(2000),status VARCHAR2(20),created_at TIMESTAMP,read_at TIMESTAMP);
  TYPE t_rows IS TABLE OF t_row INDEX BY PLS_INTEGER;
  PROCEDURE insert_row(p t_row,o_id OUT NUMBER);
  FUNCTION by_public(p_public_id VARCHAR2) RETURN t_row;
  FUNCTION list_profile(p_profile_id NUMBER) RETURN t_rows;
  PROCEDURE mark_read(p_id NUMBER);
END ntf_repository_pkg;
/
