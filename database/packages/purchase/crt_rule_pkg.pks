CREATE OR REPLACE PACKAGE crt_rule_pkg AS
  c_active CONSTANT VARCHAR2(20):='ACTIVE';c_checked_out CONSTANT VARCHAR2(20):='CHECKED_OUT';
  c_expired CONSTANT VARCHAR2(20):='EXPIRED';c_abandoned CONSTANT VARCHAR2(20):='ABANDONED';
  e_invalid_quantity EXCEPTION;e_invalid_status EXCEPTION;e_cart_closed EXCEPTION;
  PROCEDURE validate_quantity(p NUMBER);
  PROCEDURE validate_status(p VARCHAR2);
  PROCEDURE assert_editable(p VARCHAR2);
END crt_rule_pkg;
/
