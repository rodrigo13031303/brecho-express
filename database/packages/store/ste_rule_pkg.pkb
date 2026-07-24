CREATE OR REPLACE PACKAGE BODY ste_rule_pkg AS
  PROCEDURE validate_event(p_name VARCHAR2,p_description VARCHAR2,p_start TIMESTAMP,p_end TIMESTAMP)IS BEGIN
    IF TRIM(p_name)IS NULL OR LENGTH(p_name)>200 OR LENGTH(p_description)>1000 OR p_start IS NULL OR p_end IS NULL OR p_end<p_start THEN RAISE e_invalid;END IF;END;
  PROCEDURE validate_transition(p_old VARCHAR2,p_new VARCHAR2)IS n VARCHAR2(20):=UPPER(TRIM(p_new));BEGIN
    IF NOT((p_old='DRAFT' AND n IN('ACTIVE','CANCELLED'))OR(p_old='ACTIVE' AND n IN('CLOSED','CANCELLED')))THEN RAISE e_invalid_transition;END IF;END;
END ste_rule_pkg;
/
