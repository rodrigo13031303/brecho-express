CREATE OR REPLACE PACKAGE rrq_rule_pkg AS
  e_invalid EXCEPTION;e_invalid_transition EXCEPTION;
  PROCEDURE validate_open(p_reason VARCHAR2,p_description VARCHAR2);
  PROCEDURE validate_transition(p_old VARCHAR2,p_new VARCHAR2,p_result VARCHAR2);
END rrq_rule_pkg;
/
