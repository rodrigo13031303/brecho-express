CREATE OR REPLACE PACKAGE BODY acc_auth_api_pkg AS
  PROCEDURE error_response(p_status NUMBER,p_code VARCHAR2,p_message VARCHAR2,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS e core_error_pkg.t_public_error;policy core_error_pkg.t_error_policy;BEGIN core_error_pkg.build_known_error(p_code,core_error_pkg.c_category_authentication,p_message,core_error_pkg.c_severity_warn,FALSE,FALSE,e,policy);o_body:=core_response_pkg.build_error(e);o_status:=p_status;END;
  PROCEDURE login(p_request_body IN CLOB,p_ip IN VARCHAR2,p_user_agent IN VARCHAR2,o_status_code OUT PLS_INTEGER,o_response_body OUT NOCOPY CLOB) IS
    o JSON_OBJECT_T; a BEX_ACCOUNT%ROWTYPE; sid VARCHAR2(32); tok VARCHAR2(64); exp TIMESTAMP; data JSON_OBJECT_T:=JSON_OBJECT_T();
  BEGIN
    o:=core_json_pkg.parse_object(p_request_body);
    core_json_pkg.assert_allowed_attributes(o,'email,password');
    a:=acc_service_pkg.authenticate(core_json_pkg.required_string(o,'email'),core_json_pkg.required_string(o,'password'));
    acc_session_api_pkg.create_session(a.ACC_ID,1440,a.ACC_ID,p_ip,p_user_agent,sid,tok,exp);
    core_json_pkg.put_string(data,'accessToken',tok);core_json_pkg.put_string(data,'sessionPublicId',sid);core_json_pkg.put_string(data,'expiresAt',core_json_pkg.format_timestamp(exp));core_json_pkg.put_string(data,'accountPublicId',TRIM(a.ACC_PUBLIC_ID));
    o_response_body:=core_response_pkg.build_success(data);COMMIT;o_status_code:=200;
  EXCEPTION WHEN core_json_pkg.e_unknown_attribute THEN ROLLBACK;o_status_code:=400;o_response_body:=core_response_pkg.build_known_error('BEX-REQ-006',core_error_pkg.c_category_validation,'A requisicao contem campo desconhecido.');
    WHEN core_json_pkg.e_request_body_required OR core_json_pkg.e_invalid_json OR core_json_pkg.e_json_object_required OR core_json_pkg.e_required_attribute OR core_json_pkg.e_invalid_attribute_type THEN ROLLBACK;o_status_code:=400;o_response_body:=core_response_pkg.build_known_error('BEX-REQ-002',core_error_pkg.c_category_validation,'A requisicao de autenticacao e invalida.');
    WHEN acc_service_pkg.e_invalid_credentials THEN ROLLBACK;error_response(401,'BEX-AUTH-001','Credenciais invalidas.',o_status_code,o_response_body); WHEN OTHERS THEN ROLLBACK;o_status_code:=500;o_response_body:=core_response_pkg.build_technical_error; END;
  PROCEDURE logout(p_session_public_id IN VARCHAR2,p_actor_id IN NUMBER,o_status_code OUT PLS_INTEGER,o_response_body OUT NOCOPY CLOB) IS BEGIN acc_session_api_pkg.revoke_session(p_session_public_id,p_actor_id);o_response_body:=NULL;COMMIT;o_status_code:=204;EXCEPTION WHEN OTHERS THEN ROLLBACK;o_status_code:=401;o_response_body:=core_response_pkg.build_known_error('BEX-AUTH-002',core_error_pkg.c_category_authentication,'A sessao informada nao e valida.');END;
END acc_auth_api_pkg;
/
