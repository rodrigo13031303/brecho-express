CREATE OR REPLACE PACKAGE BODY adr_rule_pkg AS
  PROCEDURE validate_address(p_zip VARCHAR2,p_street VARCHAR2,p_number VARCHAR2,
    p_district VARCHAR2,p_city VARCHAR2,p_state VARCHAR2,p_country VARCHAR2,
    p_lat NUMBER,p_lon NUMBER) IS
  BEGIN
    IF NOT REGEXP_LIKE(TRIM(p_zip),'^[0-9]{5}-?[0-9]{3}$') OR TRIM(p_street) IS NULL
      OR TRIM(p_number) IS NULL OR TRIM(p_district) IS NULL OR TRIM(p_city) IS NULL
      OR NOT REGEXP_LIKE(UPPER(TRIM(p_state)),'^[A-Z]{2}$')
      OR NOT REGEXP_LIKE(UPPER(TRIM(p_country)),'^[A-Z]{2}$')
      OR((p_lat IS NULL)<>(p_lon IS NULL))
      OR p_lat NOT BETWEEN -90 AND 90 OR p_lon NOT BETWEEN -180 AND 180
    THEN RAISE e_invalid_address;END IF;
  END;
END adr_rule_pkg;
/
