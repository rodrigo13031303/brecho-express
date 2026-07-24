CREATE OR REPLACE PACKAGE com_repository_pkg AS
  TYPE t_row IS RECORD(com_id NUMBER,com_public_id CHAR(32),str_id NUMBER,ord_id NUMBER,
    pay_id NUMBER,com_base_amount NUMBER,com_commission_rate NUMBER,
    com_commission_amount NUMBER,com_gateway_fee_amount NUMBER,com_net_amount NUMBER);
  PROCEDURE insert_row(p t_row,p_actor NUMBER,o_id OUT NUMBER);
END com_repository_pkg;
/
