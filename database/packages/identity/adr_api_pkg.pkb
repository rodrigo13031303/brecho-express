CREATE OR REPLACE PACKAGE BODY adr_api_pkg AS
  e_bad EXCEPTION;
  FUNCTION js(p adr_service_pkg.t_record) RETURN JSON_OBJECT_T IS j JSON_OBJECT_T:=JSON_OBJECT_T();
  BEGIN core_json_pkg.put_string(j,'addressPublicId',TRIM(p.adr_public_id));
    IF p.adr_label IS NULL THEN core_json_pkg.put_null(j,'label');ELSE core_json_pkg.put_string(j,'label',p.adr_label);END IF;
    core_json_pkg.put_string(j,'zipCode',p.adr_zip_code);core_json_pkg.put_string(j,'street',p.adr_street);
    core_json_pkg.put_string(j,'number',p.adr_number);
    IF p.adr_complement IS NULL THEN core_json_pkg.put_null(j,'complement');ELSE core_json_pkg.put_string(j,'complement',p.adr_complement);END IF;
    core_json_pkg.put_string(j,'district',p.adr_district);
    core_json_pkg.put_string(j,'city',p.adr_city);core_json_pkg.put_string(j,'state',p.adr_state);
    core_json_pkg.put_string(j,'country',p.adr_country);
    IF p.adr_latitude IS NULL THEN core_json_pkg.put_null(j,'latitude');ELSE core_json_pkg.put_number(j,'latitude',p.adr_latitude);END IF;
    IF p.adr_longitude IS NULL THEN core_json_pkg.put_null(j,'longitude');ELSE core_json_pkg.put_number(j,'longitude',p.adr_longitude);END IF;
    core_json_pkg.put_boolean(j,'isDefault',p.adr_is_default=1);
    core_json_pkg.put_string(j,'status',p.adr_status);RETURN j;END;
  PROCEDURE err(s NUMBER,c VARCHAR2,m VARCHAR2,os OUT PLS_INTEGER,ob OUT NOCOPY CLOB) IS
    e core_error_pkg.t_public_error;p core_error_pkg.t_error_policy;
  BEGIN core_error_pkg.build_known_error(c,CASE WHEN s=404 THEN core_error_pkg.c_category_not_found
    WHEN s=403 THEN core_error_pkg.c_category_authorization ELSE core_error_pkg.c_category_validation END,
    m,core_error_pkg.c_severity_warn,FALSE,FALSE,e,p);ob:=core_response_pkg.build_error(e);os:=s;END;
  PROCEDURE create_address(p_body CLOB,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS
    j JSON_OBJECT_T;r adr_repository_pkg.t_row;x adr_service_pkg.t_record;
  BEGIN IF p_actor IS NULL THEN RAISE e_bad;END IF;j:=core_json_pkg.parse_object(p_body);core_json_pkg.assert_allowed_attributes(j,'label,zipCode,street,number,complement,district,city,state,country,latitude,longitude,isDefault');
    r.adr_label:=core_json_pkg.optional_string(j,'label');r.adr_zip_code:=core_json_pkg.required_string(j,'zipCode');r.adr_street:=core_json_pkg.required_string(j,'street');
    r.adr_number:=core_json_pkg.required_string(j,'number');r.adr_complement:=core_json_pkg.optional_string(j,'complement');
    r.adr_district:=core_json_pkg.required_string(j,'district');r.adr_city:=core_json_pkg.required_string(j,'city');r.adr_state:=core_json_pkg.required_string(j,'state');
    r.adr_country:=core_json_pkg.required_string(j,'country');
    IF j.has('latitude') THEN r.adr_latitude:=core_json_pkg.required_number(j,'latitude');END IF;
    IF j.has('longitude') THEN r.adr_longitude:=core_json_pkg.required_number(j,'longitude');END IF;
    IF j.has('isDefault') AND core_json_pkg.required_boolean(j,'isDefault') THEN r.adr_is_default:=1;END IF;
    x:=adr_service_pkg.create_address(r,p_actor);o_body:=core_response_pkg.build_success(js(x));COMMIT;o_status:=201;
  EXCEPTION WHEN core_json_pkg.e_unknown_attribute THEN ROLLBACK;err(400,'BEX-REQ-006','A requisicao contem campo desconhecido.',o_status,o_body);
    WHEN core_json_pkg.e_request_body_required OR core_json_pkg.e_invalid_json OR core_json_pkg.e_json_object_required OR core_json_pkg.e_required_attribute OR core_json_pkg.e_invalid_attribute_type THEN ROLLBACK;err(400,'BEX-REQ-002','O endereco informado e estruturalmente invalido.',o_status,o_body);
    WHEN e_bad THEN ROLLBACK;err(400,'BEX-REQ-004','O ator tecnico e obrigatorio.',o_status,o_body);
    WHEN adr_service_pkg.e_invalid THEN ROLLBACK;err(422,'BEX-ADR-002','Endereco invalido.',o_status,o_body);
    WHEN adr_service_pkg.e_forbidden THEN ROLLBACK;err(403,'BEX-ADR-003','Operacao nao autorizada.',o_status,o_body);
    WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=core_response_pkg.build_technical_error;END;
  PROCEDURE list_addresses(p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS
    r adr_service_pkg.t_table;a JSON_ARRAY_T:=JSON_ARRAY_T();i PLS_INTEGER;
  BEGIN r:=adr_service_pkg.list_addresses(p_actor);i:=r.FIRST;WHILE i IS NOT NULL LOOP
    core_json_pkg.append_element(a,js(r(i)));i:=r.NEXT(i);END LOOP;o_body:=core_response_pkg.build_success(a);o_status:=200;
  EXCEPTION WHEN adr_service_pkg.e_forbidden THEN err(403,'BEX-ADR-003','Operacao nao autorizada.',o_status,o_body);
    WHEN OTHERS THEN o_status:=500;o_body:=core_response_pkg.build_technical_error;END;
  PROCEDURE set_default(p_public VARCHAR2,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS r adr_service_pkg.t_record;
  BEGIN r:=adr_service_pkg.set_default(p_public,p_actor);o_body:=core_response_pkg.build_success(js(r));COMMIT;o_status:=200;
  EXCEPTION WHEN adr_service_pkg.e_not_found THEN ROLLBACK;err(404,'BEX-ADR-001','Endereco nao encontrado.',o_status,o_body);
    WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=core_response_pkg.build_technical_error;END;
  PROCEDURE deactivate(p_public VARCHAR2,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS r adr_service_pkg.t_record;
  BEGIN r:=adr_service_pkg.deactivate(p_public,p_actor);o_body:=core_response_pkg.build_success(js(r));COMMIT;o_status:=200;
  EXCEPTION WHEN adr_service_pkg.e_not_found THEN ROLLBACK;err(404,'BEX-ADR-001','Endereco nao encontrado.',o_status,o_body);
    WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=core_response_pkg.build_technical_error;END;
END adr_api_pkg;
/
