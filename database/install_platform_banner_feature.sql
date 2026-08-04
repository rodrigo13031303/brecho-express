SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

PROMPT Installing PLATFORM_BANNER...

DECLARE
  l_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO l_count FROM USER_TABLES
   WHERE TABLE_NAME='BEX_PLATFORM_BANNER';
  IF l_count=0 THEN
    EXECUTE IMMEDIATE q'~
      CREATE TABLE BEX_PLATFORM_BANNER(
        PLB_ID NUMBER(19) GENERATED ALWAYS AS IDENTITY,
        PLB_PUBLIC_ID CHAR(32 CHAR) NOT NULL,
        PLB_TITLE VARCHAR2(200 CHAR) NOT NULL,
        PLB_ALT_TEXT VARCHAR2(300 CHAR) NOT NULL,
        PLB_IMAGE_URL VARCHAR2(1000 CHAR),
        PLB_TARGET_TYPE VARCHAR2(30 CHAR) NOT NULL,
        PLB_TARGET_PUBLIC_ID CHAR(32 CHAR),
        PLB_TARGET_VALUE VARCHAR2(1000 CHAR),
        PLB_START_AT TIMESTAMP(6) NOT NULL,
        PLB_END_AT TIMESTAMP(6) NOT NULL,
        PLB_DISPLAY_ORDER NUMBER(5) DEFAULT 0 NOT NULL,
        PLB_STATUS VARCHAR2(20 CHAR) DEFAULT 'DRAFT' NOT NULL,
        PLB_CREATED_AT TIMESTAMP(6) DEFAULT SYSTIMESTAMP NOT NULL,
        PLB_UPDATED_AT TIMESTAMP(6) DEFAULT SYSTIMESTAMP NOT NULL,
        PLB_CREATED_BY NUMBER(19) NOT NULL,
        PLB_UPDATED_BY NUMBER(19) NOT NULL,
        CONSTRAINT PK_PLATFORM_BANNER PRIMARY KEY(PLB_ID),
        CONSTRAINT UK_PLB_PUBLIC_ID UNIQUE(PLB_PUBLIC_ID),
        CONSTRAINT FK_PLB_CREATED_BY FOREIGN KEY(PLB_CREATED_BY) REFERENCES BEX_ACCOUNT(ACC_ID),
        CONSTRAINT FK_PLB_UPDATED_BY FOREIGN KEY(PLB_UPDATED_BY) REFERENCES BEX_ACCOUNT(ACC_ID),
        CONSTRAINT CK_PLB_STATUS CHECK(PLB_STATUS IN('DRAFT','ACTIVE','INACTIVE','ARCHIVED')),
        CONSTRAINT CK_PLB_TARGET CHECK(PLB_TARGET_TYPE IN('PRODUCT','STORE','CATEGORY','STORE_EVENT','APP_SCREEN','EXTERNAL_URL')),
        CONSTRAINT CK_PLB_PERIOD CHECK(PLB_END_AT>PLB_START_AT),
        CONSTRAINT CK_PLB_ORDER CHECK(PLB_DISPLAY_ORDER BETWEEN 0 AND 99999)
      )
    ~';
    EXECUTE IMMEDIATE 'CREATE INDEX IDX_PLB_PUBLIC ON BEX_PLATFORM_BANNER(PLB_STATUS,PLB_START_AT,PLB_END_AT,PLB_DISPLAY_ORDER)';
  END IF;

  SELECT COUNT(*) INTO l_count FROM USER_TABLES
   WHERE TABLE_NAME='BEX_PLATFORM_BANNER_MEDIA';
  IF l_count=0 THEN
    EXECUTE IMMEDIATE q'~
      CREATE TABLE BEX_PLATFORM_BANNER_MEDIA(
        PLB_ID NUMBER(19) NOT NULL,
        PBM_MIME_TYPE VARCHAR2(100 CHAR) NOT NULL,
        PBM_CONTENT BLOB NOT NULL,
        PBM_UPDATED_AT TIMESTAMP(6) DEFAULT SYSTIMESTAMP NOT NULL,
        PBM_UPDATED_BY NUMBER(19) NOT NULL,
        CONSTRAINT PK_PLATFORM_BANNER_MEDIA PRIMARY KEY(PLB_ID),
        CONSTRAINT FK_PBM_BANNER FOREIGN KEY(PLB_ID) REFERENCES BEX_PLATFORM_BANNER(PLB_ID) ON DELETE CASCADE,
        CONSTRAINT FK_PBM_UPDATED_BY FOREIGN KEY(PBM_UPDATED_BY) REFERENCES BEX_ACCOUNT(ACC_ID),
        CONSTRAINT CK_PBM_MIME CHECK(PBM_MIME_TYPE IN('image/jpeg','image/png','image/webp'))
      )
    ~';
  END IF;
