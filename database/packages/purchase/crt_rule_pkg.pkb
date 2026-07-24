CREATE OR REPLACE PACKAGE BODY crt_rule_pkg AS
  PROCEDURE validate_quantity(p NUMBER) IS BEGIN
    IF p IS NULL OR p<=0 OR p<>TRUNC(p) THEN RAISE e_invalid_quantity;END IF;END;
  PROCEDURE validate_status(p VARCHAR2) IS x VARCHAR2(30):=UPPER(TRIM(p));BEGIN
    IF x IS NULL OR x NOT IN(c_active,c_checked_out,c_expired,c_abandoned)
    THEN RAISE e_invalid_status;END IF;END;
  PROCEDURE assert_editable(p VARCHAR2) IS BEGIN validate_status(p);
    IF UPPER(TRIM(p))<>c_active THEN RAISE e_cart_closed;END IF;END;
END crt_rule_pkg;
/
