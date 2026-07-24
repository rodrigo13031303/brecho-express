CREATE OR REPLACE PACKAGE BODY rrq_api_pkg AS
  FUNCTION js(r rrq_service_pkg.t_record)RETURN JSON_OBJECT_T IS j JSON_OBJECT_T:=JSON_OBJECT_T();BEGIN
    core_json_pkg.put_string(j,'returnRequestPublicId',TRIM(r.rrq_public_id));core_json_pkg.put_string(j,'reasonCode',r.reason_code);
    core_json_pkg.put_string(j,'status',r.status);core_json_pkg.put_string(j,'result',r.result);core_json_pkg.put_string(j,'storeResponse',r.store_response);RETURN j;END;
  PROCEDURE create_request(p_order VARCHAR2,p_store VARCHAR2,p_body CLOB,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB)IS
    j JSON_OBJECT_T;r rrq_service_pkg.t_record;BEGIN j:=JSON_OBJECT_T.parse(p_body);r:=rrq_service_pkg.open_request(p_order,p_store,
    j.get_string('reasonCode'),j.get_string('description'),p_actor);COMMIT;o_status:=201;o_body:=core_response_pkg.build_success(js(r));
  EXCEPTION WHEN rrq_service_pkg.e_forbidden THEN ROLLBACK;o_status:=403;o_body:=NULL;WHEN rrq_service_pkg.e_invalid THEN ROLLBACK;o_status:=422;o_body:=NULL;
    WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=NULL;END;
  PROCEDURE get_request(p_public VARCHAR2,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB)IS r rrq_service_pkg.t_record;
  BEGIN r:=rrq_service_pkg.get_request(p_public,p_actor);o_status:=200;o_body:=core_response_pkg.build_success(js(r));
  EXCEPTION WHEN rrq_service_pkg.e_not_found THEN o_status:=404;o_body:=NULL;WHEN rrq_service_pkg.e_forbidden THEN o_status:=403;o_body:=NULL;
    WHEN OTHERS THEN o_status:=500;o_body:=NULL;END;
END rrq_api_pkg;
/
