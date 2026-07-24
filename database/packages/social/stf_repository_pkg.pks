CREATE OR REPLACE PACKAGE stf_repository_pkg AS
  TYPE t_row IS RECORD(id NUMBER,public_id CHAR(32),store_id NUMBER,profile_id NUMBER,status VARCHAR2(20),followed_at TIMESTAMP,unfollowed_at TIMESTAMP);
  TYPE t_rows IS TABLE OF t_row INDEX BY PLS_INTEGER;
  PROCEDURE insert_row(p t_row,p_actor NUMBER,o_id OUT NUMBER);FUNCTION by_id(p NUMBER)RETURN t_row;
  FUNCTION active_link(p_store NUMBER,p_profile NUMBER)RETURN t_row;FUNCTION latest_link(p_store NUMBER,p_profile NUMBER)RETURN t_row;
  FUNCTION list_profile(p_profile NUMBER)RETURN t_rows;PROCEDURE update_status(p_id NUMBER,p_status VARCHAR2,p_actor NUMBER);
END stf_repository_pkg;
/
