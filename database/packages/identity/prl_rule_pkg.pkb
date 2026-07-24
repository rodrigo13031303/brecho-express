CREATE OR REPLACE PACKAGE BODY prl_rule_pkg AS
  PROCEDURE validate_expiry(p_expires TIMESTAMP)IS BEGIN IF p_expires IS NOT NULL AND p_expires<=SYSTIMESTAMP THEN RAISE e_invalid_expiry;END IF;END;
  PROCEDURE validate_transition(p_old VARCHAR2,p_new VARCHAR2)IS n VARCHAR2(20):=UPPER(TRIM(p_new));BEGIN
    IF NOT((p_old='ACTIVE' AND n='INACTIVE')OR(p_old='INACTIVE' AND n='ACTIVE'))THEN RAISE e_invalid_transition;END IF;END;
END prl_rule_pkg;
/
