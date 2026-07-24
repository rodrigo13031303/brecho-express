CREATE OR REPLACE PACKAGE BODY pim_api_pkg AS
  e_bad EXCEPTION;
  FUNCTION json(p pim_service_pkg.t_record) RETURN JSON_OBJECT_T IS j JSON_OBJECT_T:=JSON_OBJECT_T();
  BEGIN
    core_json_pkg.put_string(j,'imagePublicId',TRIM(p.image_public_id));
    core_json_pkg.put_string(j,'productPublicId',TRIM(p.product_public_id));
    core_json_pkg.put_string(j,'imageUrl',p.image_url);
    IF p.alt_text IS NULL THEN core_json_pkg.put_null(j,'altText');
    ELSE core_json_pkg.put_string(j,'altText',p.alt_text);END IF;
    core_json_pkg.put_number(j,'sortOrder',p.sort_order);
    core_json_pkg.put_boolean(j,'isPrimary',p.is_primary=1);
    core_json_pkg.put_string(j,'status',p.status);
    core_json_pkg.put_string(j,'createdAt',core_json_pkg.format_timestamp(p.created_at));
    core_json_pkg.put_string(j,'updatedAt',core_json_pkg.format_timestamp(p.updated_at));
    RETURN j;
  END;
  FUNCTION array_json(p pim_service_pkg.t_table) RETURN JSON_ARRAY_T IS
    a JSON_ARRAY_T:=JSON_ARRAY_T();i PLS_INTEGER:=p.FIRST;
  BEGIN WHILE i IS NOT NULL LOOP core_json_pkg.append_element(a,json(p(i)));i:=p.NEXT(i);END LOOP;RETURN a;END;
  FUNCTION obj(p CLOB) RETURN JSON_OBJECT_T IS e JSON_ELEMENT_T;
  BEGIN
    IF p IS NULL OR DBMS_LOB.GETLENGTH(p)=0 THEN RAISE e_bad;END IF;
    BEGIN e:=JSON_ELEMENT_T.parse(p);EXCEPTION WHEN OTHERS THEN RAISE e_bad;END;
    IF NOT e.is_object THEN RAISE e_bad;END IF;RETURN TREAT(e AS JSON_OBJECT_T);
  END;
  FUNCTION str(j JSON_OBJECT_T,n VARCHAR2,req BOOLEAN) RETURN VARCHAR2 IS e JSON_ELEMENT_T;
  BEGIN
    IF NOT j.has(n) THEN IF req THEN RAISE e_bad;END IF;RETURN NULL;END IF;e:=j.get(n);
    IF e.is_null THEN IF req THEN RAISE e_bad;END IF;RETURN NULL;END IF;
    IF NOT e.is_string THEN RAISE e_bad;END IF;RETURN j.get_string(n);
  END;
  FUNCTION num(j JSON_OBJECT_T,n VARCHAR2,req BOOLEAN) RETURN NUMBER IS e JSON_ELEMENT_T;
  BEGIN
    IF NOT j.has(n) THEN IF req THEN RAISE e_bad;END IF;RETURN NULL;END IF;e:=j.get(n);
    IF e.is_null THEN IF req THEN RAISE e_bad;END IF;RETURN NULL;END IF;
    IF NOT e.is_number THEN RAISE e_bad;END IF;RETURN j.get_number(n);
  END;
  PROCEDURE fields(j JSON_OBJECT_T) IS k JSON_KEY_LIST:=j.get_keys;
  BEGIN FOR i IN 1..k.COUNT LOOP IF k(i) NOT IN(
    'imageUrl','altText','sortOrder','isPrimary')THEN RAISE e_bad;END IF;END LOOP;END;
  PROCEDURE required(p VARCHAR2) IS BEGIN IF TRIM(p) IS NULL THEN RAISE e_bad;END IF;END;
  PROCEDURE actor(p NUMBER) IS BEGIN IF p IS NULL OR p<=0 THEN RAISE e_bad;END IF;END;
  PROCEDURE err(s NUMBER,c VARCHAR2,m VARCHAR2,os OUT PLS_INTEGER,ob OUT NOCOPY CLOB) IS
    e core_error_pkg.t_public_error;p core_error_pkg.t_error_policy;
  BEGIN core_error_pkg.build_known_error(c,CASE WHEN s=404 THEN core_error_pkg.c_category_not_found
    WHEN s=403 THEN core_error_pkg.c_category_authorization WHEN s=409 THEN core_error_pkg.c_category_conflict
    ELSE core_error_pkg.c_category_validation END,m,core_error_pkg.c_severity_warn,FALSE,FALSE,e,p);
    ob:=core_response_pkg.build_error(e);os:=s;END;
  PROCEDURE add_image(p_product_public_id VARCHAR2,p_store_public_id VARCHAR2,
    p_body CLOB,p_actor_id NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS
    j JSON_OBJECT_T;d pim_rule_pkg.t_image_data;r pim_service_pkg.t_record;
  BEGIN
    required(p_product_public_id);required(p_store_public_id);actor(p_actor_id);
    j:=obj(p_body);fields(j);d.url_value:=str(j,'imageUrl',TRUE);d.alt_text_value:=str(j,'altText',FALSE);
    d.sort_order_value:=num(j,'sortOrder',TRUE);
    IF NOT j.has('isPrimary') OR NOT j.get('isPrimary').is_boolean THEN RAISE e_bad;END IF;
    d.is_primary_value:=CASE WHEN j.get_boolean('isPrimary') THEN 1 ELSE 0 END;d.status_value:='ACTIVE';
    r:=pim_service_pkg.add_image(p_product_public_id,p_store_public_id,d,p_actor_id);
    COMMIT;o_body:=core_response_pkg.build_success(json(r));o_status:=201;
  EXCEPTION WHEN e_bad THEN ROLLBACK;err(400,'BEX-REQ-002','Requisicao de imagem invalida.',o_status,o_body);
    WHEN pim_service_pkg.e_invalid_image THEN ROLLBACK;err(422,'BEX-PIM-002','Imagem invalida.',o_status,o_body);
    WHEN pim_service_pkg.e_primary_conflict THEN ROLLBACK;err(409,'BEX-PIM-003','Imagem principal em conflito.',o_status,o_body);
    WHEN prd_service_pkg.e_product_not_found THEN ROLLBACK;err(404,'BEX-PRD-001','Achado nao encontrado.',o_status,o_body);
    WHEN str_service_pkg.e_catalog_forbidden THEN ROLLBACK;err(403,'BEX-PIM-004','Operacao nao autorizada.',o_status,o_body);
    WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=NULL;END;
  PROCEDURE get_image(p_image_public_id VARCHAR2,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS r pim_service_pkg.t_record;
  BEGIN required(p_image_public_id);r:=pim_service_pkg.get_image(p_image_public_id);IF r.status<>'ACTIVE' THEN RAISE pim_service_pkg.e_image_not_found;END IF;
    o_body:=core_response_pkg.build_success(json(r));o_status:=200;
  EXCEPTION WHEN e_bad THEN err(400,'BEX-REQ-004','Identificador obrigatorio.',o_status,o_body);
    WHEN pim_service_pkg.e_image_not_found THEN err(404,'BEX-PIM-001','Imagem nao encontrada.',o_status,o_body);
    WHEN OTHERS THEN o_status:=500;o_body:=NULL;END;
  PROCEDURE list_images(p_product_public_id VARCHAR2,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS r pim_service_pkg.t_table;
  BEGIN required(p_product_public_id);r:=pim_service_pkg.list_images(p_product_public_id);o_body:=core_response_pkg.build_success(array_json(r));o_status:=200;
  EXCEPTION WHEN e_bad THEN err(400,'BEX-REQ-004','Identificador obrigatorio.',o_status,o_body);
    WHEN prd_service_pkg.e_product_not_found THEN err(404,'BEX-PRD-001','Achado nao encontrado.',o_status,o_body);
    WHEN OTHERS THEN o_status:=500;o_body:=NULL;END;
  PROCEDURE update_image(p_image_public_id VARCHAR2,p_store_public_id VARCHAR2,p_body CLOB,p_actor_id NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS
    j JSON_OBJECT_T;p pim_rule_pkg.t_image_patch;r pim_service_pkg.t_record;
  BEGIN required(p_image_public_id);required(p_store_public_id);actor(p_actor_id);
    j:=obj(p_body);fields(j);p.set_url:=j.has('imageUrl');IF p.set_url THEN p.url_value:=str(j,'imageUrl',TRUE);END IF;
    p.set_alt_text:=j.has('altText');IF p.set_alt_text THEN p.alt_text_value:=str(j,'altText',FALSE);END IF;
    p.set_sort_order:=j.has('sortOrder');IF p.set_sort_order THEN p.sort_order_value:=num(j,'sortOrder',TRUE);END IF;
    p.set_is_primary:=j.has('isPrimary');IF p.set_is_primary THEN IF NOT j.get('isPrimary').is_boolean THEN RAISE e_bad;END IF;
      p.is_primary_value:=CASE WHEN j.get_boolean('isPrimary') THEN 1 ELSE 0 END;END IF;
    r:=pim_service_pkg.update_image(p_image_public_id,p_store_public_id,p,p_actor_id);
    COMMIT;o_body:=core_response_pkg.build_success(json(r));o_status:=200;
  EXCEPTION WHEN e_bad THEN ROLLBACK;err(400,'BEX-REQ-002','Patch de imagem invalido.',o_status,o_body);
    WHEN pim_service_pkg.e_image_not_found THEN ROLLBACK;err(404,'BEX-PIM-001','Imagem nao encontrada.',o_status,o_body);
    WHEN pim_service_pkg.e_invalid_image OR pim_service_pkg.e_empty_patch THEN ROLLBACK;err(422,'BEX-PIM-002','Imagem invalida.',o_status,o_body);
    WHEN str_service_pkg.e_catalog_forbidden THEN ROLLBACK;err(403,'BEX-PIM-004','Operacao nao autorizada.',o_status,o_body);
    WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=NULL;END;
  PROCEDURE deactivate_image(p_image_public_id VARCHAR2,p_store_public_id VARCHAR2,p_actor_id NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS r pim_service_pkg.t_record;
  BEGIN required(p_image_public_id);required(p_store_public_id);actor(p_actor_id);
    r:=pim_service_pkg.deactivate_image(p_image_public_id,p_store_public_id,p_actor_id);
    COMMIT;o_body:=core_response_pkg.build_success(json(r));o_status:=200;
  EXCEPTION WHEN e_bad THEN ROLLBACK;err(400,'BEX-REQ-004','Valores obrigatorios.',o_status,o_body);
    WHEN pim_service_pkg.e_image_not_found THEN ROLLBACK;err(404,'BEX-PIM-001','Imagem nao encontrada.',o_status,o_body);
    WHEN str_service_pkg.e_catalog_forbidden THEN ROLLBACK;err(403,'BEX-PIM-004','Operacao nao autorizada.',o_status,o_body);
    WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=NULL;END;
END pim_api_pkg;
/
