CREATE OR REPLACE PACKAGE BODY com_service_pkg AS
  PROCEDURE settle_payment(p_payment_public VARCHAR2,p_commission_rate NUMBER,
    p_gateway_fee NUMBER,p_available_at TIMESTAMP,p_actor NUMBER) IS
    p pay_repository_pkg.t_row;src ord_service_pkg.t_settlement_source;i PLS_INTEGER;
    c com_repository_pkg.t_row;id NUMBER;fee NUMBER;
  BEGIN p:=pay_service_pkg.get_internal(p_payment_public);
    IF p.pay_status<>'APPROVED' OR p.ord_id IS NULL THEN RAISE e_payment_not_approved;END IF;
    src:=ord_service_pkg.settlement_source(p.ord_id);i:=src.items.FIRST;
    WHILE i IS NOT NULL LOOP c.com_public_id:=LOWER(RAWTOHEX(SYS_GUID()));c.str_id:=src.items(i).store_id;
      c.ord_id:=p.ord_id;c.pay_id:=p.pay_id;c.com_base_amount:=src.items(i).base_amount;
      c.com_commission_rate:=p_commission_rate;fee:=ROUND(p_gateway_fee*src.items(i).base_amount/p.pay_amount,2);
      c.com_gateway_fee_amount:=fee;BEGIN com_rule_pkg.calculate(c.com_base_amount,p_commission_rate,
        fee,c.com_commission_amount,c.com_net_amount);EXCEPTION WHEN com_rule_pkg.e_invalid THEN RAISE e_invalid;END;
      BEGIN com_repository_pkg.insert_row(c,p_actor,id);EXCEPTION WHEN DUP_VAL_ON_INDEX THEN RAISE e_conflict;END;
      sbt_service_pkg.post(c.str_id,c.ord_id,c.pay_id,NULL,'SALE_HOLD',c.com_net_amount,'CREDIT',
        p_available_at,'Net sale amount on hold',p_actor);i:=src.items.NEXT(i);END LOOP;END;
END com_service_pkg;
/