END;
/

CREATE OR REPLACE PACKAGE plb_repository_pkg AS
  TYPE t_row IS RECORD(
    id NUMBER,public_id CHAR(32),title VARCHAR2(200),alt_text VARCHAR2(300),
    image_url VARCHAR2(1000),target_type VARCHAR2(30),target_public_id CHAR(32),
    target_value VARCHAR2(1000),start_at TIMESTAMP,end_at TIMESTAMP,
    display_order NUMBER,status VARCHAR2(20),created_at TIMESTAMP,updated_at TIMESTAMP
  );
  TYPE t_rows IS TABLE OF t_row INDEX BY PLS_INTEGER;
  FUNCTION map_id(p_id NUMBER)RETURN t_row;
  FUNCTION by_public(p_public VARCHAR2)RETURN t_row;
  FUNCTION list_public RETURN t_rows;
  FUNCTION list_all RETURN t_rows;
  PROCEDURE insert_row(p t_row,p_actor NUMBER,o_id OUT NUMBER);
  PROCEDURE update_row(p t_row,p_actor NUMBER);
  PROCEDURE save_media(p_id NUMBER,p_mime VARCHAR2,p_content BLOB,p_actor NUMBER);
END plb_repository_pkg;
/
CREATE OR REPLACE PACKAGE BODY plb_repository_pkg AS
  FUNCTION map_id(p_id NUMBER)RETURN t_row IS r t_row;BEGIN
    SELECT PLB_ID,PLB_PUBLIC_ID,PLB_TITLE,PLB_ALT_TEXT,PLB_IMAGE_URL,
      PLB_TARGET_TYPE,PLB_TARGET_PUBLIC_ID,PLB_TARGET_VALUE,PLB_START_AT,
      PLB_END_AT,PLB_DISPLAY_ORDER,PLB_STATUS,PLB_CREATED_AT,PLB_UPDATED_AT
    INTO r FROM BEX_PLATFORM_BANNER WHERE PLB_ID=p_id;RETURN r;END;
  FUNCTION by_public(p_public VARCHAR2)RETURN t_row IS id NUMBER;BEGIN
    SELECT PLB_ID INTO id FROM BEX_PLATFORM_BANNER
     WHERE PLB_PUBLIC_ID=LOWER(TRIM(p_public));RETURN map_id(id);END;
  FUNCTION list_public RETURN t_rows IS r t_rows;n PLS_INTEGER:=0;BEGIN
    FOR x IN(SELECT PLB_ID FROM BEX_PLATFORM_BANNER
      WHERE PLB_STATUS='ACTIVE' AND PLB_IMAGE_URL IS NOT NULL
        AND PLB_START_AT<=SYS_EXTRACT_UTC(SYSTIMESTAMP)
        AND PLB_END_AT>SYS_EXTRACT_UTC(SYSTIMESTAMP)
      ORDER BY PLB_DISPLAY_ORDER,PLB_START_AT,PLB_ID)LOOP
      n:=n+1;r(n):=map_id(x.PLB_ID);END LOOP;RETURN r;END;
  FUNCTION list_all RETURN t_rows IS r t_rows;n PLS_INTEGER:=0;BEGIN
    FOR x IN(SELECT PLB_ID FROM BEX_PLATFORM_BANNER
      ORDER BY PLB_UPDATED_AT DESC,PLB_ID DESC)LOOP
      n:=n+1;r(n):=map_id(x.PLB_ID);END LOOP;RETURN r;END;
  PROCEDURE insert_row(p t_row,p_actor NUMBER,o_id OUT NUMBER)IS BEGIN
    INSERT INTO BEX_PLATFORM_BANNER(
      PLB_PUBLIC_ID,PLB_TITLE,PLB_ALT_TEXT,PLB_TARGET_TYPE,
      PLB_TARGET_PUBLIC_ID,PLB_TARGET_VALUE,PLB_START_AT,PLB_END_AT,
      PLB_DISPLAY_ORDER,PLB_STATUS,PLB_CREATED_BY,PLB_UPDATED_BY
    )VALUES(LOWER(RAWTOHEX(SYS_GUID())),p.title,p.alt_text,p.target_type,
      p.target_public_id,p.target_value,p.start_at,p.end_at,p.display_order,
      'DRAFT',p_actor,p_actor)RETURNING PLB_ID INTO o_id;END;
  PROCEDURE update_row(p t_row,p_actor NUMBER)IS BEGIN
    UPDATE BEX_PLATFORM_BANNER SET PLB_TITLE=p.title,PLB_ALT_TEXT=p.alt_text,
      PLB_TARGET_TYPE=p.target_type,PLB_TARGET_PUBLIC_ID=p.target_public_id,
      PLB_TARGET_VALUE=p.target_value,PLB_START_AT=p.start_at,
      PLB_END_AT=p.end_at,PLB_DISPLAY_ORDER=p.display_order,
      PLB_STATUS=p.status,PLB_UPDATED_AT=SYSTIMESTAMP,PLB_UPDATED_BY=p_actor
    WHERE PLB_ID=p.id;END;
  PROCEDURE save_media(p_id NUMBER,p_mime VARCHAR2,p_content BLOB,p_actor NUMBER)IS
    url VARCHAR2(1000);pub CHAR(32);
  BEGIN
    UPDATE BEX_PLATFORM_BANNER_MEDIA SET PBM_MIME_TYPE=p_mime,
      PBM_CONTENT=p_content,PBM_UPDATED_AT=SYSTIMESTAMP,PBM_UPDATED_BY=p_actor
    WHERE PLB_ID=p_id;
    IF SQL%ROWCOUNT=0 THEN INSERT INTO BEX_PLATFORM_BANNER_MEDIA(
      PLB_ID,PBM_MIME_TYPE,PBM_CONTENT,PBM_UPDATED_BY
    )VALUES(p_id,p_mime,p_content,p_actor);END IF;
    SELECT TRIM(PLB_PUBLIC_ID)INTO pub FROM BEX_PLATFORM_BANNER WHERE PLB_ID=p_id;
    url:='https://app.rodrigosburguer.com.br/ords/brechoexpress/api/v1/platform-banners/'||pub||'/image';
    UPDATE BEX_PLATFORM_BANNER SET PLB_IMAGE_URL=url,
      PLB_UPDATED_AT=SYSTIMESTAMP,PLB_UPDATED_BY=p_actor WHERE PLB_ID=p_id;
  END;
