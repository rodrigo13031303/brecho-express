CREATE OR REPLACE PACKAGE BODY srv_rule_pkg AS
  PROCEDURE validate_review(p_overall NUMBER,p_product NUMBER,p_conservation NUMBER,p_service NUMBER,
    p_delivery NUMBER,p_packaging NUMBER,p_again VARCHAR2,p_comment VARCHAR2)IS
    PROCEDURE rate(n NUMBER,required BOOLEAN:=FALSE)IS BEGIN IF(required AND n IS NULL)OR(n IS NOT NULL AND(n<1 OR n>5 OR n<>TRUNC(n)))THEN RAISE e_invalid;END IF;END;
  BEGIN rate(p_overall,TRUE);rate(p_product);rate(p_conservation);rate(p_service);rate(p_delivery);rate(p_packaging);
    IF p_again IS NOT NULL AND UPPER(TRIM(p_again))NOT IN('Y','N')OR LENGTH(p_comment)>2000 THEN RAISE e_invalid;END IF;END;
END srv_rule_pkg;
/
