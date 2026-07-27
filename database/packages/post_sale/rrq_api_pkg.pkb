CREATE OR REPLACE PACKAGE BODY rrq_api_pkg AS
  FUNCTION js(r rrq_service_pkg.t_record)RETURN JSON_OBJECT_T IS j JSON_OBJECT_T:=JSON_OBJECT_T();BEGIN
    core_json_pkg.put_string(j,'returnRequestPublicId',TRIM(r.rrq_public_id));core_json_pkg.put_string(j,'reasonCode',r.reason_code);
    core_json_pkg.put_string(j,'status',r.status);core_json_pkg.put_string(j,'result',r.result);core_json_pkg.put_string(j,'storeResponse',r.store_response);RETURN j;END;
  PROCEDURE create_request(p_order VARCHAR2,p_store VARCHAR2,p_body CLOB,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB)IS
    j JSON_OBJECT_T;r rrq_service_pkg.t_record;BEGIN j:=core_json_pkg.parse_object(p_body);core_json_pkg.assert_allowed_attributes(j,'reasonCode,description');r:=rrq_service_pkg.open_request(p_order,p_store,
    core_json_pkg.required_string(j,'reasonCode'),core_json_pkg.optional_string(j,'description'),p_actor);o_body:=core_response_pkg.build_success(js(r));COMMIT;o_status:=201;
  EXCEPTION WHEN core_json_pkg.e_unknown_attribute THEN ROLLBACK;o_status:=400;o_body:=core_response_pkg.build_known_error('BEX-REQ-006',core_error_pkg.c_category_validation,'A requisicao contem campo desconhecido.');
    WHEN core_json_pkg.e_request_body_required OR core_json_pkg.e_invalid_json OR core_json_pkg.e_json_object_required OR core_json_pkg.e_required_attribute OR core_json_pkg.e_invalid_attribute_type THEN ROLLBACK;o_status:=400;o_body:=core_response_pkg.build_known_error('BEX-REQ-002',core_error_pkg.c_category_validation,'A requisicao de pos-venda e invalida.');
    WHEN rrq_service_pkg.e_forbidden THEN ROLLBACK;o_status:=403;o_body:=core_response_pkg.build_known_error('BEX-RRQ-002',core_error_pkg.c_category_authorization,'Operacao nao autorizada para esta solicitacao.');WHEN rrq_service_pkg.e_invalid THEN ROLLBACK;o_status:=422;o_body:=core_response_pkg.build_known_error('BEX-RRQ-003',core_error_pkg.c_category_validation,'Os dados da solicitacao sao invalidos.');
    WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=core_response_pkg.build_technical_error;END;
  PROCEDURE get_request(p_public VARCHAR2,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB)IS r rrq_service_pkg.t_record;
  BEGIN r:=rrq_service_pkg.get_request(p_public,p_actor);o_status:=200;o_body:=core_response_pkg.build_success(js(r));
  EXCEPTION WHEN rrq_service_pkg.e_not_found THEN o_status:=404;o_body:=core_response_pkg.build_known_error('BEX-RRQ-001',core_error_pkg.c_category_not_found,'A solicitacao informada nao foi encontrada.');WHEN rrq_service_pkg.e_forbidden THEN o_status:=403;o_body:=core_response_pkg.build_known_error('BEX-RRQ-002',core_error_pkg.c_category_authorization,'Operacao nao autorizada para esta solicitacao.');
    WHEN OTHERS THEN o_status:=500;o_body:=core_response_pkg.build_technical_error;END;
END rrq_api_pkg;
/
