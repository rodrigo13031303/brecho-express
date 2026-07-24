CREATE OR REPLACE PACKAGE ste_rule_pkg AS
  e_invalid EXCEPTION;e_invalid_transition EXCEPTION;
  PROCEDURE validate_event(p_name VARCHAR2,p_description VARCHAR2,p_start TIMESTAMP,p_end TIMESTAMP);
  PROCEDURE validate_transition(p_old VARCHAR2,p_new VARCHAR2);
END ste_rule_pkg;
/
