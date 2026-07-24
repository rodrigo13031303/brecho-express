CREATE OR REPLACE PACKAGE BODY rrq_rule_pkg AS
  PROCEDURE validate_open(p_reason VARCHAR2,p_description VARCHAR2) IS r VARCHAR2(50):=UPPER(TRIM(p_reason));
  BEGIN IF r IS NULL OR NOT REGEXP_LIKE(r,'^[A-Z][A-Z0-9_]{1,49}$') OR LENGTH(p_description)>2000 THEN RAISE e_invalid;END IF;END;
  PROCEDURE validate_transition(p_old VARCHAR2,p_new VARCHAR2,p_result VARCHAR2) IS n VARCHAR2(20):=UPPER(TRIM(p_new));
  BEGIN IF NOT((p_old='OPEN' AND n='UNDER_REVIEW')OR(p_old='UNDER_REVIEW' AND n='DECIDED' AND p_result IS NOT NULL)
    OR(p_old='DECIDED' AND n='CLOSED' AND p_result IS NOT NULL))THEN RAISE e_invalid_transition;END IF;END;
END rrq_rule_pkg;
/
