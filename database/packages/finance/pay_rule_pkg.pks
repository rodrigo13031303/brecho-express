CREATE OR REPLACE PACKAGE pay_rule_pkg AS
  e_invalid EXCEPTION;e_invalid_transition EXCEPTION;
  PROCEDURE validate_creation(p_amount NUMBER,p_method VARCHAR2);
  PROCEDURE validate_event(p_old VARCHAR2,p_event VARCHAR2,o_new OUT VARCHAR2);
END pay_rule_pkg;
/
