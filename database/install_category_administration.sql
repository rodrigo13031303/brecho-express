SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

PROMPT Installing hierarchical category administration...

@tables/catalog/upgrade_category_hierarchy.sql
@packages/catalog/install_cat_repository_pkg.sql
@packages/catalog/install_cat_service_pkg.sql
@packages/catalog/install_cat_api_pkg.sql

CREATE OR REPLACE PACKAGE cat_admin_api_pkg AS
  PROCEDURE list_categories(p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE create_category(p_body CLOB,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE update_category(p_public VARCHAR2,p_body CLOB,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE change_status(p_public VARCHAR2,p_status VARCHAR2,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE delete_category(p_public VARCHAR2,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
END cat_admin_api_pkg;
/

CREATE OR REPLACE PACKAGE BODY cat_admin_api_pkg AS
  e_not_found EXCEPTION;e_invalid EXCEPTION;e_conflict EXCEPTION;e_cycle EXCEPTION;

  PROCEDURE require_admin(p_actor NUMBER)IS BEGIN
    iam_authorization_pkg.require_role(p_actor,'ADMIN');
  END;

  FUNCTION id_for(p_public VARCHAR2)RETURN NUMBER IS l_id NUMBER;BEGIN
    SELECT CAT_ID INTO l_id FROM BEX_CATEGORY WHERE CAT_PUBLIC_ID=LOWER(TRIM(p_public));
    RETURN l_id;
  EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_found;END;

  FUNCTION public_for(p_id NUMBER)RETURN VARCHAR2 IS l_public VARCHAR2(32);BEGIN
    IF p_id IS NULL THEN RETURN NULL;END IF;
    SELECT TRIM(CAT_PUBLIC_ID) INTO l_public FROM BEX_CATEGORY WHERE CAT_ID=p_id;
    RETURN l_public;
  END;

  FUNCTION row_json(p_id NUMBER)RETURN JSON_OBJECT_T IS
    j JSON_OBJECT_T:=JSON_OBJECT_T();r BEX_CATEGORY%ROWTYPE;products NUMBER;children NUMBER;
  BEGIN
    SELECT * INTO r FROM BEX_CATEGORY WHERE CAT_ID=p_id;
    SELECT COUNT(*) INTO products FROM BEX_PRODUCT WHERE CAT_ID=p_id;
    SELECT COUNT(*) INTO children FROM BEX_CATEGORY WHERE CAT_PARENT_ID=p_id;
    core_json_pkg.put_string(j,'categoryPublicId',TRIM(r.CAT_PUBLIC_ID));
    core_json_pkg.put_string(j,'categoryName',r.CAT_NAME);
    core_json_pkg.put_string(j,'categorySlug',r.CAT_SLUG);
    IF r.CAT_DESCRIPTION IS NULL THEN core_json_pkg.put_null(j,'description');ELSE core_json_pkg.put_string(j,'description',r.CAT_DESCRIPTION);END IF;
    IF r.CAT_PARENT_ID IS NULL THEN core_json_pkg.put_null(j,'parentCategoryPublicId');ELSE core_json_pkg.put_string(j,'parentCategoryPublicId',public_for(r.CAT_PARENT_ID));END IF;
    core_json_pkg.put_number(j,'sortOrder',r.CAT_SORT_ORDER);
    core_json_pkg.put_boolean(j,'acceptsProducts',r.CAT_ACCEPTS_PRODUCTS=1);
    core_json_pkg.put_string(j,'status',r.CAT_STATUS);
    core_json_pkg.put_number(j,'productCount',products);
    core_json_pkg.put_number(j,'childCount',children);
    core_json_pkg.put_boolean(j,'canDelete',products=0 AND children=0);
    core_json_pkg.put_boolean(j,'canInactivate',products=0 AND children=0);
    RETURN j;
  END;

  FUNCTION parse_parent(p_json JSON_OBJECT_T)RETURN NUMBER IS l_public VARCHAR2(32767);BEGIN
    l_public:=core_json_pkg.optional_string(p_json,'parentCategoryPublicId');
    IF l_public IS NULL THEN RETURN NULL;END IF;
    RETURN id_for(l_public);
  END;

  PROCEDURE validate_values(p_name VARCHAR2,p_slug VARCHAR2,p_order NUMBER)IS BEGIN
    IF TRIM(p_name)IS NULL OR LENGTH(TRIM(p_name))>200 OR
       TRIM(p_slug)IS NULL OR LENGTH(TRIM(p_slug))>120 OR
       NOT REGEXP_LIKE(p_slug,'^[a-z0-9]+(-[a-z0-9]+)*$') OR
       p_order NOT BETWEEN 0 AND 999999999 THEN RAISE e_invalid;END IF;
  END;

  PROCEDURE validate_parent(p_id NUMBER,p_parent NUMBER)IS l_count NUMBER;BEGIN
    IF p_parent IS NULL THEN RETURN;END IF;
    IF p_parent=p_id THEN RAISE e_cycle;END IF;
    SELECT COUNT(*) INTO l_count FROM(
      SELECT CAT_ID FROM BEX_CATEGORY START WITH CAT_PARENT_ID=p_id
      CONNECT BY NOCYCLE PRIOR CAT_ID=CAT_PARENT_ID
    )WHERE CAT_ID=p_parent;
    IF l_count>0 THEN RAISE e_cycle;END IF;
  END;

  PROCEDURE error_response(p_status NUMBER,p_code VARCHAR2,p_message VARCHAR2,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB)IS
    e core_error_pkg.t_public_error;pol core_error_pkg.t_error_policy;
  BEGIN
    core_error_pkg.build_known_error(p_code,CASE WHEN p_status=403 THEN core_error_pkg.c_category_authorization WHEN p_status=404 THEN core_error_pkg.c_category_not_found WHEN p_status=409 THEN core_error_pkg.c_category_conflict ELSE core_error_pkg.c_category_validation END,p_message,core_error_pkg.c_severity_warn,FALSE,FALSE,e,pol);
    o_body:=core_response_pkg.build_error(e);o_status:=p_status;
  EXCEPTION WHEN OTHERS THEN o_status:=500;o_body:=NULL;END;

  PROCEDURE handle_known(p_code NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB)IS BEGIN
    IF p_code=-1 THEN error_response(409,'BEX-CAT-006','Ja existe uma categoria com esse slug.',o_status,o_body);
    ELSE error_response(500,'BEX-SYS-001','Nao foi possivel concluir a operacao.',o_status,o_body);END IF;
  END;

  PROCEDURE list_categories(p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB)IS
    a JSON_ARRAY_T:=JSON_ARRAY_T();
  BEGIN
    require_admin(p_actor);
    FOR x IN(SELECT CAT_ID FROM BEX_CATEGORY ORDER BY NVL(CAT_PARENT_ID,0),CAT_SORT_ORDER,CAT_NAME,CAT_ID)LOOP core_json_pkg.append_element(a,row_json(x.CAT_ID));END LOOP;
    o_body:=core_response_pkg.build_success(a);o_status:=200;
  EXCEPTION WHEN iam_authorization_pkg.e_forbidden THEN error_response(403,'BEX-AUTH-006','A conta nao possui acesso administrativo.',o_status,o_body);
    WHEN OTHERS THEN error_response(500,'BEX-SYS-001','Nao foi possivel carregar as categorias.',o_status,o_body);END;

  PROCEDURE create_category(p_body CLOB,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB)IS
    j JSON_OBJECT_T;n VARCHAR2(200);s VARCHAR2(120);d VARCHAR2(1000);parent NUMBER;ord NUMBER;accepts NUMBER;id NUMBER;
  BEGIN
    require_admin(p_actor);j:=core_json_pkg.parse_object(p_body);
    core_json_pkg.assert_allowed_attributes(j,'categoryName,categorySlug,description,parentCategoryPublicId,sortOrder,acceptsProducts');
    n:=cat_rule_pkg.normalize_name(core_json_pkg.required_string(j,'categoryName'));
    s:=cat_rule_pkg.normalize_slug(core_json_pkg.required_string(j,'categorySlug'));
    d:=core_json_pkg.optional_string(j,'description');parent:=parse_parent(j);ord:=core_json_pkg.required_number(j,'sortOrder');
    accepts:=CASE WHEN core_json_pkg.required_boolean(j,'acceptsProducts')THEN 1 ELSE 0 END;
    validate_values(n,s,ord);
    INSERT INTO BEX_CATEGORY(CAT_PUBLIC_ID,CAT_NAME,CAT_SLUG,CAT_DESCRIPTION,CAT_PARENT_ID,CAT_SORT_ORDER,CAT_ACCEPTS_PRODUCTS,CAT_STATUS,CAT_CREATED_BY,CAT_UPDATED_BY)
    VALUES(LOWER(RAWTOHEX(SYS_GUID())),n,s,TRIM(d),parent,ord,accepts,'ACTIVE',p_actor,p_actor)RETURNING CAT_ID INTO id;
    o_body:=core_response_pkg.build_success(row_json(id));COMMIT;o_status:=201;
  EXCEPTION WHEN iam_authorization_pkg.e_forbidden THEN ROLLBACK;error_response(403,'BEX-AUTH-006','A conta nao possui acesso administrativo.',o_status,o_body);
    WHEN e_not_found THEN ROLLBACK;error_response(422,'BEX-CAT-004','A categoria pai nao foi encontrada.',o_status,o_body);
    WHEN e_invalid OR core_json_pkg.e_request_body_required OR core_json_pkg.e_invalid_json OR core_json_pkg.e_required_attribute OR core_json_pkg.e_invalid_attribute_type OR core_json_pkg.e_unknown_attribute THEN ROLLBACK;error_response(422,'BEX-CAT-003','Confira os dados da categoria.',o_status,o_body);
    WHEN DUP_VAL_ON_INDEX THEN ROLLBACK;error_response(409,'BEX-CAT-006','Ja existe uma categoria com esse slug.',o_status,o_body);
    WHEN OTHERS THEN ROLLBACK;handle_known(SQLCODE,o_status,o_body);END;

  PROCEDURE update_category(p_public VARCHAR2,p_body CLOB,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB)IS
    j JSON_OBJECT_T;n VARCHAR2(200);s VARCHAR2(120);d VARCHAR2(1000);parent NUMBER;ord NUMBER;accepts NUMBER;id NUMBER;products NUMBER;
  BEGIN
    require_admin(p_actor);id:=id_for(p_public);j:=core_json_pkg.parse_object(p_body);
    core_json_pkg.assert_allowed_attributes(j,'categoryName,categorySlug,description,parentCategoryPublicId,sortOrder,acceptsProducts');
    n:=cat_rule_pkg.normalize_name(core_json_pkg.required_string(j,'categoryName'));s:=cat_rule_pkg.normalize_slug(core_json_pkg.required_string(j,'categorySlug'));
    d:=core_json_pkg.optional_string(j,'description');parent:=parse_parent(j);ord:=core_json_pkg.required_number(j,'sortOrder');accepts:=CASE WHEN core_json_pkg.required_boolean(j,'acceptsProducts')THEN 1 ELSE 0 END;
    validate_values(n,s,ord);validate_parent(id,parent);
    SELECT COUNT(*) INTO products FROM BEX_PRODUCT WHERE CAT_ID=id;
    IF accepts=0 AND products>0 THEN RAISE e_conflict;END IF;
    UPDATE BEX_CATEGORY SET CAT_NAME=n,CAT_SLUG=s,CAT_DESCRIPTION=TRIM(d),CAT_PARENT_ID=parent,CAT_SORT_ORDER=ord,CAT_ACCEPTS_PRODUCTS=accepts,CAT_UPDATED_AT=SYSTIMESTAMP,CAT_UPDATED_BY=p_actor WHERE CAT_ID=id;
    o_body:=core_response_pkg.build_success(row_json(id));COMMIT;o_status:=200;
  EXCEPTION WHEN iam_authorization_pkg.e_forbidden THEN ROLLBACK;error_response(403,'BEX-AUTH-006','A conta nao possui acesso administrativo.',o_status,o_body);
    WHEN e_not_found THEN ROLLBACK;error_response(404,'BEX-CAT-001','Categoria ou categoria pai nao encontrada.',o_status,o_body);
    WHEN e_cycle THEN ROLLBACK;error_response(409,'BEX-CAT-005','A categoria pai criaria um ciclo.',o_status,o_body);
    WHEN e_conflict THEN ROLLBACK;error_response(409,'BEX-CAT-007','Categoria com produtos deve continuar aceitando produtos.',o_status,o_body);
    WHEN e_invalid OR core_json_pkg.e_request_body_required OR core_json_pkg.e_invalid_json OR core_json_pkg.e_required_attribute OR core_json_pkg.e_invalid_attribute_type OR core_json_pkg.e_unknown_attribute THEN ROLLBACK;error_response(422,'BEX-CAT-003','Confira os dados da categoria.',o_status,o_body);
    WHEN DUP_VAL_ON_INDEX THEN ROLLBACK;error_response(409,'BEX-CAT-006','Ja existe uma categoria com esse slug.',o_status,o_body);
    WHEN OTHERS THEN ROLLBACK;handle_known(SQLCODE,o_status,o_body);END;

  PROCEDURE change_status(p_public VARCHAR2,p_status VARCHAR2,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB)IS id NUMBER;used NUMBER;children NUMBER;st VARCHAR2(20):=UPPER(TRIM(p_status));BEGIN
    require_admin(p_actor);id:=id_for(p_public);IF st NOT IN('ACTIVE','INACTIVE')THEN RAISE e_invalid;END IF;
    IF st='INACTIVE'THEN SELECT COUNT(*)INTO used FROM BEX_PRODUCT WHERE CAT_ID=id;SELECT COUNT(*)INTO children FROM BEX_CATEGORY WHERE CAT_PARENT_ID=id;IF used>0 OR children>0 THEN RAISE e_conflict;END IF;END IF;
    UPDATE BEX_CATEGORY SET CAT_STATUS=st,CAT_UPDATED_AT=SYSTIMESTAMP,CAT_UPDATED_BY=p_actor WHERE CAT_ID=id;o_body:=core_response_pkg.build_success(row_json(id));COMMIT;o_status:=200;
  EXCEPTION WHEN iam_authorization_pkg.e_forbidden THEN ROLLBACK;error_response(403,'BEX-AUTH-006','A conta nao possui acesso administrativo.',o_status,o_body);WHEN e_not_found THEN ROLLBACK;error_response(404,'BEX-CAT-001','Categoria nao encontrada.',o_status,o_body);WHEN e_conflict THEN ROLLBACK;error_response(409,'BEX-CAT-008','Categoria com produtos ou subcategorias nao pode ser inativada.',o_status,o_body);WHEN OTHERS THEN ROLLBACK;error_response(500,'BEX-SYS-001','Nao foi possivel alterar a categoria.',o_status,o_body);END;

  PROCEDURE delete_category(p_public VARCHAR2,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB)IS id NUMBER;used NUMBER;children NUMBER;BEGIN
    require_admin(p_actor);id:=id_for(p_public);SELECT COUNT(*)INTO used FROM BEX_PRODUCT WHERE CAT_ID=id;SELECT COUNT(*)INTO children FROM BEX_CATEGORY WHERE CAT_PARENT_ID=id;
    IF used>0 OR children>0 THEN RAISE e_conflict;END IF;DELETE FROM BEX_CATEGORY WHERE CAT_ID=id;COMMIT;o_body:=core_response_pkg.build_success(JSON_OBJECT_T());o_status:=200;
  EXCEPTION WHEN iam_authorization_pkg.e_forbidden THEN ROLLBACK;error_response(403,'BEX-AUTH-006','A conta nao possui acesso administrativo.',o_status,o_body);WHEN e_not_found THEN ROLLBACK;error_response(404,'BEX-CAT-001','Categoria nao encontrada.',o_status,o_body);WHEN e_conflict THEN ROLLBACK;error_response(409,'BEX-CAT-009','Categoria com produtos ou subcategorias nao pode ser excluida. Corrija o cadastro.',o_status,o_body);WHEN OTHERS THEN ROLLBACK;error_response(500,'BEX-SYS-001','Nao foi possivel excluir a categoria.',o_status,o_body);END;
END cat_admin_api_pkg;
/

BEGIN
  ORDS.DEFINE_TEMPLATE(p_module_name=>'brecho-express-v1',p_pattern=>'admin/categories',p_etag_type=>'NONE');
  ORDS.DEFINE_HANDLER('brecho-express-v1','admin/categories','GET',ORDS.SOURCE_TYPE_PLSQL,q'~DECLARE a BOOLEAN;i NUMBER;p VARCHAR2(32);s PLS_INTEGER;b CLOB;BEGIN ord_runtime_pkg.begin_authenticated_request(:authorization,a,i,p,s,b);IF a THEN cat_admin_api_pkg.list_categories(i,s,b);END IF;:status_code:=s;ord_runtime_pkg.write_json_response(b);ord_runtime_pkg.clear_request_context;EXCEPTION WHEN OTHERS THEN ord_runtime_pkg.clear_request_context;RAISE;END;~');
  ORDS.DEFINE_HANDLER('brecho-express-v1','admin/categories','POST',ORDS.SOURCE_TYPE_PLSQL,q'~DECLARE a BOOLEAN;i NUMBER;p VARCHAR2(32);s PLS_INTEGER;b CLOB;request_body CLOB:=:body_text;BEGIN ord_runtime_pkg.begin_authenticated_request(:authorization,a,i,p,s,b);IF a THEN cat_admin_api_pkg.create_category(request_body,i,s,b);END IF;:status_code:=s;ord_runtime_pkg.write_json_response(b);ord_runtime_pkg.clear_request_context;END;~');
  ORDS.DEFINE_TEMPLATE(p_module_name=>'brecho-express-v1',p_pattern=>'admin/categories/:categoryPublicId',p_etag_type=>'NONE');
  ORDS.DEFINE_HANDLER('brecho-express-v1','admin/categories/:categoryPublicId','PUT',ORDS.SOURCE_TYPE_PLSQL,q'~DECLARE a BOOLEAN;i NUMBER;p VARCHAR2(32);s PLS_INTEGER;b CLOB;request_body CLOB:=:body_text;BEGIN ord_runtime_pkg.begin_authenticated_request(:authorization,a,i,p,s,b);IF a THEN cat_admin_api_pkg.update_category(:categoryPublicId,request_body,i,s,b);END IF;:status_code:=s;ord_runtime_pkg.write_json_response(b);ord_runtime_pkg.clear_request_context;END;~');
  ORDS.DEFINE_HANDLER('brecho-express-v1','admin/categories/:categoryPublicId','DELETE',ORDS.SOURCE_TYPE_PLSQL,q'~DECLARE a BOOLEAN;i NUMBER;p VARCHAR2(32);s PLS_INTEGER;b CLOB;BEGIN ord_runtime_pkg.begin_authenticated_request(:authorization,a,i,p,s,b);IF a THEN cat_admin_api_pkg.delete_category(:categoryPublicId,i,s,b);END IF;:status_code:=s;ord_runtime_pkg.write_json_response(b);ord_runtime_pkg.clear_request_context;END;~');
  ORDS.DEFINE_TEMPLATE(p_module_name=>'brecho-express-v1',p_pattern=>'admin/categories/:categoryPublicId/actions/:categoryAction',p_etag_type=>'NONE');
  ORDS.DEFINE_HANDLER('brecho-express-v1','admin/categories/:categoryPublicId/actions/:categoryAction','POST',ORDS.SOURCE_TYPE_PLSQL,q'~DECLARE a BOOLEAN;i NUMBER;p VARCHAR2(32);s PLS_INTEGER;b CLOB;BEGIN ord_runtime_pkg.begin_authenticated_request(:authorization,a,i,p,s,b);IF a THEN cat_admin_api_pkg.change_status(:categoryPublicId,CASE LOWER(:categoryAction)WHEN 'activate' THEN 'ACTIVE'WHEN 'inactivate' THEN 'INACTIVE'ELSE 'INVALID'END,i,s,b);END IF;:status_code:=s;ord_runtime_pkg.write_json_response(b);ord_runtime_pkg.clear_request_context;END;~');
  FOR r IN(SELECT 'admin/categories' pattern,'GET' method FROM DUAL UNION ALL SELECT 'admin/categories','POST'FROM DUAL UNION ALL SELECT 'admin/categories/:categoryPublicId','PUT'FROM DUAL UNION ALL SELECT 'admin/categories/:categoryPublicId','DELETE'FROM DUAL UNION ALL SELECT 'admin/categories/:categoryPublicId/actions/:categoryAction','POST'FROM DUAL)LOOP
    ORDS.DEFINE_PARAMETER(p_module_name=>'brecho-express-v1',p_pattern=>r.pattern,p_method=>r.method,p_name=>'Authorization',p_bind_variable_name=>'authorization',p_source_type=>'HEADER',p_param_type=>'STRING',p_access_method=>'IN');
  END LOOP;
  COMMIT;
END;
/

SHOW ERRORS PACKAGE CAT_ADMIN_API_PKG
SHOW ERRORS PACKAGE BODY CAT_ADMIN_API_PKG

PROMPT Hierarchical category administration installed.
