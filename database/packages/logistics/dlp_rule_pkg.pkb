CREATE OR REPLACE PACKAGE BODY dlp_rule_pkg AS
  PROCEDURE validate_profile(p_code VARCHAR2,p_name VARCHAR2,p_base NUMBER,
    p_distance NUMBER,p_weight NUMBER,p_express NUMBER) IS c VARCHAR2(50):=UPPER(TRIM(p_code));
  BEGIN IF c NOT IN('PICKUP','LOCAL','EXPRESS','NATIONAL') OR TRIM(p_name) IS NULL
    OR LENGTH(TRIM(p_name))>100 OR p_base<0 OR p_distance<=0 OR p_weight<=0
    OR NVL(p_express,-1) NOT IN(0,1) THEN RAISE e_invalid;END IF;END;
END dlp_rule_pkg;
/
