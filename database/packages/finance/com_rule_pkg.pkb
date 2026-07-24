CREATE OR REPLACE PACKAGE BODY com_rule_pkg AS
  PROCEDURE calculate(p_base NUMBER,p_rate NUMBER,p_gateway_fee NUMBER,
    o_commission OUT NUMBER,o_net OUT NUMBER) IS
  BEGIN IF p_base<=0 OR p_rate NOT BETWEEN 0 AND 100 OR p_gateway_fee<0 THEN RAISE e_invalid;END IF;
    o_commission:=ROUND(p_base*p_rate/100,2);o_net:=p_base-o_commission-p_gateway_fee;
    IF o_net<0 THEN RAISE e_invalid;END IF;END;
END com_rule_pkg;
/
