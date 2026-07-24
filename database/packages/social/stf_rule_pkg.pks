CREATE OR REPLACE PACKAGE stf_rule_pkg AS
  e_invalid_transition EXCEPTION;PROCEDURE validate_transition(p_old VARCHAR2,p_new VARCHAR2);
END stf_rule_pkg;
/
