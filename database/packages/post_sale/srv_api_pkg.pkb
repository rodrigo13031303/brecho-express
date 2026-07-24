CREATE OR REPLACE PACKAGE BODY srv_api_pkg AS
  FUNCTION js(r srv_service_pkg.t_record)RETURN JSON_OBJECT_T IS j JSON_OBJECT_T:=JSON_OBJECT_T();BEGIN
    core_json_pkg.put_string(j,'reviewPublicId',TRIM(r.srv_public_id));core_json_pkg.put_number(j,'overallRate',r.overall_rate);
    core_json_pkg.put_string(j,'wouldBuyAgain',r.would_buy_again);core_json_pkg.put_string(j,'comment',r.comment_text);
    core_json_pkg.put_string(j,'storeReply',r.store_reply);RETURN j;END;
  PROCEDURE create_review(p_order VARCHAR2,p_store VARCHAR2,p_body CLOB,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB)IS
    j JSON_OBJECT_T;r srv_service_pkg.t_record;BEGIN j:=JSON_OBJECT_T.parse(p_body);r:=srv_service_pkg.create_review(p_order,p_store,
    j.get_number('overallRate'),j.get_number('productMatchRate'),j.get_number('conservationRate'),j.get_number('serviceRate'),
    j.get_number('deliveryRate'),j.get_number('packagingRate'),j.get_string('wouldBuyAgain'),j.get_string('comment'),p_actor);
    COMMIT;o_status:=201;o_body:=core_response_pkg.build_success(js(r));
  EXCEPTION WHEN srv_service_pkg.e_conflict THEN ROLLBACK;o_status:=409;o_body:=NULL;WHEN srv_service_pkg.e_forbidden THEN ROLLBACK;o_status:=403;o_body:=NULL;
    WHEN srv_service_pkg.e_invalid THEN ROLLBACK;o_status:=422;o_body:=NULL;WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=NULL;END;
  PROCEDURE get_review(p_public VARCHAR2,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB)IS r srv_service_pkg.t_record;
  BEGIN r:=srv_service_pkg.get_review(p_public);o_status:=200;o_body:=core_response_pkg.build_success(js(r));
  EXCEPTION WHEN srv_service_pkg.e_not_found THEN o_status:=404;o_body:=NULL;WHEN OTHERS THEN o_status:=500;o_body:=NULL;END;
END srv_api_pkg;
/
