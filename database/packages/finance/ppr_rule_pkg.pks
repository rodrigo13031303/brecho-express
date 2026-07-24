CREATE OR REPLACE PACKAGE ppr_rule_pkg AS
  e_invalid EXCEPTION;
  PROCEDURE validate_data(p_code VARCHAR2,p_name VARCHAR2,p_status VARCHAR2);
END ppr_rule_pkg;
/
