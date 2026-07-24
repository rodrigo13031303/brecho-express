CREATE OR REPLACE PACKAGE BODY crt_api_pkg AS
  e_bad EXCEPTION;

  FUNCTION item_json(p crt_service_pkg.t_item_record) RETURN JSON_OBJECT_T IS
    j JSON_OBJECT_T:=JSON_OBJECT_T();
  BEGIN
    core_json_pkg.put_string(j,'itemPublicId',TRIM(p.item_public_id));
    core_json_pkg.put_string(j,'productPublicId',TRIM(p.product_public_id));
    core_json_pkg.put_string(j,'storePublicId',TRIM(p.store_public_id));
    core_json_pkg.put_number(j,'quantity',p.quantity);
    core_json_pkg.put_number(j,'unitPrice',p.unit_price);
    core_json_pkg.put_string(j,'status',p.status);
    RETURN j;
  END;

  FUNCTION cart_json(p crt_service_pkg.t_cart_record) RETURN JSON_OBJECT_T IS
    j JSON_OBJECT_T:=JSON_OBJECT_T();a JSON_ARRAY_T:=JSON_ARRAY_T();
    i PLS_INTEGER:=p.items.FIRST;
  BEGIN
    core_json_pkg.put_string(j,'cartPublicId',TRIM(p.cart_public_id));
    core_json_pkg.put_string(j,'profilePublicId',TRIM(p.profile_public_id));
    core_json_pkg.put_string(j,'status',p.status);
    IF p.expires_at IS NULL THEN core_json_pkg.put_null(j,'expiresAt');
    ELSE core_json_pkg.put_string(j,'expiresAt',core_json_pkg.format_timestamp(p.expires_at));END IF;
    core_json_pkg.put_string(j,'createdAt',core_json_pkg.format_timestamp(p.created_at));
    core_json_pkg.put_string(j,'updatedAt',core_json_pkg.format_timestamp(p.updated_at));
    WHILE i IS NOT NULL LOOP core_json_pkg.append_element(a,item_json(p.items(i)));
      i:=p.items.NEXT(i);END LOOP;
    j.put('items',a);RETURN j;
  END;

  FUNCTION object_body(p CLOB) RETURN JSON_OBJECT_T IS e JSON_ELEMENT_T;
  BEGIN
    IF p IS NULL OR DBMS_LOB.GETLENGTH(p)=0 THEN RAISE e_bad;END IF;
    BEGIN e:=JSON_ELEMENT_T.parse(p);EXCEPTION WHEN OTHERS THEN RAISE e_bad;END;
    IF e IS NULL OR NOT e.is_object THEN RAISE e_bad;END IF;
    RETURN TREAT(e AS JSON_OBJECT_T);
  END;

  PROCEDURE required(p VARCHAR2) IS BEGIN IF TRIM(p) IS NULL THEN RAISE e_bad;END IF;END;
  PROCEDURE actor(p NUMBER) IS BEGIN IF p IS NULL OR p<=0 THEN RAISE e_bad;END IF;END;
  PROCEDURE allowed(j JSON_OBJECT_T,p_add BOOLEAN) IS k JSON_KEY_LIST:=j.get_keys;
  BEGIN
    FOR i IN 1..k.COUNT LOOP
      IF (p_add AND k(i) NOT IN('productPublicId','quantity'))
         OR(NOT p_add AND k(i)<>'quantity') THEN RAISE e_bad;END IF;
    END LOOP;
  END;
  FUNCTION str(j JSON_OBJECT_T,n VARCHAR2) RETURN VARCHAR2 IS e JSON_ELEMENT_T;
  BEGIN
    IF NOT j.has(n) THEN RAISE e_bad;END IF;e:=j.get(n);
    IF e IS NULL OR e.is_null OR NOT e.is_string THEN RAISE e_bad;END IF;
    RETURN j.get_string(n);
  END;
  FUNCTION num(j JSON_OBJECT_T,n VARCHAR2) RETURN NUMBER IS e JSON_ELEMENT_T;
  BEGIN
    IF NOT j.has(n) THEN RAISE e_bad;END IF;e:=j.get(n);
    IF e IS NULL OR e.is_null OR NOT e.is_number THEN RAISE e_bad;END IF;
    RETURN j.get_number(n);
  END;

  PROCEDURE error_response(s NUMBER,c VARCHAR2,m VARCHAR2,
    os OUT PLS_INTEGER,ob OUT NOCOPY CLOB) IS
    e core_error_pkg.t_public_error;p core_error_pkg.t_error_policy;
  BEGIN
    core_error_pkg.build_known_error(c,CASE WHEN s=404 THEN core_error_pkg.c_category_not_found
      WHEN s=403 THEN core_error_pkg.c_category_authorization
      WHEN s=409 THEN core_error_pkg.c_category_conflict
      ELSE core_error_pkg.c_category_validation END,m,
      core_error_pkg.c_severity_warn,FALSE,FALSE,e,p);
    ob:=core_response_pkg.build_error(e);os:=s;
  EXCEPTION WHEN OTHERS THEN os:=500;ob:=NULL;END;
  PROCEDURE internal_error(os OUT PLS_INTEGER,ob OUT NOCOPY CLOB) IS
    e core_error_pkg.t_public_error;p core_error_pkg.t_error_policy;
  BEGIN core_error_pkg.build_technical_error('BEX-SYS-001',
    'Nao foi possivel concluir a requisicao.',FALSE,e,p);
    ob:=core_response_pkg.build_error(e);os:=500;
  EXCEPTION WHEN OTHERS THEN os:=500;ob:=NULL;END;

  PROCEDURE get_or_create_cart(p_actor_id NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS
    r crt_service_pkg.t_cart_record;
  BEGIN actor(p_actor_id);r:=crt_service_pkg.get_or_create_active(p_actor_id);
    COMMIT;o_body:=core_response_pkg.build_success(cart_json(r));o_status:=200;
  EXCEPTION WHEN e_bad THEN ROLLBACK;error_response(400,'BEX-REQ-004','Ator obrigatorio.',o_status,o_body);
    WHEN crt_service_pkg.e_forbidden THEN ROLLBACK;error_response(403,'BEX-CRT-003','Perfil indisponivel.',o_status,o_body);
    WHEN OTHERS THEN ROLLBACK;internal_error(o_status,o_body);END;

  PROCEDURE get_cart(p_cart_public_id VARCHAR2,p_actor_id NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS
    r crt_service_pkg.t_cart_record;
  BEGIN required(p_cart_public_id);actor(p_actor_id);r:=crt_service_pkg.get_cart(p_cart_public_id,p_actor_id);
    o_body:=core_response_pkg.build_success(cart_json(r));o_status:=200;
  EXCEPTION WHEN e_bad THEN error_response(400,'BEX-REQ-004','Valores obrigatorios.',o_status,o_body);
    WHEN crt_service_pkg.e_cart_not_found THEN error_response(404,'BEX-CRT-001','Carrinho nao encontrado.',o_status,o_body);
    WHEN crt_service_pkg.e_forbidden THEN error_response(403,'BEX-CRT-003','Carrinho nao pertence ao perfil.',o_status,o_body);
    WHEN OTHERS THEN internal_error(o_status,o_body);END;

  PROCEDURE add_item(p_cart_public_id VARCHAR2,p_body CLOB,p_actor_id NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS
    j JSON_OBJECT_T;r crt_service_pkg.t_cart_record;
  BEGIN required(p_cart_public_id);actor(p_actor_id);j:=object_body(p_body);allowed(j,TRUE);
    r:=crt_service_pkg.add_item(p_cart_public_id,str(j,'productPublicId'),num(j,'quantity'),p_actor_id);
    COMMIT;o_body:=core_response_pkg.build_success(cart_json(r));o_status:=201;
  EXCEPTION WHEN e_bad THEN ROLLBACK;error_response(400,'BEX-REQ-002','Item do carrinho invalido.',o_status,o_body);
    WHEN crt_service_pkg.e_cart_not_found THEN ROLLBACK;error_response(404,'BEX-CRT-001','Carrinho nao encontrado.',o_status,o_body);
    WHEN prd_service_pkg.e_product_not_found THEN ROLLBACK;error_response(404,'BEX-PRD-001','Achado nao encontrado.',o_status,o_body);
    WHEN crt_service_pkg.e_forbidden THEN ROLLBACK;error_response(403,'BEX-CRT-003','Operacao nao autorizada.',o_status,o_body);
    WHEN crt_service_pkg.e_item_conflict THEN ROLLBACK;error_response(409,'BEX-CRT-005','Achado ja esta no carrinho.',o_status,o_body);
    WHEN crt_service_pkg.e_invalid_quantity OR crt_service_pkg.e_cart_closed OR prd_service_pkg.e_invalid_product
      THEN ROLLBACK;error_response(422,'BEX-CRT-004','Carrinho ou quantidade invalida.',o_status,o_body);
    WHEN OTHERS THEN ROLLBACK;internal_error(o_status,o_body);END;

  PROCEDURE update_item(p_cart_public_id VARCHAR2,p_item_public_id VARCHAR2,p_body CLOB,p_actor_id NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS
    j JSON_OBJECT_T;r crt_service_pkg.t_cart_record;
  BEGIN required(p_cart_public_id);required(p_item_public_id);actor(p_actor_id);
    j:=object_body(p_body);allowed(j,FALSE);
    r:=crt_service_pkg.update_item(p_cart_public_id,p_item_public_id,num(j,'quantity'),p_actor_id);
    COMMIT;o_body:=core_response_pkg.build_success(cart_json(r));o_status:=200;
  EXCEPTION WHEN e_bad THEN ROLLBACK;error_response(400,'BEX-REQ-002','Atualizacao do item invalida.',o_status,o_body);
    WHEN crt_service_pkg.e_cart_not_found OR crt_service_pkg.e_item_not_found THEN ROLLBACK;error_response(404,'BEX-CRT-002','Item nao encontrado.',o_status,o_body);
    WHEN crt_service_pkg.e_forbidden THEN ROLLBACK;error_response(403,'BEX-CRT-003','Operacao nao autorizada.',o_status,o_body);
    WHEN crt_service_pkg.e_invalid_quantity OR crt_service_pkg.e_cart_closed OR prd_service_pkg.e_invalid_product
      THEN ROLLBACK;error_response(422,'BEX-CRT-004','Carrinho ou quantidade invalida.',o_status,o_body);
    WHEN OTHERS THEN ROLLBACK;internal_error(o_status,o_body);END;

  PROCEDURE remove_item(p_cart_public_id VARCHAR2,p_item_public_id VARCHAR2,p_actor_id NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS
    r crt_service_pkg.t_cart_record;
  BEGIN required(p_cart_public_id);required(p_item_public_id);actor(p_actor_id);
    r:=crt_service_pkg.remove_item(p_cart_public_id,p_item_public_id,p_actor_id);
    COMMIT;o_body:=core_response_pkg.build_success(cart_json(r));o_status:=200;
  EXCEPTION WHEN e_bad THEN ROLLBACK;error_response(400,'BEX-REQ-004','Valores obrigatorios.',o_status,o_body);
    WHEN crt_service_pkg.e_cart_not_found OR crt_service_pkg.e_item_not_found THEN ROLLBACK;error_response(404,'BEX-CRT-002','Item nao encontrado.',o_status,o_body);
    WHEN crt_service_pkg.e_forbidden THEN ROLLBACK;error_response(403,'BEX-CRT-003','Operacao nao autorizada.',o_status,o_body);
    WHEN crt_service_pkg.e_cart_closed THEN ROLLBACK;error_response(422,'BEX-CRT-004','Carrinho encerrado.',o_status,o_body);
    WHEN OTHERS THEN ROLLBACK;internal_error(o_status,o_body);END;
END crt_api_pkg;
/
