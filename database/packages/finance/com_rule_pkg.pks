CREATE OR REPLACE PACKAGE com_rule_pkg AS
  e_invalid EXCEPTION;
  PROCEDURE calculate(p_base NUMBER,p_rate NUMBER,p_gateway_fee NUMBER,
    o_commission OUT NUMBER,o_net OUT NUMBER);
END com_rule_pkg;
/
