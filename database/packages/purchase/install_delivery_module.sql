WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT Installing purchase delivery packages...

CREATE OR REPLACE PACKAGE pdl_service_pkg AS
  TYPE t_record IS RECORD(
    delivery_public_id CHAR(32),
    request_public_id CHAR(32),
    address_public_id CHAR(32),
    label VARCHAR2(100),
    zip_code VARCHAR2(10),
    street VARCHAR2(200),
    number_value VARCHAR2(50),
    complement VARCHAR2(200),
    district VARCHAR2(100),
    city VARCHAR2(100),
    state_code CHAR(2),
    country_code CHAR(2),
    status VARCHAR2(30)
  );
  e_not_found EXCEPTION;
  e_forbidden EXCEPTION;
  e_request_closed EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_not_found,-20695);
  PRAGMA EXCEPTION_INIT(e_forbidden,-20696);
  PRAGMA EXCEPTION_INIT(e_request_closed,-20697);
  FUNCTION get_delivery(
    p_request_public_id VARCHAR2,p_actor_id NUMBER
  ) RETURN t_record;
  FUNCTION select_address(
    p_request_public_id VARCHAR2,p_address_public_id VARCHAR2,p_actor_id NUMBER
  ) RETURN t_record;
END pdl_service_pkg;
/

CREATE OR REPLACE PACKAGE BODY pdl_service_pkg AS
  FUNCTION owned_request(
    p_public_id VARCHAR2,p_actor_id NUMBER
  ) RETURN pur_repository_pkg.t_request IS
    r pur_repository_pkg.t_request;
    p BEX_PROFILE%ROWTYPE;
  BEGIN
    BEGIN r:=pur_repository_pkg.get_request_by_public(p_public_id);
    EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_found;END;
    BEGIN p:=pfl_service_pkg.get_by_account_id(p_actor_id);
    EXCEPTION WHEN pfl_service_pkg.e_profile_not_found THEN RAISE e_forbidden;END;
    IF r.pfl_id<>p.pfl_id THEN RAISE e_forbidden;END IF;
    RETURN r;
  END;

  FUNCTION map_row(p_id NUMBER) RETURN t_record IS
    r t_record;
  BEGIN
    SELECT d.PDL_PUBLIC_ID,q.PUR_PUBLIC_ID,a.ADR_PUBLIC_ID,d.PDL_LABEL,
      d.PDL_ZIP_CODE,d.PDL_STREET,d.PDL_NUMBER,d.PDL_COMPLEMENT,
      d.PDL_DISTRICT,d.PDL_CITY,d.PDL_STATE,d.PDL_COUNTRY,d.PDL_STATUS
    INTO r
    FROM BEX_PURCHASE_DELIVERY d
    JOIN BEX_PURCHASE_REQUEST q ON q.PUR_ID=d.PUR_ID
    JOIN BEX_ADDRESS a ON a.ADR_ID=d.ADR_ID
    WHERE d.PDL_ID=p_id;
    RETURN r;
  END;

  FUNCTION get_delivery(
    p_request_public_id VARCHAR2,p_actor_id NUMBER
  ) RETURN t_record IS
    q pur_repository_pkg.t_request;
    id NUMBER;
  BEGIN
    q:=owned_request(p_request_public_id,p_actor_id);
    BEGIN
      SELECT PDL_ID INTO id FROM BEX_PURCHASE_DELIVERY WHERE PUR_ID=q.pur_id;
    EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_found;END;
    RETURN map_row(id);
  END;

  FUNCTION select_address(
    p_request_public_id VARCHAR2,p_address_public_id VARCHAR2,p_actor_id NUMBER
  ) RETURN t_record IS
    q pur_repository_pkg.t_request;
    a adr_repository_pkg.t_row;
    id NUMBER;
  BEGIN
    q:=owned_request(p_request_public_id,p_actor_id);
    IF q.pur_status NOT IN('APPROVED','PARTIALLY_APPROVED') THEN
      RAISE e_request_closed;
    END IF;
    BEGIN a:=adr_repository_pkg.by_public(p_address_public_id);
    EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_found;END;
    IF a.pfl_id<>q.pfl_id OR a.adr_status<>'ACTIVE' THEN RAISE e_forbidden;END IF;

    MERGE INTO BEX_PURCHASE_DELIVERY d
    USING (SELECT q.pur_id pur_id FROM dual) s
    ON (d.PUR_ID=s.pur_id)
    WHEN MATCHED THEN UPDATE SET
      d.ADR_ID=a.adr_id,d.PDL_LABEL=a.adr_label,
      d.PDL_ZIP_CODE=a.adr_zip_code,d.PDL_STREET=a.adr_street,
      d.PDL_NUMBER=a.adr_number,d.PDL_COMPLEMENT=a.adr_complement,
      d.PDL_DISTRICT=a.adr_district,d.PDL_CITY=a.adr_city,
      d.PDL_STATE=a.adr_state,d.PDL_COUNTRY=a.adr_country,
      d.PDL_STATUS='ADDRESS_SELECTED',d.PDL_UPDATED_AT=SYSTIMESTAMP,
      d.PDL_UPDATED_BY=p_actor_id
    WHEN NOT MATCHED THEN INSERT(
      PDL_PUBLIC_ID,PUR_ID,ADR_ID,PDL_LABEL,PDL_ZIP_CODE,PDL_STREET,
      PDL_NUMBER,PDL_COMPLEMENT,PDL_DISTRICT,PDL_CITY,PDL_STATE,
      PDL_COUNTRY,PDL_CREATED_BY,PDL_UPDATED_BY
    ) VALUES(
      LOWER(RAWTOHEX(SYS_GUID())),q.pur_id,a.adr_id,a.adr_label,
      a.adr_zip_code,a.adr_street,a.adr_number,a.adr_complement,
      a.adr_district,a.adr_city,a.adr_state,a.adr_country,
      p_actor_id,p_actor_id
    );
    SELECT PDL_ID INTO id FROM BEX_PURCHASE_DELIVERY WHERE PUR_ID=q.pur_id;
    RETURN map_row(id);
  END;
