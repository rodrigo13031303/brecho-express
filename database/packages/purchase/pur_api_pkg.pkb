CREATE OR REPLACE PACKAGE BODY pur_api_pkg AS
  e_bad EXCEPTION;
  FUNCTION item_json(p pur_service_pkg.t_item_record) RETURN JSON_OBJECT_T IS j JSON_OBJECT_T:=JSON_OBJECT_T();
  BEGIN
    core_json_pkg.put_string(j,'itemPublicId',TRIM(p.item_public_id));
    core_json_pkg.put_string(j,'productPublicId',TRIM(p.product_public_id));
    core_json_pkg.put_string(j,'storePublicId',TRIM(p.store_public_id));
    core_json_pkg.put_number(j,'requestedQuantity',p.requested_quantity);
    IF p.confirmed_quantity IS NULL THEN core_json_pkg.put_null(j,'confirmedQuantity');
    ELSE core_json_pkg.put_number(j,'confirmedQuantity',p.confirmed_quantity);END IF;
    core_json_pkg.put_number(j,'unitPrice',p.unit_price);
    IF p.reject_reason IS NULL THEN core_json_pkg.put_null(j,'rejectReason');
    ELSE core_json_pkg.put_string(j,'rejectReason',p.reject_reason);END IF;
    core_json_pkg.put_string(j,'status',p.status);RETURN j;
  END;
  FUNCTION request_json(p pur_service_pkg.t_record) RETURN JSON_OBJECT_T IS
    j JSON_OBJECT_T:=JSON_OBJECT_T();a JSON_ARRAY_T:=JSON_ARRAY_T();i PLS_INTEGER:=p.items.FIRST;
  BEGIN
    core_json_pkg.put_string(j,'requestPublicId',TRIM(p.request_public_id));
    core_json_pkg.put_string(j,'profilePublicId',TRIM(p.profile_public_id));
    core_json_pkg.put_string(j,'status',p.status);
    core_json_pkg.put_string(j,'requestedAt',core_json_pkg.format_timestamp(p.requested_at));
    IF p.confirmed_at IS NULL THEN core_json_pkg.put_null(j,'confirmedAt');
    ELSE core_json_pkg.put_string(j,'confirmedAt',core_json_pkg.format_timestamp(p.confirmed_at));END IF;
    IF p.response_at IS NULL THEN core_json_pkg.put_null(j,'responseAt');
    ELSE core_json_pkg.put_string(j,'responseAt',core_json_pkg.format_timestamp(p.response_at));END IF;
    IF p.expires_at IS NULL THEN core_json_pkg.put_null(j,'expiresAt');
    ELSE core_json_pkg.put_string(j,'expiresAt',core_json_pkg.format_timestamp(p.expires_at));END IF;
    WHILE i IS NOT NULL LOOP core_json_pkg.append_element(a,item_json(p.items(i)));
      i:=p.items.NEXT(i);END LOOP;j.put('items',a);RETURN j;
  END;
  FUNCTION object_body(p CLOB) RETURN JSON_OBJECT_T IS e JSON_ELEMENT_T;
  BEGIN IF p IS NULL OR DBMS_LOB.GETLENGTH(p)=0 THEN RAISE e_bad;END IF;
    BEGIN e:=JSON_ELEMENT_T.parse(p);EXCEPTION WHEN OTHERS THEN RAISE e_bad;END;
    IF e IS NULL OR NOT e.is_object THEN RAISE e_bad;END IF;RETURN TREAT(e AS JSON_OBJECT_T);END;
  PROCEDURE required(p VARCHAR2) IS BEGIN IF TRIM(p) IS NULL THEN RAISE e_bad;END IF;END;
  PROCEDURE actor(p NUMBER) IS BEGIN IF p IS NULL OR p<=0 THEN RAISE e_bad;END IF;END;
  PROCEDURE allowed(j JSON_OBJECT_T) IS k JSON_KEY_LIST:=j.get_keys;
  BEGIN FOR i IN 1..k.COUNT LOOP IF k(i) NOT IN('confirmedQuantity','rejectReason') THEN RAISE e_bad;END IF;END LOOP;END;
  FUNCTION num(j JSON_OBJECT_T,n VARCHAR2) RETURN NUMBER IS e JSON_ELEMENT_T;
  BEGIN IF NOT j.has(n) THEN RAISE e_bad;END IF;e:=j.get(n);
    IF e IS NULL OR e.is_null OR NOT e.is_number THEN RAISE e_bad;END IF;RETURN j.get_number(n);END;
  FUNCTION opt_str(j JSON_OBJECT_T,n VARCHAR2) RETURN VARCHAR2 IS e JSON_ELEMENT_T;
  BEGIN IF NOT j.has(n) THEN RETURN NULL;END IF;e:=j.get(n);
    IF e IS NULL OR e.is_null THEN RETURN NULL;END IF;IF NOT e.is_string THEN RAISE e_bad;END IF;
    RETURN j.get_string(n);END;
  PROCEDURE err(s NUMBER,c VARCHAR2,m VARCHAR2,os OUT PLS_INTEGER,ob OUT NOCOPY CLOB) IS
    e core_error_pkg.t_public_error;p core_error_pkg.t_error_policy;
  BEGIN core_error_pkg.build_known_error(c,CASE WHEN s=404 THEN core_error_pkg.c_category_not_found
    WHEN s=403 THEN core_error_pkg.c_category_authorization ELSE core_error_pkg.c_category_validation END,
    m,core_error_pkg.c_severity_warn,FALSE,FALSE,e,p);ob:=core_response_pkg.build_error(e);os:=s;
  EXCEPTION WHEN OTHERS THEN os:=500;ob:=NULL;END;
  PROCEDURE internal_error(os OUT PLS_INTEGER,ob OUT NOCOPY CLOB) IS
    e core_error_pkg.t_public_error;p core_error_pkg.t_error_policy;
  BEGIN core_error_pkg.build_technical_error('BEX-SYS-001','Nao foi possivel concluir a requisicao.',
    FALSE,e,p);ob:=core_response_pkg.build_error(e);os:=500;
  EXCEPTION WHEN OTHERS THEN os:=500;ob:=NULL;END;

  PROCEDURE checkout(p_cart_public_id VARCHAR2,p_actor_id NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS r pur_service_pkg.t_record;
  BEGIN required(p_cart_public_id);actor(p_actor_id);r:=pur_service_pkg.checkout(p_cart_public_id,p_actor_id);
    COMMIT;o_body:=core_response_pkg.build_success(request_json(r));o_status:=201;
  EXCEPTION WHEN e_bad THEN ROLLBACK;err(400,'BEX-REQ-004','Valores obrigatorios.',o_status,o_body);
    WHEN crt_service_pkg.e_cart_not_found THEN ROLLBACK;err(404,'BEX-CRT-001','Carrinho nao encontrado.',o_status,o_body);
    WHEN crt_service_pkg.e_forbidden THEN ROLLBACK;err(403,'BEX-PUR-003','Operacao nao autorizada.',o_status,o_body);
    WHEN crt_service_pkg.e_empty_cart OR crt_service_pkg.e_cart_closed OR prd_service_pkg.e_invalid_product
      THEN ROLLBACK;err(422,'BEX-PUR-004','Carrinho nao pode ser enviado.',o_status,o_body);
    WHEN OTHERS THEN ROLLBACK;internal_error(o_status,o_body);END;
  PROCEDURE get_request(p_request_public_id VARCHAR2,p_actor_id NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS r pur_service_pkg.t_record;
  BEGIN required(p_request_public_id);actor(p_actor_id);r:=pur_service_pkg.get_request(p_request_public_id,p_actor_id);
    o_body:=core_response_pkg.build_success(request_json(r));o_status:=200;
  EXCEPTION WHEN e_bad THEN err(400,'BEX-REQ-004','Valores obrigatorios.',o_status,o_body);
    WHEN pur_service_pkg.e_request_not_found THEN err(404,'BEX-PUR-001','Solicitacao nao encontrada.',o_status,o_body);
    WHEN pur_service_pkg.e_forbidden THEN err(403,'BEX-PUR-003','Operacao nao autorizada.',o_status,o_body);
    WHEN OTHERS THEN internal_error(o_status,o_body);END;
  PROCEDURE respond_item(p_request_public_id VARCHAR2,p_item_public_id VARCHAR2,p_store_public_id VARCHAR2,
    p_body CLOB,p_actor_id NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS
    j JSON_OBJECT_T;r pur_service_pkg.t_record;
  BEGIN required(p_request_public_id);required(p_item_public_id);required(p_store_public_id);actor(p_actor_id);
    j:=object_body(p_body);allowed(j);r:=pur_service_pkg.respond_item(p_request_public_id,p_item_public_id,
      p_store_public_id,num(j,'confirmedQuantity'),opt_str(j,'rejectReason'),p_actor_id);
    COMMIT;o_body:=core_response_pkg.build_success(request_json(r));o_status:=200;
  EXCEPTION WHEN e_bad THEN ROLLBACK;err(400,'BEX-REQ-002','Resposta comercial invalida.',o_status,o_body);
    WHEN pur_service_pkg.e_request_not_found OR pur_service_pkg.e_item_not_found THEN ROLLBACK;err(404,'BEX-PUR-002','Item da solicitacao nao encontrado.',o_status,o_body);
    WHEN pur_service_pkg.e_forbidden OR str_service_pkg.e_catalog_forbidden THEN ROLLBACK;err(403,'BEX-PUR-003','Operacao nao autorizada.',o_status,o_body);
    WHEN pur_service_pkg.e_invalid_response OR pur_service_pkg.e_request_closed THEN ROLLBACK;err(422,'BEX-PUR-004','Resposta comercial invalida.',o_status,o_body);
    WHEN OTHERS THEN ROLLBACK;internal_error(o_status,o_body);END;
END pur_api_pkg;
/
