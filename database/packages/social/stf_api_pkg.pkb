CREATE OR REPLACE PACKAGE BODY stf_api_pkg AS
  FUNCTION js(r stf_service_pkg.t_record)RETURN JSON_OBJECT_T IS j JSON_OBJECT_T:=JSON_OBJECT_T();BEGIN
    core_json_pkg.put_string(j,'followerPublicId',TRIM(r.public_id));core_json_pkg.put_string(j,'status',r.status);RETURN j;END;
  PROCEDURE follow_store(p_store VARCHAR2,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB)IS r stf_service_pkg.t_record;
  BEGIN r:=stf_service_pkg.follow_store(p_store,p_actor);o_body:=core_response_pkg.build_success(js(r));COMMIT;o_status:=201;
  EXCEPTION WHEN stf_service_pkg.e_conflict THEN ROLLBACK;o_status:=409;o_body:=core_response_pkg.build_known_error('BEX-STF-002',core_error_pkg.c_category_conflict,'O perfil ja segue esta loja.');WHEN stf_service_pkg.e_store_not_found THEN ROLLBACK;o_status:=404;o_body:=core_response_pkg.build_known_error('BEX-STR-001',core_error_pkg.c_category_not_found,'A loja informada nao foi encontrada.');
    WHEN stf_service_pkg.e_forbidden THEN ROLLBACK;o_status:=403;o_body:=core_response_pkg.build_known_error('BEX-STF-003',core_error_pkg.c_category_authorization,'Operacao nao autorizada para este perfil.');WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=core_response_pkg.build_technical_error;END;
  PROCEDURE unfollow_store(p_store VARCHAR2,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB)IS r stf_service_pkg.t_record;
  BEGIN r:=stf_service_pkg.unfollow_store(p_store,p_actor);o_body:=core_response_pkg.build_success(js(r));COMMIT;o_status:=200;
  EXCEPTION WHEN stf_service_pkg.e_not_following THEN ROLLBACK;o_status:=409;o_body:=core_response_pkg.build_known_error('BEX-STF-001',core_error_pkg.c_category_conflict,'O perfil nao segue esta loja.');WHEN stf_service_pkg.e_store_not_found THEN ROLLBACK;o_status:=404;o_body:=core_response_pkg.build_known_error('BEX-STR-001',core_error_pkg.c_category_not_found,'A loja informada nao foi encontrada.');
    WHEN stf_service_pkg.e_forbidden THEN ROLLBACK;o_status:=403;o_body:=core_response_pkg.build_known_error('BEX-STF-003',core_error_pkg.c_category_authorization,'Operacao nao autorizada para este perfil.');WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=core_response_pkg.build_technical_error;END;
END stf_api_pkg;
/
