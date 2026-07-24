CREATE OR REPLACE PACKAGE adr_repository_pkg AS
  TYPE t_row IS RECORD(adr_id NUMBER,adr_public_id CHAR(32),pfl_id NUMBER,adr_label VARCHAR2(100),
    adr_zip_code VARCHAR2(10),adr_street VARCHAR2(200),adr_number VARCHAR2(50),
    adr_complement VARCHAR2(200),adr_district VARCHAR2(100),adr_city VARCHAR2(100),
    adr_state CHAR(2),adr_country CHAR(2),adr_latitude NUMBER,adr_longitude NUMBER,
    adr_is_default NUMBER,adr_status VARCHAR2(20),adr_created_at TIMESTAMP,adr_updated_at TIMESTAMP);
  TYPE t_rows IS TABLE OF t_row INDEX BY PLS_INTEGER;
  PROCEDURE insert_row(p t_row,p_actor NUMBER,o_id OUT NUMBER);
  FUNCTION by_public(p VARCHAR2) RETURN t_row;FUNCTION by_id(p NUMBER) RETURN t_row;
  FUNCTION list_profile(p NUMBER) RETURN t_rows;
  PROCEDURE clear_default(p_profile NUMBER,p_actor NUMBER);
  PROCEDURE set_status(p_id NUMBER,p_status VARCHAR2,p_default NUMBER,p_actor NUMBER);
END adr_repository_pkg;
/
