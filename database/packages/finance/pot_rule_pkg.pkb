CREATE OR REPLACE PACKAGE BODY pot_rule_pkg AS
  PROCEDURE validate_request(p_amount NUMBER,p_key VARCHAR2,p_type VARCHAR2) IS BEGIN
    IF p_amount<=0 OR TRIM(p_key) IS NULL OR LENGTH(TRIM(p_key))>200
      OR UPPER(TRIM(p_type)) NOT IN('CPF','CNPJ','EMAIL','PHONE','RANDOM') THEN RAISE e_invalid;END IF;END;
  PROCEDURE validate_transition(p_old VARCHAR2,p_new VARCHAR2,p_reason VARCHAR2) IS n VARCHAR2(20):=UPPER(TRIM(p_new));
  BEGIN IF NOT((p_old='REQUESTED' AND n IN('APPROVED','REJECTED')) OR(p_old='APPROVED' AND n='PAID'))
    OR(n='REJECTED' AND TRIM(p_reason) IS NULL) THEN RAISE e_invalid_transition;END IF;END;
END pot_rule_pkg;
/
