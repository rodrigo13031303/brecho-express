CREATE OR REPLACE PACKAGE pev_rule_pkg AS
  e_invalid EXCEPTION;
  PROCEDURE validate_event(p_type VARCHAR2,p_external VARCHAR2,p_at TIMESTAMP,p_payload CLOB);
END pev_rule_pkg;
/
