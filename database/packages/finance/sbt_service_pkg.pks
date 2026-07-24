CREATE OR REPLACE PACKAGE sbt_service_pkg AS
  e_invalid EXCEPTION;e_insufficient_balance EXCEPTION;
  PROCEDURE post(p_store NUMBER,p_order NUMBER,p_payment NUMBER,p_payout NUMBER,
    p_type VARCHAR2,p_amount NUMBER,p_direction VARCHAR2,p_available TIMESTAMP,
    p_description VARCHAR2,p_actor NUMBER);
  FUNCTION available_balance(p_store NUMBER) RETURN NUMBER;
  PROCEDURE lock_store(p_store NUMBER);
  PROCEDURE release_hold(p_store NUMBER,p_order NUMBER,p_payment NUMBER,
    p_amount NUMBER,p_actor NUMBER);
END sbt_service_pkg;
/
