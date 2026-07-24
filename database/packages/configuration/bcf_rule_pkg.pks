CREATE OR REPLACE PACKAGE bcf_rule_pkg AS
  e_invalid EXCEPTION;
  PROCEDURE validate_value(p_text VARCHAR2,p_number NUMBER,p_boolean CHAR);
END bcf_rule_pkg;
/