END plb_repository_pkg;
/

CREATE OR REPLACE PACKAGE plb_rule_pkg AS
  e_invalid EXCEPTION;e_transition EXCEPTION;
  PROCEDURE validate(p plb_repository_pkg.t_row,p_current VARCHAR2 DEFAULT NULL);
END plb_rule_pkg;
/
CREATE OR REPLACE PACKAGE BODY plb_rule_pkg AS
  PROCEDURE validate(p plb_repository_pkg.t_row,p_current VARCHAR2 DEFAULT NULL)IS
    resource_target BOOLEAN:=p.target_type IN('PRODUCT','STORE','CATEGORY','STORE_EVENT');
  BEGIN
    IF TRIM(p.title)IS NULL OR LENGTH(TRIM(p.title))>200
      OR TRIM(p.alt_text)IS NULL OR LENGTH(TRIM(p.alt_text))>300
      OR p.start_at IS NULL OR p.end_at IS NULL OR p.end_at<=p.start_at
      OR p.display_order NOT BETWEEN 0 AND 99999
      OR p.target_type NOT IN('PRODUCT','STORE','CATEGORY','STORE_EVENT','APP_SCREEN','EXTERNAL_URL')
      OR(resource_target AND TRIM(p.target_public_id)IS NULL)
      OR(NOT resource_target AND TRIM(p.target_value)IS NULL)
      OR(p.target_type='EXTERNAL_URL' AND LOWER(TRIM(p.target_value))NOT LIKE 'https://%')
    THEN RAISE e_invalid;END IF;
    IF p.status NOT IN('DRAFT','ACTIVE','INACTIVE','ARCHIVED')THEN RAISE e_invalid;END IF;
    IF p.status='ACTIVE' AND TRIM(p.image_url)IS NULL THEN RAISE e_invalid;END IF;
    IF p_current='ARCHIVED' AND p.status<>'ARCHIVED'THEN RAISE e_transition;END IF;
  END;
END plb_rule_pkg;
/

