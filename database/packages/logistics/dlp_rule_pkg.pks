CREATE OR REPLACE PACKAGE dlp_rule_pkg AS
  e_invalid EXCEPTION;
  PROCEDURE validate_profile(p_code VARCHAR2,p_name VARCHAR2,p_base NUMBER,
    p_distance NUMBER,p_weight NUMBER,p_express NUMBER);
END dlp_rule_pkg;
/
