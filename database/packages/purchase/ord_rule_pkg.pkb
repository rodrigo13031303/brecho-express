CREATE OR REPLACE PACKAGE BODY ord_rule_pkg AS
  PROCEDURE validate_amounts(p_subtotal NUMBER,p_discount NUMBER,p_shipping NUMBER,p_total NUMBER) IS
  BEGIN IF p_subtotal<0 OR NVL(p_discount,0)<0 OR NVL(p_shipping,0)<0
    OR p_total<>p_subtotal-NVL(p_discount,0)+NVL(p_shipping,0) THEN RAISE e_invalid_amount;END IF;END;
  PROCEDURE validate_transition(p_old VARCHAR2,p_new VARCHAR2) IS n VARCHAR2(20):=UPPER(TRIM(p_new));
  BEGIN IF NOT((p_old='PAID' AND n IN('PROCESSING','CANCELLED')) OR
    (p_old='PROCESSING' AND n IN('SHIPPED','CANCELLED')) OR
    (p_old='SHIPPED' AND n='COMPLETED')) THEN RAISE e_invalid_transition;END IF;END;
END ord_rule_pkg;
/
