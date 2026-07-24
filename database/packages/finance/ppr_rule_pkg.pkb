CREATE OR REPLACE PACKAGE BODY ppr_rule_pkg AS
  PROCEDURE validate_data(p_code VARCHAR2,p_name VARCHAR2,p_status VARCHAR2) IS
  BEGIN IF NOT REGEXP_LIKE(UPPER(TRIM(p_code)),'^[A-Z][A-Z0-9_]{1,49}$')
    OR TRIM(p_name) IS NULL OR LENGTH(TRIM(p_name))>100
    OR UPPER(TRIM(p_status)) NOT IN('ACTIVE','INACTIVE') THEN RAISE e_invalid;END IF;END;
END ppr_rule_pkg;
/
