CREATE OR REPLACE PACKAGE rat_repository_pkg AS
  TYPE t_row IS RECORD(rat_id NUMBER,rat_public_id CHAR(32),rrq_id NUMBER,pfl_id NUMBER,attachment_type VARCHAR2(50),
    attachment_url VARCHAR2(1000),filename VARCHAR2(255),mime_type VARCHAR2(100),size_bytes NUMBER,
    description VARCHAR2(2000),uploaded_at TIMESTAMP,status VARCHAR2(20));
  TYPE t_rows IS TABLE OF t_row INDEX BY PLS_INTEGER;
  PROCEDURE insert_row(p t_row,p_actor NUMBER,o_id OUT NUMBER);FUNCTION by_public(p VARCHAR2)RETURN t_row;
  FUNCTION by_id(p NUMBER)RETURN t_row;FUNCTION list_request(p_request NUMBER)RETURN t_rows;
END rat_repository_pkg;
/