CREATE OR REPLACE PACKAGE plb_service_pkg AS
  e_not_found EXCEPTION;e_invalid EXCEPTION;e_transition EXCEPTION;
  FUNCTION list_public RETURN plb_repository_pkg.t_rows;
  FUNCTION list_admin(p_actor NUMBER)RETURN plb_repository_pkg.t_rows;
  FUNCTION create_banner(p plb_repository_pkg.t_row,p_actor NUMBER)RETURN plb_repository_pkg.t_row;
  FUNCTION update_banner(p_public VARCHAR2,p plb_repository_pkg.t_row,p_actor NUMBER)RETURN plb_repository_pkg.t_row;
  FUNCTION upload_image(p_public VARCHAR2,p_mime VARCHAR2,p_content BLOB,p_actor NUMBER)RETURN plb_repository_pkg.t_row;
END plb_service_pkg;
/
CREATE OR REPLACE PACKAGE BODY plb_service_pkg AS
  PROCEDURE admin(p_actor NUMBER)IS BEGIN iam_authorization_pkg.require_role(p_actor,'ADMIN');
    EXCEPTION WHEN iam_authorization_pkg.e_forbidden THEN RAISE;END;
  FUNCTION find(p_public VARCHAR2)RETURN plb_repository_pkg.t_row IS r plb_repository_pkg.t_row;BEGIN
    BEGIN r:=plb_repository_pkg.by_public(p_public);EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_found;END;RETURN r;END;
  FUNCTION list_public RETURN plb_repository_pkg.t_rows IS BEGIN RETURN plb_repository_pkg.list_public;END;
  FUNCTION list_admin(p_actor NUMBER)RETURN plb_repository_pkg.t_rows IS BEGIN admin(p_actor);RETURN plb_repository_pkg.list_all;END;
  FUNCTION create_banner(p plb_repository_pkg.t_row,p_actor NUMBER)RETURN plb_repository_pkg.t_row IS x plb_repository_pkg.t_row;id NUMBER;
  BEGIN admin(p_actor);x:=p;x.status:='DRAFT';BEGIN plb_rule_pkg.validate(x);EXCEPTION WHEN plb_rule_pkg.e_invalid THEN RAISE e_invalid;END;
    plb_repository_pkg.insert_row(x,p_actor,id);RETURN plb_repository_pkg.map_id(id);END;
  FUNCTION update_banner(p_public VARCHAR2,p plb_repository_pkg.t_row,p_actor NUMBER)RETURN plb_repository_pkg.t_row IS x plb_repository_pkg.t_row;c plb_repository_pkg.t_row;
  BEGIN admin(p_actor);c:=find(p_public);x:=p;x.id:=c.id;x.image_url:=c.image_url;
    BEGIN plb_rule_pkg.validate(x,c.status);EXCEPTION WHEN plb_rule_pkg.e_invalid THEN RAISE e_invalid;WHEN plb_rule_pkg.e_transition THEN RAISE e_transition;END;
    plb_repository_pkg.update_row(x,p_actor);RETURN plb_repository_pkg.by_public(p_public);END;
  FUNCTION upload_image(p_public VARCHAR2,p_mime VARCHAR2,p_content BLOB,p_actor NUMBER)RETURN plb_repository_pkg.t_row IS x plb_repository_pkg.t_row;
  BEGIN admin(p_actor);x:=find(p_public);
    IF LOWER(TRIM(p_mime))NOT IN('image/jpeg','image/png','image/webp')
      OR p_content IS NULL OR DBMS_LOB.GETLENGTH(p_content)=0
      OR DBMS_LOB.GETLENGTH(p_content)>1048576 THEN RAISE e_invalid;END IF;
    plb_repository_pkg.save_media(x.id,LOWER(TRIM(p_mime)),p_content,p_actor);
    RETURN plb_repository_pkg.by_public(p_public);END;
END plb_service_pkg;
/

