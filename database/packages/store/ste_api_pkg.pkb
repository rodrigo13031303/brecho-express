CREATE OR REPLACE PACKAGE BODY ste_api_pkg AS
  PROCEDURE create_event(p_store VARCHAR2,p_body CLOB,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB)IS
    j JSON_OBJECT_T;x JSON_OBJECT_T:=JSON_OBJECT_T();r ste_service_pkg.t_record;
  BEGIN j:=core_json_pkg.parse_object(p_body);core_json_pkg.assert_allowed_attributes(j,'name,description,startAt,endAt');r:=ste_service_pkg.create_event(p_store,core_json_pkg.required_string(j,'name'),core_json_pkg.optional_string(j,'description'),
    core_json_pkg.required_timestamp_tz(j,'startAt','YYYY-MM-DD"T"HH24:MI:SSTZH:TZM'),core_json_pkg.required_timestamp_tz(j,'endAt','YYYY-MM-DD"T"HH24:MI:SSTZH:TZM'),p_actor);
    core_json_pkg.put_string(x,'eventPublicId',TRIM(r.public_id));core_json_pkg.put_string(x,'name',r.event_name);core_json_pkg.put_string(x,'status',r.status);
    o_body:=core_response_pkg.build_success(x);COMMIT;o_status:=201;
  EXCEPTION WHEN core_json_pkg.e_unknown_attribute THEN ROLLBACK;o_status:=400;o_body:=core_response_pkg.build_known_error('BEX-REQ-006',core_error_pkg.c_category_validation,'A requisicao contem campo desconhecido.');
    WHEN core_json_pkg.e_request_body_required OR core_json_pkg.e_invalid_json OR core_json_pkg.e_json_object_required OR core_json_pkg.e_required_attribute OR core_json_pkg.e_invalid_attribute_type OR core_json_pkg.e_invalid_temporal_value THEN ROLLBACK;o_status:=400;o_body:=core_response_pkg.build_known_error('BEX-REQ-002',core_error_pkg.c_category_validation,'O evento informado e estruturalmente invalido.');
    WHEN ste_service_pkg.e_forbidden THEN ROLLBACK;o_status:=403;o_body:=core_response_pkg.build_known_error('BEX-STE-001',core_error_pkg.c_category_authorization,'Operacao nao autorizada para esta loja.');WHEN ste_service_pkg.e_invalid THEN ROLLBACK;o_status:=422;o_body:=core_response_pkg.build_known_error('BEX-STE-002',core_error_pkg.c_category_validation,'Os dados do evento sao invalidos.');
    WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=core_response_pkg.build_technical_error;END;
END ste_api_pkg;
/
