CREATE OR REPLACE PACKAGE pot_rule_pkg AS
  e_invalid EXCEPTION;e_invalid_transition EXCEPTION;
  PROCEDURE validate_request(p_amount NUMBER,p_key VARCHAR2,p_type VARCHAR2);
  PROCEDURE validate_transition(p_old VARCHAR2,p_new VARCHAR2,p_reason VARCHAR2);
END pot_rule_pkg;
/
