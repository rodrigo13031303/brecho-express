CREATE OR REPLACE PACKAGE BODY sbl_api_pkg AS
  PROCEDURE get_balance(p_store_public VARCHAR2,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS
    r sbl_query_pkg.t_record;j JSON_OBJECT_T:=JSON_OBJECT_T();
  BEGIN r:=sbl_query_pkg.get_balance(p_store_public,p_actor);
    core_json_pkg.put_string(j,'storePublicId',TRIM(r.store_public_id));
    core_json_pkg.put_number(j,'blockedAmount',r.blocked_amount);core_json_pkg.put_number(j,'availableAmount',r.available_amount);
    core_json_pkg.put_number(j,'pendingPayoutAmount',r.pending_payout_amount);core_json_pkg.put_number(j,'paidAmount',r.paid_amount);
    o_body:=core_response_pkg.build_success(j);o_status:=200;
  EXCEPTION WHEN sbl_query_pkg.e_forbidden THEN o_status:=403;o_body:=NULL;WHEN OTHERS THEN o_status:=500;o_body:=NULL;END;
END sbl_api_pkg;
/