CREATE OR REPLACE PACKAGE plb_api_pkg AS
  PROCEDURE list_public(o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE list_admin(p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE create_banner(p_body CLOB,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE update_banner(p_public VARCHAR2,p_body CLOB,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE upload_image(p_public VARCHAR2,p_mime VARCHAR2,p_content BLOB,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE my_roles(p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
END plb_api_pkg;
/
CREATE OR REPLACE PACKAGE BODY plb_api_pkg AS
  FUNCTION js(p plb_repository_pkg.t_row)RETURN JSON_OBJECT_T IS j JSON_OBJECT_T:=JSON_OBJECT_T();BEGIN
    core_json_pkg.put_string(j,'bannerPublicId',TRIM(p.public_id));
    core_json_pkg.put_string(j,'title',p.title);core_json_pkg.put_string(j,'altText',p.alt_text);
    IF p.image_url IS NULL THEN core_json_pkg.put_null(j,'imageUrl');ELSE core_json_pkg.put_string(j,'imageUrl',p.image_url);END IF;
    core_json_pkg.put_string(j,'targetType',p.target_type);
    IF p.target_public_id IS NULL THEN core_json_pkg.put_null(j,'targetPublicId');ELSE core_json_pkg.put_string(j,'targetPublicId',TRIM(p.target_public_id));END IF;
    IF p.target_value IS NULL THEN core_json_pkg.put_null(j,'targetValue');ELSE core_json_pkg.put_string(j,'targetValue',p.target_value);END IF;
    core_json_pkg.put_string(j,'startAt',core_json_pkg.format_timestamp(p.start_at)||'Z');
    core_json_pkg.put_string(j,'endAt',core_json_pkg.format_timestamp(p.end_at)||'Z');
    core_json_pkg.put_number(j,'displayOrder',p.display_order);core_json_pkg.put_string(j,'status',p.status);RETURN j;END;
  FUNCTION arr(p plb_repository_pkg.t_rows)RETURN JSON_ARRAY_T IS a JSON_ARRAY_T:=JSON_ARRAY_T();i PLS_INTEGER:=p.FIRST;BEGIN
    WHILE i IS NOT NULL LOOP core_json_pkg.append_element(a,js(p(i)));i:=p.NEXT(i);END LOOP;RETURN a;END;
  FUNCTION parse(p_body CLOB)RETURN plb_repository_pkg.t_row IS j JSON_OBJECT_T;r plb_repository_pkg.t_row;BEGIN
    j:=core_json_pkg.parse_object(p_body);
    core_json_pkg.assert_allowed_attributes(j,'title,altText,targetType,targetPublicId,targetValue,startAt,endAt,displayOrder,status');
    r.title:=core_json_pkg.required_string(j,'title');r.alt_text:=core_json_pkg.required_string(j,'altText');
    r.target_type:=UPPER(core_json_pkg.required_string(j,'targetType'));
    r.target_public_id:=core_json_pkg.optional_string(j,'targetPublicId');r.target_value:=core_json_pkg.optional_string(j,'targetValue');
    r.start_at:=core_json_pkg.required_timestamp(j,'startAt','YYYY-MM-DD"T"HH24:MI:SS.FF"Z"');
    r.end_at:=core_json_pkg.required_timestamp(j,'endAt','YYYY-MM-DD"T"HH24:MI:SS.FF"Z"');
    r.display_order:=core_json_pkg.required_number(j,'displayOrder');
    IF j.has('status')THEN r.status:=UPPER(core_json_pkg.required_string(j,'status'));ELSE r.status:='DRAFT';END IF;RETURN r;END;
  PROCEDURE err(s NUMBER,c VARCHAR2,m VARCHAR2,os OUT PLS_INTEGER,ob OUT NOCOPY CLOB)IS e core_error_pkg.t_public_error;p core_error_pkg.t_error_policy;BEGIN
    core_error_pkg.build_known_error(c,CASE WHEN s=403 THEN core_error_pkg.c_category_authorization WHEN s=404 THEN core_error_pkg.c_category_not_found WHEN s=409 THEN core_error_pkg.c_category_conflict ELSE core_error_pkg.c_category_validation END,m,core_error_pkg.c_severity_warn,FALSE,FALSE,e,p);
    ob:=core_response_pkg.build_error(e);os:=s;EXCEPTION WHEN OTHERS THEN os:=500;ob:=NULL;END;
  PROCEDURE list_public(o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB)IS BEGIN o_body:=core_response_pkg.build_success(arr(plb_service_pkg.list_public));o_status:=200;
    EXCEPTION WHEN OTHERS THEN err(500,'BEX-SYS-001','Nao foi possivel carregar os banners.',o_status,o_body);END;
  PROCEDURE list_admin(p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB)IS BEGIN o_body:=core_response_pkg.build_success(arr(plb_service_pkg.list_admin(p_actor)));o_status:=200;
    EXCEPTION WHEN iam_authorization_pkg.e_forbidden THEN err(403,'BEX-AUTH-006','A conta nao possui acesso administrativo.',o_status,o_body);WHEN OTHERS THEN err(500,'BEX-SYS-001','Nao foi possivel carregar os banners.',o_status,o_body);END;
  PROCEDURE create_banner(p_body CLOB,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB)IS r plb_repository_pkg.t_row;BEGIN r:=plb_service_pkg.create_banner(parse(p_body),p_actor);o_body:=core_response_pkg.build_success(js(r));COMMIT;o_status:=201;
    EXCEPTION WHEN core_json_pkg.e_request_body_required OR core_json_pkg.e_invalid_json OR core_json_pkg.e_required_attribute OR core_json_pkg.e_invalid_attribute_type OR core_json_pkg.e_unknown_attribute OR core_json_pkg.e_invalid_temporal_value THEN ROLLBACK;err(400,'BEX-REQ-026','Dados do banner invalidos.',o_status,o_body);
    WHEN iam_authorization_pkg.e_forbidden THEN ROLLBACK;err(403,'BEX-AUTH-006','A conta nao possui acesso administrativo.',o_status,o_body);
    WHEN plb_service_pkg.e_invalid THEN ROLLBACK;err(422,'BEX-PLB-001','Confira os dados e a vigencia do banner.',o_status,o_body);WHEN OTHERS THEN ROLLBACK;err(500,'BEX-SYS-001','Nao foi possivel criar o banner.',o_status,o_body);END;
  PROCEDURE update_banner(p_public VARCHAR2,p_body CLOB,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB)IS r plb_repository_pkg.t_row;BEGIN r:=plb_service_pkg.update_banner(p_public,parse(p_body),p_actor);o_body:=core_response_pkg.build_success(js(r));COMMIT;o_status:=200;
    EXCEPTION WHEN core_json_pkg.e_request_body_required OR core_json_pkg.e_invalid_json OR core_json_pkg.e_required_attribute OR core_json_pkg.e_invalid_attribute_type OR core_json_pkg.e_unknown_attribute OR core_json_pkg.e_invalid_temporal_value THEN ROLLBACK;err(400,'BEX-REQ-026','Dados do banner invalidos.',o_status,o_body);
    WHEN iam_authorization_pkg.e_forbidden THEN ROLLBACK;err(403,'BEX-AUTH-006','A conta nao possui acesso administrativo.',o_status,o_body);
    WHEN plb_service_pkg.e_not_found THEN ROLLBACK;err(404,'BEX-PLB-002','Banner nao encontrado.',o_status,o_body);
    WHEN plb_service_pkg.e_invalid THEN ROLLBACK;err(422,'BEX-PLB-001','Confira os dados e a imagem do banner.',o_status,o_body);
    WHEN plb_service_pkg.e_transition THEN ROLLBACK;err(409,'BEX-PLB-003','O banner arquivado nao pode ser reativado.',o_status,o_body);
    WHEN OTHERS THEN ROLLBACK;err(500,'BEX-SYS-001','Nao foi possivel atualizar o banner.',o_status,o_body);END;
  PROCEDURE upload_image(p_public VARCHAR2,p_mime VARCHAR2,p_content BLOB,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB)IS r plb_repository_pkg.t_row;BEGIN r:=plb_service_pkg.upload_image(p_public,p_mime,p_content,p_actor);o_body:=core_response_pkg.build_success(js(r));COMMIT;o_status:=200;
    EXCEPTION WHEN iam_authorization_pkg.e_forbidden THEN ROLLBACK;err(403,'BEX-AUTH-006','A conta nao possui acesso administrativo.',o_status,o_body);
    WHEN plb_service_pkg.e_not_found THEN ROLLBACK;err(404,'BEX-PLB-002','Banner nao encontrado.',o_status,o_body);
    WHEN plb_service_pkg.e_invalid THEN ROLLBACK;err(422,'BEX-PLB-004','Envie JPG, PNG ou WebP de ate 1 MB.',o_status,o_body);
    WHEN OTHERS THEN ROLLBACK;err(500,'BEX-SYS-001','Nao foi possivel enviar a imagem.',o_status,o_body);END;
  PROCEDURE my_roles(p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB)IS a JSON_ARRAY_T:=JSON_ARRAY_T();BEGIN
    FOR x IN(SELECT r.ROL_CODE FROM BEX_PROFILE p JOIN BEX_PROFILE_ROLE pr ON pr.PFL_ID=p.PFL_ID JOIN BEX_ROLE r ON r.ROL_ID=pr.ROL_ID
      WHERE p.ACC_ID=p_actor AND pr.PRL_STATUS='ACTIVE'AND r.ROL_STATUS='ACTIVE'AND(pr.PRL_EXPIRES_AT IS NULL OR pr.PRL_EXPIRES_AT>SYSTIMESTAMP)ORDER BY r.ROL_CODE)
    LOOP core_json_pkg.append_string(a,x.ROL_CODE);END LOOP;o_body:=core_response_pkg.build_success(a);o_status:=200;
    EXCEPTION WHEN OTHERS THEN err(500,'BEX-SYS-001','Nao foi possivel consultar as permissoes.',o_status,o_body);END;
END plb_api_pkg;
/

BEGIN
  ORDS.DEFINE_TEMPLATE(p_module_name=>'brecho-express-v1',p_pattern=>'platform-banners',p_etag_type=>'NONE');
  ORDS.DEFINE_HANDLER('brecho-express-v1','platform-banners','GET',ORDS.SOURCE_TYPE_PLSQL,q'~
DECLARE s PLS_INTEGER;b CLOB;BEGIN ord_runtime_pkg.begin_anonymous_request;plb_api_pkg.list_public(s,b);:status_code:=s;ord_runtime_pkg.write_json_response(b);ord_runtime_pkg.clear_request_context;EXCEPTION WHEN OTHERS THEN ord_runtime_pkg.clear_request_context;RAISE;END;~');
  ORDS.DEFINE_TEMPLATE(p_module_name=>'brecho-express-v1',p_pattern=>'platform-banners/:bannerPublicId/image',p_etag_type=>'NONE');
  ORDS.DEFINE_HANDLER('brecho-express-v1','platform-banners/:bannerPublicId/image','GET',ORDS.SOURCE_TYPE_MEDIA,q'~
SELECT m.PBM_MIME_TYPE,m.PBM_CONTENT FROM BEX_PLATFORM_BANNER_MEDIA m JOIN BEX_PLATFORM_BANNER b ON b.PLB_ID=m.PLB_ID WHERE b.PLB_PUBLIC_ID=LOWER(TRIM(:bannerPublicId))~');
  ORDS.DEFINE_TEMPLATE(p_module_name=>'brecho-express-v1',p_pattern=>'admin/platform-banners',p_etag_type=>'NONE');
  ORDS.DEFINE_HANDLER('brecho-express-v1','admin/platform-banners','GET',ORDS.SOURCE_TYPE_PLSQL,q'~
DECLARE a BOOLEAN;i NUMBER;p VARCHAR2(32);s PLS_INTEGER;b CLOB;BEGIN ord_runtime_pkg.begin_authenticated_request(:authorization,a,i,p,s,b);IF a THEN plb_api_pkg.list_admin(i,s,b);END IF;:status_code:=s;ord_runtime_pkg.write_json_response(b);ord_runtime_pkg.clear_request_context;EXCEPTION WHEN OTHERS THEN ord_runtime_pkg.clear_request_context;RAISE;END;~');
  ORDS.DEFINE_HANDLER('brecho-express-v1','admin/platform-banners','POST',ORDS.SOURCE_TYPE_PLSQL,q'~
DECLARE a BOOLEAN;i NUMBER;p VARCHAR2(32);s PLS_INTEGER;b CLOB;request_body CLOB:=:body_text;BEGIN ord_runtime_pkg.begin_authenticated_request(:authorization,a,i,p,s,b);IF a THEN plb_api_pkg.create_banner(request_body,i,s,b);END IF;:status_code:=s;ord_runtime_pkg.write_json_response(b);ord_runtime_pkg.clear_request_context;EXCEPTION WHEN OTHERS THEN ROLLBACK;api_error_log_pkg.capture(core_context_pkg.trace_id(),'PLATFORM_BANNER','CREATE',i,SQLCODE,SQLERRM,DBMS_UTILITY.format_error_backtrace);ord_runtime_pkg.clear_request_context;RAISE;END;~');
  ORDS.DEFINE_TEMPLATE(p_module_name=>'brecho-express-v1',p_pattern=>'admin/platform-banners/:bannerPublicId',p_etag_type=>'NONE');
  ORDS.DEFINE_HANDLER('brecho-express-v1','admin/platform-banners/:bannerPublicId','PUT',ORDS.SOURCE_TYPE_PLSQL,q'~
DECLARE a BOOLEAN;i NUMBER;p VARCHAR2(32);s PLS_INTEGER;b CLOB;request_body CLOB:=:body_text;BEGIN ord_runtime_pkg.begin_authenticated_request(:authorization,a,i,p,s,b);IF a THEN plb_api_pkg.update_banner(:bannerPublicId,request_body,i,s,b);END IF;:status_code:=s;ord_runtime_pkg.write_json_response(b);ord_runtime_pkg.clear_request_context;EXCEPTION WHEN OTHERS THEN ROLLBACK;api_error_log_pkg.capture(core_context_pkg.trace_id(),'PLATFORM_BANNER','UPDATE',i,SQLCODE,SQLERRM,DBMS_UTILITY.format_error_backtrace);ord_runtime_pkg.clear_request_context;RAISE;END;~');
  ORDS.DEFINE_TEMPLATE(p_module_name=>'brecho-express-v1',p_pattern=>'admin/platform-banners/:bannerPublicId/image',p_etag_type=>'NONE');
  ORDS.DEFINE_HANDLER('brecho-express-v1','admin/platform-banners/:bannerPublicId/image','POST',ORDS.SOURCE_TYPE_PLSQL,q'~
DECLARE a BOOLEAN;i NUMBER;p VARCHAR2(32);s PLS_INTEGER;b CLOB;content BLOB:=:body;BEGIN ord_runtime_pkg.begin_authenticated_request(:authorization,a,i,p,s,b);IF a THEN plb_api_pkg.upload_image(:bannerPublicId,:content_type,content,i,s,b);END IF;:status_code:=s;ord_runtime_pkg.write_json_response(b);ord_runtime_pkg.clear_request_context;EXCEPTION WHEN OTHERS THEN ROLLBACK;ord_runtime_pkg.clear_request_context;RAISE;END;~');
  ORDS.DEFINE_TEMPLATE(p_module_name=>'brecho-express-v1',p_pattern=>'me/roles',p_etag_type=>'NONE');
  ORDS.DEFINE_HANDLER('brecho-express-v1','me/roles','GET',ORDS.SOURCE_TYPE_PLSQL,q'~
DECLARE a BOOLEAN;i NUMBER;p VARCHAR2(32);s PLS_INTEGER;b CLOB;BEGIN ord_runtime_pkg.begin_authenticated_request(:authorization,a,i,p,s,b);IF a THEN plb_api_pkg.my_roles(i,s,b);END IF;:status_code:=s;ord_runtime_pkg.write_json_response(b);ord_runtime_pkg.clear_request_context;EXCEPTION WHEN OTHERS THEN ord_runtime_pkg.clear_request_context;RAISE;END;~');
  FOR route_data IN(
    SELECT 'admin/platform-banners' pattern_value,'GET' method_value FROM DUAL
    UNION ALL SELECT 'admin/platform-banners','POST' FROM DUAL
    UNION ALL SELECT 'admin/platform-banners/:bannerPublicId','PUT' FROM DUAL
    UNION ALL SELECT 'admin/platform-banners/:bannerPublicId/image','POST' FROM DUAL
    UNION ALL SELECT 'me/roles','GET' FROM DUAL
  )LOOP
    ORDS.DEFINE_PARAMETER(
      p_module_name=>'brecho-express-v1',p_pattern=>route_data.pattern_value,
      p_method=>route_data.method_value,p_name=>'Authorization',
      p_bind_variable_name=>'authorization',p_source_type=>'HEADER',
      p_param_type=>'STRING',p_access_method=>'IN'
    );
  END LOOP;
  ORDS.DEFINE_PARAMETER(
    p_module_name=>'brecho-express-v1',
    p_pattern=>'admin/platform-banners/:bannerPublicId/image',p_method=>'POST',
    p_name=>'Content-Type',p_bind_variable_name=>'content_type',
    p_source_type=>'HEADER',p_param_type=>'STRING',p_access_method=>'IN'
  );
  COMMIT;
END;
/

SHOW ERRORS PACKAGE PLB_REPOSITORY_PKG
SHOW ERRORS PACKAGE BODY PLB_REPOSITORY_PKG
SHOW ERRORS PACKAGE PLB_RULE_PKG
SHOW ERRORS PACKAGE BODY PLB_RULE_PKG
SHOW ERRORS PACKAGE PLB_SERVICE_PKG
SHOW ERRORS PACKAGE BODY PLB_SERVICE_PKG
SHOW ERRORS PACKAGE PLB_API_PKG
SHOW ERRORS PACKAGE BODY PLB_API_PKG

DECLARE
  l_valid NUMBER;
BEGIN
  SELECT COUNT(*) INTO l_valid FROM USER_OBJECTS
   WHERE OBJECT_NAME IN(
     'PLB_REPOSITORY_PKG','PLB_RULE_PKG','PLB_SERVICE_PKG','PLB_API_PKG'
   ) AND OBJECT_TYPE IN('PACKAGE','PACKAGE BODY') AND STATUS='VALID';
  IF l_valid<>8 THEN
    RAISE_APPLICATION_ERROR(-20026,'Packages de PLATFORM_BANNER invalidos.');
  END IF;
  DBMS_OUTPUT.PUT_LINE('SUCCESS - 8 package objects VALID.');
END;
/

PROMPT PLATFORM_BANNER installed successfully.
