CREATE OR REPLACE PACKAGE BODY stf_rule_pkg AS
  PROCEDURE validate_transition(p_old VARCHAR2,p_new VARCHAR2)IS n VARCHAR2(20):=UPPER(TRIM(p_new));BEGIN
    IF NOT((p_old='ACTIVE' AND n='INACTIVE')OR(p_old='INACTIVE' AND n='ACTIVE'))THEN RAISE e_invalid_transition;END IF;END;
END stf_rule_pkg;
/
