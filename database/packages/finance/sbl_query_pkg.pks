CREATE OR REPLACE PACKAGE sbl_query_pkg AS
  TYPE t_record IS RECORD(store_public_id CHAR(32),blocked_amount NUMBER,
    available_amount NUMBER,pending_payout_amount NUMBER,paid_amount NUMBER);
  e_forbidden EXCEPTION;
  FUNCTION get_balance(p_store_public VARCHAR2,p_actor NUMBER) RETURN t_record;
END sbl_query_pkg;
/
