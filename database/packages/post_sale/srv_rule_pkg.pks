CREATE OR REPLACE PACKAGE srv_rule_pkg AS
  e_invalid EXCEPTION;
  PROCEDURE validate_review(p_overall NUMBER,p_product NUMBER,p_conservation NUMBER,p_service NUMBER,
    p_delivery NUMBER,p_packaging NUMBER,p_again VARCHAR2,p_comment VARCHAR2);
END srv_rule_pkg;
/
