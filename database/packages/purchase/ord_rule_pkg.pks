CREATE OR REPLACE PACKAGE ord_rule_pkg AS
  e_invalid_amount EXCEPTION;e_invalid_transition EXCEPTION;
  PROCEDURE validate_amounts(p_subtotal NUMBER,p_discount NUMBER,p_shipping NUMBER,p_total NUMBER);
  PROCEDURE validate_transition(p_old VARCHAR2,p_new VARCHAR2);
END ord_rule_pkg;
/
