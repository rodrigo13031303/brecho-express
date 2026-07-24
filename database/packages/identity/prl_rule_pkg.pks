CREATE OR REPLACE PACKAGE prl_rule_pkg AS
  e_invalid_expiry EXCEPTION;e_invalid_transition EXCEPTION;
  PROCEDURE validate_expiry(p_expires TIMESTAMP);
  PROCEDURE validate_transition(p_old VARCHAR2,p_new VARCHAR2);
END prl_rule_pkg;
/
