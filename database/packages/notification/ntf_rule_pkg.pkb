CREATE OR REPLACE PACKAGE BODY ntf_rule_pkg AS
  PROCEDURE validate_notification(p_type VARCHAR2,p_title VARCHAR2,p_body VARCHAR2) IS BEGIN
    IF TRIM(p_type) IS NULL OR TRIM(p_title) IS NULL OR TRIM(p_body) IS NULL THEN RAISE e_invalid; END IF;
  END;
  PROCEDURE validate_channel(p_channel VARCHAR2) IS BEGIN
    IF UPPER(TRIM(p_channel)) NOT IN('IN_APP','EMAIL','PUSH') THEN RAISE e_invalid; END IF;
  END;
END ntf_rule_pkg;
/
