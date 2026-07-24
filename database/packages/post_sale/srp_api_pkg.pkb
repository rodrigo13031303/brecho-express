CREATE OR REPLACE PACKAGE BODY srp_api_pkg AS
  PROCEDURE get_store(p_store VARCHAR2,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB)IS
    r srp_query_pkg.t_record;j JSON_OBJECT_T:=JSON_OBJECT_T();
  BEGIN r:=srp_query_pkg.get_store(p_store);core_json_pkg.put_string(j,'storePublicId',TRIM(r.store_public_id));
    core_json_pkg.put_number(j,'overallRate',r.overall_rate);core_json_pkg.put_number(j,'reviewCount',r.review_count);
    core_json_pkg.put_number(j,'orderCount',r.order_count);core_json_pkg.put_number(j,'returnRequestCount',r.return_request_count);
    core_json_pkg.put_number(j,'returnRate',r.return_rate);core_json_pkg.put_number(j,'wouldBuyAgainRate',r.would_buy_again_rate);
    o_status:=200;o_body:=core_response_pkg.build_success(j);
  EXCEPTION WHEN srp_query_pkg.e_not_found THEN o_status:=404;o_body:=NULL;WHEN OTHERS THEN o_status:=500;o_body:=NULL;END;
END srp_api_pkg;
/
