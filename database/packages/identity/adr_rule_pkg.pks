CREATE OR REPLACE PACKAGE adr_rule_pkg AS
  e_invalid_address EXCEPTION;e_invalid_status EXCEPTION;
  PROCEDURE validate_address(p_zip VARCHAR2,p_street VARCHAR2,p_number VARCHAR2,
    p_district VARCHAR2,p_city VARCHAR2,p_state VARCHAR2,p_country VARCHAR2,
    p_lat NUMBER,p_lon NUMBER);
END adr_rule_pkg;
/
