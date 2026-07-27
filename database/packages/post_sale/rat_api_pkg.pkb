CREATE OR REPLACE PACKAGE BODY rat_api_pkg AS
  PROCEDURE add_attachment(p_request VARCHAR2,p_body CLOB,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB)IS
    j JSON_OBJECT_T;r rat_service_pkg.t_record;x JSON_OBJECT_T:=JSON_OBJECT_T();
  BEGIN j:=core_json_pkg.parse_object(p_body);core_json_pkg.assert_allowed_attributes(j,'type,url,filename,mimeType,sizeBytes,description');r:=rat_service_pkg.add_attachment(p_request,core_json_pkg.required_string(j,'type'),core_json_pkg.required_string(j,'url'),
    core_json_pkg.required_string(j,'filename'),core_json_pkg.required_string(j,'mimeType'),core_json_pkg.required_number(j,'sizeBytes'),core_json_pkg.optional_string(j,'description'),p_actor);
    core_json_pkg.put_string(x,'attachmentPublicId',TRIM(r.rat_public_id));core_json_pkg.put_string(x,'type',r.attachment_type);
    core_json_pkg.put_string(x,'url',r.attachment_url);o_body:=core_response_pkg.build_success(x);COMMIT;o_status:=201;
  EXCEPTION WHEN core_json_pkg.e_unknown_attribute THEN ROLLBACK;o_status:=400;o_body:=core_response_pkg.build_known_error('BEX-REQ-006',core_error_pkg.c_category_validation,'A requisicao contem campo desconhecido.');
    WHEN core_json_pkg.e_request_body_required OR core_json_pkg.e_invalid_json OR core_json_pkg.e_json_object_required OR core_json_pkg.e_required_attribute OR core_json_pkg.e_invalid_attribute_type THEN ROLLBACK;o_status:=400;o_body:=core_response_pkg.build_known_error('BEX-REQ-002',core_error_pkg.c_category_validation,'O anexo informado e estruturalmente invalido.');
    WHEN rat_service_pkg.e_not_found THEN ROLLBACK;o_status:=404;o_body:=core_response_pkg.build_known_error('BEX-RAT-001',core_error_pkg.c_category_not_found,'A avaliacao informada nao foi encontrada.');WHEN rat_service_pkg.e_forbidden THEN ROLLBACK;o_status:=403;o_body:=core_response_pkg.build_known_error('BEX-RAT-002',core_error_pkg.c_category_authorization,'Operacao nao autorizada para esta avaliacao.');
    WHEN rat_service_pkg.e_invalid THEN ROLLBACK;o_status:=422;o_body:=core_response_pkg.build_known_error('BEX-RAT-003',core_error_pkg.c_category_validation,'Os dados da avaliacao sao invalidos.');WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=core_response_pkg.build_technical_error;END;
END rat_api_pkg;
/
