CREATE OR REPLACE PACKAGE BODY sbl_query_pkg AS
  FUNCTION get_balance(p_store_public VARCHAR2,p_actor NUMBER) RETURN t_record IS
    r t_record;id NUMBER;
  BEGIN BEGIN id:=str_service_pkg.resolve_catalog_store_id(p_store_public,p_actor);
    EXCEPTION WHEN str_service_pkg.e_catalog_forbidden THEN RAISE e_forbidden;END;
    r.store_public_id:=p_store_public;
    SELECT NVL(MAX(SBL_BLOCKED_AMOUNT),0),NVL(MAX(SBL_AVAILABLE_AMOUNT),0),
      NVL(MAX(SBL_PENDING_PAYOUT_AMOUNT),0),NVL(MAX(SBL_PAID_AMOUNT),0)
      INTO r.blocked_amount,r.available_amount,r.pending_payout_amount,r.paid_amount
      FROM BEX_STORE_BALANCE WHERE STR_ID=id;RETURN r;END;
END sbl_query_pkg;
/