END pdl_service_pkg;
/

CREATE OR REPLACE PACKAGE pdl_api_pkg AS
  PROCEDURE get_delivery(
    p_request_public_id VARCHAR2,p_actor_id NUMBER,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB
  );
  PROCEDURE select_address(
    p_request_public_id VARCHAR2,p_body CLOB,p_actor_id NUMBER,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB
  );
END pdl_api_pkg;
/

CREATE OR REPLACE PACKAGE BODY pdl_api_pkg AS
  e_bad EXCEPTION;
  FUNCTION js(p pdl_service_pkg.t_record) RETURN JSON_OBJECT_T IS
    j JSON_OBJECT_T:=JSON_OBJECT_T();
  BEGIN
    core_json_pkg.put_string(j,'deliveryPublicId',TRIM(p.delivery_public_id));
    core_json_pkg.put_string(j,'requestPublicId',TRIM(p.request_public_id));
    core_json_pkg.put_string(j,'addressPublicId',TRIM(p.address_public_id));
    IF p.label IS NULL THEN core_json_pkg.put_null(j,'label');
    ELSE core_json_pkg.put_string(j,'label',p.label);END IF;
    core_json_pkg.put_string(j,'zipCode',p.zip_code);
    core_json_pkg.put_string(j,'street',p.street);
    core_json_pkg.put_string(j,'number',p.number_value);
    IF p.complement IS NULL THEN core_json_pkg.put_null(j,'complement');
    ELSE core_json_pkg.put_string(j,'complement',p.complement);END IF;
    core_json_pkg.put_string(j,'district',p.district);
    core_json_pkg.put_string(j,'city',p.city);
    core_json_pkg.put_string(j,'state',p.state_code);
    core_json_pkg.put_string(j,'country',p.country_code);
    core_json_pkg.put_string(j,'status',p.status);
    RETURN j;
  END;
  PROCEDURE err(s NUMBER,c VARCHAR2,m VARCHAR2,os OUT PLS_INTEGER,ob OUT NOCOPY CLOB) IS
    e core_error_pkg.t_public_error;p core_error_pkg.t_error_policy;
  BEGIN
    core_error_pkg.build_known_error(c,
      CASE WHEN s=404 THEN core_error_pkg.c_category_not_found
        WHEN s=403 THEN core_error_pkg.c_category_authorization
        ELSE core_error_pkg.c_category_validation END,
      m,core_error_pkg.c_severity_warn,FALSE,FALSE,e,p);
    ob:=core_response_pkg.build_error(e);os:=s;
  END;
  PROCEDURE internal_error(os OUT PLS_INTEGER,ob OUT NOCOPY CLOB) IS
  BEGIN os:=500;ob:=core_response_pkg.build_technical_error;END;

  PROCEDURE get_delivery(
    p_request_public_id VARCHAR2,p_actor_id NUMBER,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB
  ) IS r pdl_service_pkg.t_record;
  BEGIN
    IF TRIM(p_request_public_id) IS NULL OR p_actor_id IS NULL THEN RAISE e_bad;END IF;
    r:=pdl_service_pkg.get_delivery(p_request_public_id,p_actor_id);
    o_body:=core_response_pkg.build_success(js(r));o_status:=200;
  EXCEPTION
    WHEN e_bad THEN err(400,'BEX-REQ-004','Valores obrigatorios.',o_status,o_body);
    WHEN pdl_service_pkg.e_not_found THEN err(404,'BEX-PDL-001','Entrega ainda nao informada.',o_status,o_body);
    WHEN pdl_service_pkg.e_forbidden THEN err(403,'BEX-PDL-003','Operacao nao autorizada.',o_status,o_body);
    WHEN OTHERS THEN internal_error(o_status,o_body);
  END;

  PROCEDURE select_address(
    p_request_public_id VARCHAR2,p_body CLOB,p_actor_id NUMBER,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB
  ) IS
    j JSON_OBJECT_T;r pdl_service_pkg.t_record;address_public_id VARCHAR2(32);
  BEGIN
    IF TRIM(p_request_public_id) IS NULL OR p_actor_id IS NULL THEN RAISE e_bad;END IF;
    j:=core_json_pkg.parse_object(p_body);
    core_json_pkg.assert_allowed_attributes(j,'addressPublicId');
    address_public_id:=core_json_pkg.required_string(j,'addressPublicId');
    r:=pdl_service_pkg.select_address(
      p_request_public_id,address_public_id,p_actor_id
    );
    o_body:=core_response_pkg.build_success(js(r));COMMIT;o_status:=200;
  EXCEPTION
    WHEN core_json_pkg.e_unknown_attribute OR core_json_pkg.e_invalid_json
      OR core_json_pkg.e_json_object_required OR core_json_pkg.e_required_attribute
      OR core_json_pkg.e_invalid_attribute_type OR e_bad
      THEN ROLLBACK;err(400,'BEX-REQ-002','Endereco invalido.',o_status,o_body);
    WHEN pdl_service_pkg.e_not_found THEN ROLLBACK;err(404,'BEX-PDL-001','Solicitacao ou endereco nao encontrado.',o_status,o_body);
    WHEN pdl_service_pkg.e_forbidden THEN ROLLBACK;err(403,'BEX-PDL-003','Operacao nao autorizada.',o_status,o_body);
    WHEN pdl_service_pkg.e_request_closed THEN ROLLBACK;err(422,'BEX-PDL-004','A solicitacao ainda nao esta aprovada.',o_status,o_body);
    WHEN OTHERS THEN ROLLBACK;internal_error(o_status,o_body);
  END;
END pdl_api_pkg;
/

PROMPT Purchase delivery packages installed.
