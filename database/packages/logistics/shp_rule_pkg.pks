CREATE OR REPLACE PACKAGE shp_rule_pkg AS
  e_invalid EXCEPTION;e_invalid_transition EXCEPTION;
  PROCEDURE validate_transition(p_old VARCHAR2,p_new VARCHAR2);
END shp_rule_pkg;
/
