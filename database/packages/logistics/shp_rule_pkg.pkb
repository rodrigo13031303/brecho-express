CREATE OR REPLACE PACKAGE BODY shp_rule_pkg AS
  PROCEDURE validate_transition(p_old VARCHAR2,p_new VARCHAR2) IS n VARCHAR2(20):=UPPER(TRIM(p_new));
  BEGIN IF NOT((p_old='CREATED' AND n IN('READY','CANCELLED')) OR
    (p_old='READY' AND n IN('IN_TRANSIT','CANCELLED')) OR
    (p_old='IN_TRANSIT' AND n='DELIVERED')) THEN RAISE e_invalid_transition;END IF;END;
END shp_rule_pkg;
/
