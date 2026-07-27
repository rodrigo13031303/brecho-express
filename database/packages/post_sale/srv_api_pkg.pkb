CREATE OR REPLACE PACKAGE BODY srv_api_pkg AS
  FUNCTION js(r srv_service_pkg.t_record)RETURN JSON_OBJECT_T IS j JSON_OBJECT_T:=JSON_OBJECT_T();BEGIN
    core_json_pkg.put_string(j,'reviewPublicId',TRIM(r.srv_public_id));core_json_pkg.put_number(j,'overallRate',r.overall_rate);
    core_json_pkg.put_string(j,'wouldBuyAgain',r.would_buy_again);core_json_pkg.put_string(j,'comment',r.comment_text);
    core_json_pkg.put_string(j,'storeReply',r.store_reply);RETURN j;END;
  PROCEDURE create_review(p_order VARCHAR2,p_store VARCHAR2,p_body CLOB,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB)IS
    j JSON_OBJECT_T;r srv_service_pkg.t_record;BEGIN j:=core_json_pkg.parse_object(p_body);core_json_pkg.assert_allowed_attributes(j,'overallRate,productMatchRate,conservationRate,serviceRate,deliveryRate,packagingRate,wouldBuyAgain,comment');r:=srv_service_pkg.create_review(p_order,p_store,
    core_json_pkg.required_number(j,'overallRate'),core_json_pkg.required_number(j,'productMatchRate'),core_json_pkg.required_number(j,'conservationRate'),core_json_pkg.required_number(j,'serviceRate'),
    core_json_pkg.required_number(j,'deliveryRate'),core_json_pkg.required_number(j,'packagingRate'),core_json_pkg.required_string(j,'wouldBuyAgain'),core_json_pkg.optional_string(j,'comment'),p_actor);
    o_body:=core_response_pkg.build_success(js(r));COMMIT;o_status:=201;
  EXCEPTION WHEN core_json_pkg.e_unknown_attribute THEN ROLLBACK;o_status:=400;o_body:=core_response_pkg.build_known_error('BEX-REQ-006',core_error_pkg.c_category_validation,'A requisicao contem campo desconhecido.');
    WHEN core_json_pkg.e_request_body_required OR core_json_pkg.e_invalid_json OR core_json_pkg.e_json_object_required OR core_json_pkg.e_required_attribute OR core_json_pkg.e_invalid_attribute_type THEN ROLLBACK;o_status:=400;o_body:=core_response_pkg.build_known_error('BEX-REQ-002',core_error_pkg.c_category_validation,'A avaliacao informada e estruturalmente invalida.');
    WHEN srv_service_pkg.e_conflict THEN ROLLBACK;o_status:=409;o_body:=core_response_pkg.build_known_error('BEX-SRV-002',core_error_pkg.c_category_conflict,'A avaliacao de atendimento esta em conflito com o estado atual.');WHEN srv_service_pkg.e_forbidden THEN ROLLBACK;o_status:=403;o_body:=core_response_pkg.build_known_error('BEX-SRV-003',core_error_pkg.c_category_authorization,'Operacao nao autorizada para esta avaliacao.');
    WHEN srv_service_pkg.e_invalid THEN ROLLBACK;o_status:=422;o_body:=core_response_pkg.build_known_error('BEX-SRV-004',core_error_pkg.c_category_validation,'Os dados da avaliacao sao invalidos.');WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=core_response_pkg.build_technical_error;END;
  PROCEDURE get_review(p_public VARCHAR2,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB)IS r srv_service_pkg.t_record;
  BEGIN r:=srv_service_pkg.get_review(p_public);o_status:=200;o_body:=core_response_pkg.build_success(js(r));
  EXCEPTION WHEN srv_service_pkg.e_not_found THEN o_status:=404;o_body:=core_response_pkg.build_known_error('BEX-SRV-001',core_error_pkg.c_category_not_found,'A avaliacao informada nao foi encontrada.');WHEN OTHERS THEN o_status:=500;o_body:=core_response_pkg.build_technical_error;END;
END srv_api_pkg;
/
