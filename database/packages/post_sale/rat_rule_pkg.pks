CREATE OR REPLACE PACKAGE rat_rule_pkg AS
  e_invalid EXCEPTION;
  PROCEDURE validate_create(p_type VARCHAR2,p_url VARCHAR2,p_size NUMBER);
END rat_rule_pkg;
/
