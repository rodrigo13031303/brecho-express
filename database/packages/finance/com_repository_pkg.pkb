CREATE OR REPLACE PACKAGE BODY com_repository_pkg AS
  PROCEDURE insert_row(p t_row,p_actor NUMBER,o_id OUT NUMBER) IS BEGIN INSERT INTO BEX_COMMISSION(
    COM_PUBLIC_ID,STR_ID,ORD_ID,PAY_ID,COM_BASE_AMOUNT,COM_COMMISSION_RATE,
    COM_COMMISSION_AMOUNT,COM_GATEWAY_FEE_AMOUNT,COM_NET_AMOUNT,COM_CREATED_BY,COM_UPDATED_BY)
    VALUES(p.com_public_id,p.str_id,p.ord_id,p.pay_id,p.com_base_amount,p.com_commission_rate,
    p.com_commission_amount,p.com_gateway_fee_amount,p.com_net_amount,p_actor,p_actor)
    RETURNING COM_ID INTO o_id;END;
END com_repository_pkg;
/
