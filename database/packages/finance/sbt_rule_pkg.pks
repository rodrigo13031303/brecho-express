CREATE OR REPLACE PACKAGE sbt_rule_pkg AS
  e_invalid EXCEPTION;
  PROCEDURE validate_movement(p_type VARCHAR2,p_amount NUMBER,p_direction VARCHAR2);
END sbt_rule_pkg;
/
