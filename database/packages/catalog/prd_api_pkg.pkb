CREATE OR REPLACE PACKAGE BODY prd_api_pkg AS
  e_bad_request EXCEPTION; e_actor_required EXCEPTION;

  FUNCTION to_json(p prd_service_pkg.t_product_record) RETURN JSON_OBJECT_T IS
    j JSON_OBJECT_T:=JSON_OBJECT_T();
  BEGIN
    core_json_pkg.put_string(j,'productPublicId',TRIM(p.product_public_id));
    core_json_pkg.put_string(j,'storePublicId',TRIM(p.store_public_id));
    core_json_pkg.put_string(j,'categoryPublicId',TRIM(p.category_public_id));
    IF p.brand_public_id IS NULL THEN core_json_pkg.put_null(j,'brandPublicId');
    ELSE core_json_pkg.put_string(j,'brandPublicId',TRIM(p.brand_public_id)); END IF;
    core_json_pkg.put_string(j,'title',p.title);
    core_json_pkg.put_string(j,'slug',p.slug);
    IF p.description IS NULL THEN core_json_pkg.put_null(j,'description');
    ELSE core_json_pkg.put_string(j,'description',p.description); END IF;
    core_json_pkg.put_number(j,'price',p.price);
    core_json_pkg.put_number(j,'quantity',p.quantity);
    core_json_pkg.put_string(j,'condition',p.condition);
    IF p.weight IS NULL THEN core_json_pkg.put_null(j,'weight');
    ELSE core_json_pkg.put_number(j,'weight',p.weight); END IF;
    IF p.width IS NULL THEN core_json_pkg.put_null(j,'width');
    ELSE core_json_pkg.put_number(j,'width',p.width); END IF;
    IF p.height IS NULL THEN core_json_pkg.put_null(j,'height');
    ELSE core_json_pkg.put_number(j,'height',p.height); END IF;
    IF p.length IS NULL THEN core_json_pkg.put_null(j,'length');
    ELSE core_json_pkg.put_number(j,'length',p.length); END IF;
    core_json_pkg.put_string(j,'status',p.status);
    core_json_pkg.put_string(j,'createdAt',core_json_pkg.format_timestamp(p.created_at));
    core_json_pkg.put_string(j,'updatedAt',core_json_pkg.format_timestamp(p.updated_at));
    RETURN j;
  END;

  FUNCTION to_array(p prd_service_pkg.t_product_table) RETURN JSON_ARRAY_T IS
    a JSON_ARRAY_T:=JSON_ARRAY_T(); i PLS_INTEGER:=p.FIRST;
  BEGIN
    WHILE i IS NOT NULL LOOP
      core_json_pkg.append_element(a,to_json(p(i))); i:=p.NEXT(i);
    END LOOP; RETURN a;
  END;

  PROCEDURE error_response(
    p_status PLS_INTEGER,p_code VARCHAR2,p_message VARCHAR2,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB
  ) IS e core_error_pkg.t_public_error; pol core_error_pkg.t_error_policy;
  BEGIN
    core_error_pkg.build_known_error(
      p_code,CASE WHEN p_status=404 THEN core_error_pkg.c_category_not_found
      WHEN p_status=409 THEN core_error_pkg.c_category_conflict
      WHEN p_status=403 THEN core_error_pkg.c_category_authorization
      ELSE core_error_pkg.c_category_validation END,
      p_message,core_error_pkg.c_severity_warn,FALSE,FALSE,e,pol
    );
    o_body:=core_response_pkg.build_error(e); o_status:=p_status;
  EXCEPTION WHEN OTHERS THEN o_status:=500; o_body:=NULL;
  END;

  PROCEDURE internal_error(o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS
    e core_error_pkg.t_public_error; pol core_error_pkg.t_error_policy;
  BEGIN
    core_error_pkg.build_technical_error(
      'BEX-SYS-001','Nao foi possivel concluir a requisicao.',
      FALSE,e,pol
    );
    o_body:=core_response_pkg.build_error(e); o_status:=500;
  EXCEPTION WHEN OTHERS THEN o_status:=500; o_body:=NULL;
  END;

  PROCEDURE required(p VARCHAR2) IS
  BEGIN IF TRIM(p) IS NULL THEN RAISE e_bad_request; END IF; END;
  PROCEDURE actor(p NUMBER) IS
  BEGIN IF p IS NULL OR p<=0 THEN RAISE e_actor_required; END IF; END;

  FUNCTION parse_object(p CLOB) RETURN JSON_OBJECT_T IS x JSON_ELEMENT_T;
  BEGIN
    IF p IS NULL OR DBMS_LOB.GETLENGTH(p)=0 THEN RAISE e_bad_request; END IF;
    BEGIN x:=JSON_ELEMENT_T.parse(p);
    EXCEPTION WHEN OTHERS THEN RAISE e_bad_request; END;
    IF x IS NULL OR NOT x.is_object THEN RAISE e_bad_request; END IF;
    RETURN TREAT(x AS JSON_OBJECT_T);
  END;
  FUNCTION string_value(j JSON_OBJECT_T,n VARCHAR2,p_required BOOLEAN)
    RETURN VARCHAR2 IS x JSON_ELEMENT_T;
  BEGIN
    IF NOT j.has(n) THEN IF p_required THEN RAISE e_bad_request; END IF; RETURN NULL; END IF;
    x:=j.get(n);
    IF x IS NULL OR x.is_null THEN IF p_required THEN RAISE e_bad_request; END IF; RETURN NULL; END IF;
    IF NOT x.is_string THEN RAISE e_bad_request; END IF;
    RETURN j.get_string(n);
  END;
  FUNCTION number_value(j JSON_OBJECT_T,n VARCHAR2,p_required BOOLEAN)
    RETURN NUMBER IS x JSON_ELEMENT_T;
  BEGIN
    IF NOT j.has(n) THEN IF p_required THEN RAISE e_bad_request; END IF; RETURN NULL; END IF;
    x:=j.get(n);
    IF x IS NULL OR x.is_null THEN IF p_required THEN RAISE e_bad_request; END IF; RETURN NULL; END IF;
    IF NOT x.is_number THEN RAISE e_bad_request; END IF;
    RETURN j.get_number(n);
  END;
  PROCEDURE allowed(j JSON_OBJECT_T,p_patch BOOLEAN) IS k JSON_KEY_LIST:=j.get_keys;
  BEGIN
    FOR i IN 1..k.COUNT LOOP
      IF k(i) NOT IN (
        'categoryPublicId','brandPublicId','title','slug','description',
        'price','quantity','condition','weight','width','height','length'
      ) THEN RAISE e_bad_request; END IF;
    END LOOP;
  END;

  PROCEDURE service_error(
    p_kind PLS_INTEGER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB
  ) IS
  BEGIN
    CASE p_kind
      WHEN 1 THEN error_response(404,'BEX-PRD-001','O Achado nao foi encontrado.',o_status,o_body);
      WHEN 2 THEN error_response(422,'BEX-PRD-002','Os dados do Achado sao invalidos.',o_status,o_body);
      WHEN 3 THEN error_response(422,'BEX-PRD-003','A transicao do Achado e invalida.',o_status,o_body);
      WHEN 4 THEN error_response(409,'BEX-PRD-004','O slug do Achado ja esta em uso.',o_status,o_body);
      WHEN 5 THEN error_response(403,'BEX-PRD-005','O ator nao pode administrar o catalogo.',o_status,o_body);
      ELSE error_response(404,'BEX-PRD-006','Uma referencia informada nao foi encontrada.',o_status,o_body);
    END CASE;
  END;

  PROCEDURE create_product(
    p_store_public_id VARCHAR2,p_request_body CLOB,p_actor_id NUMBER,
    o_status_code OUT PLS_INTEGER,o_response_body OUT NOCOPY CLOB
  ) IS j JSON_OBJECT_T; c prd_rule_pkg.t_product_creation;
    r prd_service_pkg.t_product_record; cat VARCHAR2(32767); brd VARCHAR2(32767);
  BEGIN
    required(p_store_public_id); actor(p_actor_id); j:=parse_object(p_request_body); allowed(j,FALSE);
    cat:=string_value(j,'categoryPublicId',TRUE);
    brd:=string_value(j,'brandPublicId',FALSE);
    c.title_value:=string_value(j,'title',TRUE); c.slug_value:=string_value(j,'slug',TRUE);
    c.description_value:=string_value(j,'description',FALSE);
    c.price_value:=number_value(j,'price',TRUE); c.quantity_value:=number_value(j,'quantity',TRUE);
    c.condition_value:=string_value(j,'condition',TRUE);
    c.weight_value:=number_value(j,'weight',FALSE); c.width_value:=number_value(j,'width',FALSE);
    c.height_value:=number_value(j,'height',FALSE); c.length_value:=number_value(j,'length',FALSE);
    r:=prd_service_pkg.create_product(p_store_public_id,cat,brd,c,p_actor_id);
    COMMIT; o_response_body:=core_response_pkg.build_success(to_json(r)); o_status_code:=201;
  EXCEPTION
    WHEN e_bad_request OR e_actor_required THEN ROLLBACK; error_response(400,'BEX-REQ-002','A requisicao do Achado e invalida.',o_status_code,o_response_body);
    WHEN prd_service_pkg.e_invalid_product THEN ROLLBACK; service_error(2,o_status_code,o_response_body);
    WHEN prd_service_pkg.e_slug_already_used THEN ROLLBACK; service_error(4,o_status_code,o_response_body);
    WHEN str_service_pkg.e_catalog_forbidden THEN ROLLBACK; service_error(5,o_status_code,o_response_body);
    WHEN str_service_pkg.e_store_not_found OR cat_service_pkg.e_category_not_found
      OR brd_service_pkg.e_brand_not_found THEN ROLLBACK; service_error(6,o_status_code,o_response_body);
    WHEN cat_service_pkg.e_category_inactive OR brd_service_pkg.e_brand_inactive
      THEN ROLLBACK; service_error(2,o_status_code,o_response_body);
    WHEN OTHERS THEN ROLLBACK; internal_error(o_status_code,o_response_body);
  END;

  PROCEDURE get_product(p_product_public_id VARCHAR2,o_status_code OUT PLS_INTEGER,o_response_body OUT NOCOPY CLOB) IS r prd_service_pkg.t_product_record;
  BEGIN
    required(p_product_public_id); r:=prd_service_pkg.get_by_public_id(p_product_public_id);
    o_response_body:=core_response_pkg.build_success(to_json(r)); o_status_code:=200;
  EXCEPTION
    WHEN e_bad_request THEN error_response(400,'BEX-REQ-004','Identificador obrigatorio.',o_status_code,o_response_body);
    WHEN prd_service_pkg.e_product_not_found THEN service_error(1,o_status_code,o_response_body);
    WHEN OTHERS THEN internal_error(o_status_code,o_response_body);
  END;

  PROCEDURE get_product_by_slug(p_store_public_id VARCHAR2,p_slug VARCHAR2,o_status_code OUT PLS_INTEGER,o_response_body OUT NOCOPY CLOB) IS r prd_service_pkg.t_product_record;
  BEGIN
    required(p_store_public_id); required(p_slug);
    r:=prd_service_pkg.get_by_store_slug(p_store_public_id,p_slug);
    o_response_body:=core_response_pkg.build_success(to_json(r)); o_status_code:=200;
  EXCEPTION
    WHEN e_bad_request THEN error_response(400,'BEX-REQ-004','Valores obrigatorios.',o_status_code,o_response_body);
    WHEN prd_service_pkg.e_product_not_found OR str_service_pkg.e_store_not_found THEN service_error(1,o_status_code,o_response_body);
    WHEN prd_service_pkg.e_invalid_product THEN service_error(2,o_status_code,o_response_body);
    WHEN OTHERS THEN internal_error(o_status_code,o_response_body);
  END;

  PROCEDURE list_store_products(p_store_public_id VARCHAR2,p_status VARCHAR2,p_actor_id NUMBER,o_status_code OUT PLS_INTEGER,o_response_body OUT NOCOPY CLOB) IS r prd_service_pkg.t_product_table;
  BEGIN
    required(p_store_public_id); actor(p_actor_id);
    r:=prd_service_pkg.list_by_store(p_store_public_id,p_status,p_actor_id);
    o_response_body:=core_response_pkg.build_success(to_array(r)); o_status_code:=200;
  EXCEPTION
    WHEN e_bad_request OR e_actor_required THEN error_response(400,'BEX-REQ-004','Valores obrigatorios.',o_status_code,o_response_body);
    WHEN str_service_pkg.e_catalog_forbidden THEN service_error(5,o_status_code,o_response_body);
    WHEN prd_service_pkg.e_invalid_status THEN service_error(2,o_status_code,o_response_body);
    WHEN str_service_pkg.e_store_not_found THEN service_error(6,o_status_code,o_response_body);
    WHEN OTHERS THEN internal_error(o_status_code,o_response_body);
  END;

  PROCEDURE list_public_products(p_category_public_id VARCHAR2,p_brand_public_id VARCHAR2,p_condition VARCHAR2,o_status_code OUT PLS_INTEGER,o_response_body OUT NOCOPY CLOB) IS r prd_service_pkg.t_product_table;
  BEGIN
    r:=prd_service_pkg.list_public(p_category_public_id,p_brand_public_id,p_condition);
    o_response_body:=core_response_pkg.build_success(to_array(r)); o_status_code:=200;
  EXCEPTION
    WHEN prd_service_pkg.e_invalid_product THEN service_error(2,o_status_code,o_response_body);
    WHEN cat_service_pkg.e_category_not_found OR brd_service_pkg.e_brand_not_found THEN service_error(6,o_status_code,o_response_body);
    WHEN cat_service_pkg.e_category_inactive OR brd_service_pkg.e_brand_inactive
      THEN service_error(2,o_status_code,o_response_body);
    WHEN OTHERS THEN internal_error(o_status_code,o_response_body);
  END;

  PROCEDURE patch_product(p_product_public_id VARCHAR2,p_store_public_id VARCHAR2,p_request_body CLOB,p_actor_id NUMBER,o_status_code OUT PLS_INTEGER,o_response_body OUT NOCOPY CLOB) IS
    j JSON_OBJECT_T; p prd_rule_pkg.t_product_patch; r prd_service_pkg.t_product_record;
    sc BOOLEAN; sb BOOLEAN; cat VARCHAR2(32767); brd VARCHAR2(32767);
  BEGIN
    required(p_product_public_id); required(p_store_public_id); actor(p_actor_id);
    j:=parse_object(p_request_body); allowed(j,TRUE);
    sc:=j.has('categoryPublicId'); sb:=j.has('brandPublicId');
    IF sc THEN cat:=string_value(j,'categoryPublicId',TRUE); END IF;
    IF sb THEN brd:=string_value(j,'brandPublicId',FALSE); END IF;
    p.set_title:=j.has('title'); IF p.set_title THEN p.title_value:=string_value(j,'title',TRUE); END IF;
    p.set_slug:=j.has('slug'); IF p.set_slug THEN p.slug_value:=string_value(j,'slug',TRUE); END IF;
    p.set_description:=j.has('description'); IF p.set_description THEN p.description_value:=string_value(j,'description',FALSE); END IF;
    p.set_price:=j.has('price'); IF p.set_price THEN p.price_value:=number_value(j,'price',TRUE); END IF;
    p.set_quantity:=j.has('quantity'); IF p.set_quantity THEN p.quantity_value:=number_value(j,'quantity',TRUE); END IF;
    p.set_condition:=j.has('condition'); IF p.set_condition THEN p.condition_value:=string_value(j,'condition',TRUE); END IF;
    p.set_weight:=j.has('weight'); IF p.set_weight THEN p.weight_value:=number_value(j,'weight',FALSE); END IF;
    p.set_width:=j.has('width'); IF p.set_width THEN p.width_value:=number_value(j,'width',FALSE); END IF;
    p.set_height:=j.has('height'); IF p.set_height THEN p.height_value:=number_value(j,'height',FALSE); END IF;
    p.set_length:=j.has('length'); IF p.set_length THEN p.length_value:=number_value(j,'length',FALSE); END IF;
    r:=prd_service_pkg.update_product(p_product_public_id,p_store_public_id,p,sc,cat,sb,brd,p_actor_id);
    COMMIT; o_response_body:=core_response_pkg.build_success(to_json(r)); o_status_code:=200;
  EXCEPTION
    WHEN e_bad_request OR e_actor_required THEN ROLLBACK; error_response(400,'BEX-REQ-002','A requisicao do Achado e invalida.',o_status_code,o_response_body);
    WHEN prd_service_pkg.e_product_not_found THEN ROLLBACK; service_error(1,o_status_code,o_response_body);
    WHEN prd_service_pkg.e_invalid_product OR prd_service_pkg.e_empty_patch
      OR prd_service_pkg.e_product_archived THEN ROLLBACK; service_error(2,o_status_code,o_response_body);
    WHEN prd_service_pkg.e_slug_already_used THEN ROLLBACK; service_error(4,o_status_code,o_response_body);
    WHEN str_service_pkg.e_catalog_forbidden THEN ROLLBACK; service_error(5,o_status_code,o_response_body);
    WHEN cat_service_pkg.e_category_not_found OR brd_service_pkg.e_brand_not_found
      THEN ROLLBACK; service_error(6,o_status_code,o_response_body);
    WHEN cat_service_pkg.e_category_inactive OR brd_service_pkg.e_brand_inactive
      THEN ROLLBACK; service_error(2,o_status_code,o_response_body);
    WHEN OTHERS THEN ROLLBACK; internal_error(o_status_code,o_response_body);
  END;

  PROCEDURE change_status(p_product_public_id VARCHAR2,p_store_public_id VARCHAR2,p_new_status VARCHAR2,p_actor_id NUMBER,o_status_code OUT PLS_INTEGER,o_response_body OUT NOCOPY CLOB) IS r prd_service_pkg.t_product_record;
  BEGIN
    required(p_product_public_id); required(p_store_public_id); required(p_new_status); actor(p_actor_id);
    r:=prd_service_pkg.change_status(p_product_public_id,p_store_public_id,p_new_status,p_actor_id);
    COMMIT; o_response_body:=core_response_pkg.build_success(to_json(r)); o_status_code:=200;
  EXCEPTION
    WHEN e_bad_request OR e_actor_required THEN ROLLBACK; error_response(400,'BEX-REQ-004','Valores obrigatorios.',o_status_code,o_response_body);
    WHEN prd_service_pkg.e_product_not_found THEN ROLLBACK; service_error(1,o_status_code,o_response_body);
    WHEN prd_service_pkg.e_invalid_status OR prd_service_pkg.e_invalid_transition
      OR prd_service_pkg.e_activation_no_stock THEN ROLLBACK; service_error(3,o_status_code,o_response_body);
    WHEN str_service_pkg.e_catalog_forbidden THEN ROLLBACK; service_error(5,o_status_code,o_response_body);
    WHEN OTHERS THEN ROLLBACK; internal_error(o_status_code,o_response_body);
  END;
END prd_api_pkg;
/
