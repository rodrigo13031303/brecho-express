CREATE OR REPLACE PACKAGE BODY pot_api_pkg AS
  FUNCTION js(p pot_service_pkg.t_record) RETURN JSON_OBJECT_T IS j JSON_OBJECT_T:=JSON_OBJECT_T();
  BEGIN core_json_pkg.put_string(j,'payoutPublicId',TRIM(p.payout_public_id));
    core_json_pkg.put_string(j,'storePublicId',TRIM(p.store_public_id));core_json_pkg.put_number(j,'amount',p.amount);
    core_json_pkg.put_string(j,'pixKeyType',p.pix_key_type);core_json_pkg.put_string(j,'status',p.status);RETURN j;END;
  PROCEDURE request_payout(p_store VARCHAR2,p_body CLOB,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS
    j JSON_OBJECT_T;r pot_service_pkg.t_record;
  BEGIN j:=JSON_OBJECT_T.parse(p_body);r:=pot_service_pkg.request_payout(p_store,j.get_number('amount'),
    j.get_string('pixKey'),j.get_string('pixKeyType'),p_actor);COMMIT;
    o_body:=core_response_pkg.build_success(js(r));o_status:=201;
  EXCEPTION WHEN pot_service_pkg.e_insufficient THEN ROLLBACK;o_status:=422;o_body:=NULL;
    WHEN pot_service_pkg.e_invalid THEN ROLLBACK;o_status:=422;o_body:=NULL;
    WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=NULL;END;
  PROCEDURE get_payout(p_public VARCHAR2,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS r pot_service_pkg.t_record;
  BEGIN r:=pot_service_pkg.get_payout(p_public,p_actor);o_body:=core_response_pkg.build_success(js(r));o_status:=200;
  EXCEPTION WHEN pot_service_pkg.e_not_found THEN o_status:=404;o_body:=NULL;
    WHEN pot_service_pkg.e_forbidden THEN o_status:=403;o_body:=NULL;WHEN OTHERS THEN o_status:=500;o_body:=NULL;END;
END pot_api_pkg;
/
