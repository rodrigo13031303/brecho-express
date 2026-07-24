CREATE OR REPLACE PACKAGE com_service_pkg AS
  e_invalid EXCEPTION;e_payment_not_approved EXCEPTION;e_conflict EXCEPTION;
  PROCEDURE settle_payment(p_payment_public VARCHAR2,p_commission_rate NUMBER,
    p_gateway_fee NUMBER,p_available_at TIMESTAMP,p_actor NUMBER);
END com_service_pkg;
/
