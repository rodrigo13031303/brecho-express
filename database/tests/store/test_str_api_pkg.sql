SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  g_test_count   PLS_INTEGER := 0;
  g_current_test VARCHAR2(200);
  g_trace_id     core_trace_pkg.t_trace_id;
  c_expected_test_count CONSTANT PLS_INTEGER := 40;

  l_token VARCHAR2(12);
  l_account_id BEX_ACCOUNT.ACC_ID%TYPE;
  l_other_account_id BEX_ACCOUNT.ACC_ID%TYPE;
  l_empty_account_id BEX_ACCOUNT.ACC_ID%TYPE;
  l_blocked_account_id BEX_ACCOUNT.ACC_ID%TYPE;
  l_account_public_id BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE;
  l_other_account_public_id BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE;
  l_empty_account_public_id BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE;
  l_blocked_account_public_id BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE;
  l_store_public_id VARCHAR2(32);
  l_store_slug VARCHAR2(100);
  l_other_store_public_id VARCHAR2(32);
  l_request CLOB;
  l_response CLOB;
  l_status PLS_INTEGER;
  l_envelope JSON_OBJECT_T;
  l_data JSON_OBJECT_T;
  l_error JSON_OBJECT_T;
  l_array JSON_ARRAY_T;

  PROCEDURE fail(p_message IN VARCHAR2) IS
  BEGIN RAISE_APPLICATION_ERROR(-20999,p_message); END;

  PROCEDURE assert_true(p_condition IN BOOLEAN,p_message IN VARCHAR2) IS
  BEGIN IF p_condition IS NULL OR NOT p_condition THEN fail(p_message); END IF; END;

  PROCEDURE assert_false(p_condition IN BOOLEAN,p_message IN VARCHAR2) IS
  BEGIN IF p_condition IS NULL OR p_condition THEN fail(p_message); END IF; END;

  PROCEDURE start_test(p_name IN VARCHAR2) IS
  BEGIN g_current_test := p_name; END;

  PROCEDURE pass IS
  BEGIN
    g_test_count := g_test_count + 1;
    DBMS_OUTPUT.PUT_LINE('PASS '||LPAD(g_test_count,2,'0')||' - '||g_current_test);
  END;

  PROCEDURE free_clob(io_value IN OUT NOCOPY CLOB) IS
  BEGIN
    IF io_value IS NOT NULL AND DBMS_LOB.ISTEMPORARY(io_value)=1 THEN
      DBMS_LOB.FREETEMPORARY(io_value);
    END IF;
    io_value := NULL;
  END;

  PROCEDURE clear_context IS
  BEGIN
    core_security_context_pkg.clear; core_context_pkg.clear; core_trace_pkg.clear;
  END;

  PROCEDURE init_context IS
  BEGIN
    clear_context; core_trace_pkg.initialize; g_trace_id := core_trace_pkg.current_trace_id;
    core_context_pkg.initialize(core_context_pkg.c_origin_external,
      core_context_pkg.c_mode_synchronous,l_account_public_id,TRUE);
    core_security_context_pkg.initialize(core_security_context_pkg.c_actor_type_user,
      core_security_context_pkg.c_authentication_method_session);
  END;

  PROCEDURE create_account(p_status IN VARCHAR2,o_id OUT NUMBER,o_public OUT VARCHAR2) IS
    l_email VARCHAR2(255);
  BEGIN
    o_public := LOWER(RAWTOHEX(SYS_GUID()));
    l_email := 'store.api.'||LOWER(RAWTOHEX(SYS_GUID()))||'@example.invalid';
    INSERT INTO BEX_ACCOUNT(ACC_PUBLIC_ID,ACC_EMAIL,ACC_PASSWORD_HASH,
      ACC_PASSWORD_CHANGED_AT,ACC_STATUS)
    VALUES(o_public,l_email,'store-api-test-credential',SYSTIMESTAMP,p_status)
    RETURNING ACC_ID INTO o_id;
  END;

  FUNCTION create_body(
    p_name VARCHAR2,p_slug VARCHAR2,p_unknown BOOLEAN DEFAULT FALSE
  ) RETURN CLOB IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
  BEGIN
    core_json_pkg.put_string(l_object,'storeName',p_name);
    core_json_pkg.put_string(l_object,'storeSlug',p_slug);
    core_json_pkg.put_null(l_object,'description');
    core_json_pkg.put_null(l_object,'logoUrl');
    core_json_pkg.put_null(l_object,'coverUrl');
    IF p_unknown THEN core_json_pkg.put_string(l_object,'accId','forbidden'); END IF;
    RETURN core_json_pkg.serialize(l_object);
  END;

  FUNCTION patch_body(p_name VARCHAR2,p_value VARCHAR2,p_null BOOLEAN DEFAULT FALSE) RETURN CLOB IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
  BEGIN
    IF p_name IS NOT NULL THEN
      IF p_null THEN core_json_pkg.put_null(l_object,p_name);
      ELSE core_json_pkg.put_string(l_object,p_name,p_value); END IF;
    END IF;
    RETURN core_json_pkg.serialize(l_object);
  END;

  FUNCTION full_create_body(
    p_slug VARCHAR2, p_logo VARCHAR2, p_cover VARCHAR2,
    p_locale VARCHAR2, p_timezone VARCHAR2
  ) RETURN CLOB IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
  BEGIN
    core_json_pkg.put_string(l_object,'storeName','Validation Store');
    core_json_pkg.put_string(l_object,'storeSlug',p_slug);
    IF p_logo IS NULL THEN core_json_pkg.put_null(l_object,'logoUrl');
    ELSE core_json_pkg.put_string(l_object,'logoUrl',p_logo); END IF;
    IF p_cover IS NULL THEN core_json_pkg.put_null(l_object,'coverUrl');
    ELSE core_json_pkg.put_string(l_object,'coverUrl',p_cover); END IF;
    core_json_pkg.put_string(l_object,'localeCode',p_locale);
    core_json_pkg.put_string(l_object,'timezoneName',p_timezone);
    RETURN core_json_pkg.serialize(l_object);
  END;

  PROCEDURE parse_response IS
  BEGIN l_envelope := JSON_OBJECT_T.parse(l_response); END;

  FUNCTION json_is_null(
    p_object IN JSON_OBJECT_T,
    p_name   IN VARCHAR2
  ) RETURN BOOLEAN IS
    l_element JSON_ELEMENT_T;
  BEGIN
    l_element := p_object.get(p_name);
    RETURN l_element IS NOT NULL AND l_element.is_null;
  END;

  PROCEDURE assert_error(p_status PLS_INTEGER,p_code VARCHAR2) IS
  BEGIN
    assert_true(l_status=p_status,'Status de erro incorreto.');
    assert_true(l_response IS NOT NULL,'Envelope de erro ausente.'); parse_response;
    l_error := l_envelope.get_object('error');
    assert_false(l_envelope.get_boolean('success'),'Erro retornou sucesso.');
    assert_true(l_error.get_string('code')=p_code,'Codigo de erro incorreto.');
  END;

  PROCEDURE invoke_create(p_account VARCHAR2,p_body CLOB,p_actor NUMBER) IS
  BEGIN
    free_clob(l_response); init_context;
    str_api_pkg.create_store(p_account,p_body,p_actor,l_status,l_response); clear_context;
  END;

  PROCEDURE invoke_get(p_public VARCHAR2,p_actor NUMBER) IS
  BEGIN free_clob(l_response); init_context;
    str_api_pkg.get_store(p_public,p_actor,l_status,l_response); clear_context; END;

  PROCEDURE invoke_get_slug(p_slug VARCHAR2,p_actor NUMBER) IS
  BEGIN free_clob(l_response); init_context;
    str_api_pkg.get_store_by_slug(p_slug,p_actor,l_status,l_response); clear_context; END;

  PROCEDURE invoke_list(p_account VARCHAR2,p_actor NUMBER) IS
  BEGIN free_clob(l_response); init_context;
    str_api_pkg.list_stores_by_account(p_account,p_actor,l_status,l_response); clear_context; END;

  PROCEDURE invoke_update(p_public VARCHAR2,p_body CLOB,p_actor NUMBER) IS
  BEGIN free_clob(l_response); init_context;
    str_api_pkg.update_store(p_public,p_body,p_actor,l_status,l_response); clear_context; END;

  PROCEDURE invoke_activate(p_public VARCHAR2,p_actor NUMBER) IS
  BEGIN free_clob(l_response); init_context;
    str_api_pkg.activate_store(p_public,p_actor,l_status,l_response); clear_context; END;

  PROCEDURE invoke_close(p_public VARCHAR2,p_actor NUMBER) IS
  BEGIN free_clob(l_response); init_context;
    str_api_pkg.close_store(p_public,p_actor,l_status,l_response); clear_context; END;

  PROCEDURE invoke_available(p_slug VARCHAR2,p_actor NUMBER) IS
  BEGIN free_clob(l_response); init_context;
    str_api_pkg.check_slug_availability(p_slug,p_actor,l_status,l_response); clear_context; END;

  PROCEDURE cleanup IS
  BEGIN
    DELETE FROM BEX_STORE WHERE ACC_ID IN
      (l_account_id,l_other_account_id,l_empty_account_id,l_blocked_account_id);
    DELETE FROM BEX_ACCOUNT WHERE ACC_ID IN
      (l_account_id,l_other_account_id,l_empty_account_id,l_blocked_account_id);
    COMMIT;
  END;

  PROCEDURE run_tests IS
    l_count PLS_INTEGER; l_source_count PLS_INTEGER; l_before VARCHAR2(200);
  BEGIN
    start_test('Specification esta valida');
    SELECT COUNT(*) INTO l_count FROM USER_OBJECTS WHERE OBJECT_NAME='STR_API_PKG' AND OBJECT_TYPE='PACKAGE' AND STATUS='VALID';
    assert_true(l_count=1,'Specification invalida.'); pass;

    start_test('Body esta valido e sem USER_ERRORS');
    SELECT COUNT(*) INTO l_count FROM USER_OBJECTS WHERE OBJECT_NAME='STR_API_PKG' AND OBJECT_TYPE='PACKAGE BODY' AND STATUS='VALID';
    SELECT COUNT(*) INTO l_source_count FROM USER_ERRORS WHERE NAME='STR_API_PKG';
    assert_true(l_count=1 AND l_source_count=0,'Body invalido ou com erros.'); pass;

    l_request := create_body('  Store   API  ',' Store API '||l_token);
    invoke_create(l_account_public_id,l_request,l_account_id); free_clob(l_request);
    start_test('CREATE retorna 201 e envelope oficial');
    assert_true(l_status=201,'Status de criacao incorreto.'); parse_response;
    assert_true(l_envelope.get_boolean('success') AND l_envelope.get_string('traceId')=g_trace_id,'Envelope incorreto.'); pass;

    start_test('CREATE retorna payload publico normalizado');
    l_data := l_envelope.get_object('data'); l_store_public_id := l_data.get_string('storePublicId'); l_store_slug := l_data.get_string('storeSlug');
    assert_true(LENGTH(l_store_public_id)=32 AND l_data.get_string('storeName')='Store API' AND l_store_slug='store-api-'||l_token,'Payload incorreto.'); pass;

    start_test('Payload nao expoe IDs internos ou auditoria tecnica');
    assert_false(l_data.has('strId') OR l_data.has('accId') OR l_data.has('createdBy') OR l_data.has('updatedBy'),'Payload interno exposto.'); pass;

    start_test('Payload representa opcionais nulos e timestamps');
    assert_true(json_is_null(l_data,'description') AND json_is_null(l_data,'logoUrl') AND json_is_null(l_data,'coverUrl') AND l_data.has('createdAt') AND l_data.has('updatedAt'),'Opcionais ou timestamps incorretos.'); pass;

    start_test('CREATE executa COMMIT');
    ROLLBACK; SELECT COUNT(*) INTO l_count FROM BEX_STORE WHERE STR_PUBLIC_ID=l_store_public_id;
    assert_true(l_count=1,'Criacao nao foi confirmada.'); pass;

    start_test('GET por public ID retorna 200');
    invoke_get(l_store_public_id,l_account_id); parse_response; l_data:=l_envelope.get_object('data');
    assert_true(l_status=200 AND l_data.get_string('storePublicId')=l_store_public_id,'GET incorreto.'); pass;

    start_test('GET por slug normaliza entrada');
    invoke_get_slug(' '||UPPER(l_store_slug)||' ',l_account_id); parse_response;
    assert_true(l_status=200 AND l_envelope.get_object('data').get_string('storePublicId')=l_store_public_id,'GET slug incorreto.'); pass;

    l_request:=create_body('Other API','other-api-'||l_token); invoke_create(l_account_public_id,l_request,l_account_id); free_clob(l_request);
    parse_response; l_other_store_public_id:=l_envelope.get_object('data').get_string('storePublicId');
    start_test('LIST retorna array com varias STORE');
    invoke_list(l_account_public_id,l_account_id); parse_response; l_array:=l_envelope.get_array('data');
    assert_true(l_status=200 AND l_array.get_size=2,'LIST incorreta.'); pass;

    start_test('LIST vazia retorna array vazio');
    invoke_list(l_empty_account_public_id,l_account_id); parse_response; l_array:=l_envelope.get_array('data');
    assert_true(l_array.get_size=0,'Lista vazia incorreta.'); pass;

    start_test('PATCH altera campo presente');
    l_request:=patch_body('storeName','Updated API'); invoke_update(l_store_public_id,l_request,l_account_id); free_clob(l_request);
    parse_response; l_data:=l_envelope.get_object('data'); assert_true(l_status=200 AND l_data.get_string('storeName')='Updated API','PATCH nao alterou nome.'); pass;

    start_test('PATCH preserva campo ausente');
    l_before:=l_data.get_string('storeSlug'); l_request:=patch_body('description','New description');
    invoke_update(l_store_public_id,l_request,l_account_id); free_clob(l_request); parse_response; l_data:=l_envelope.get_object('data');
    assert_true(l_data.get_string('storeSlug')=l_before,'Campo ausente foi alterado.'); pass;

    start_test('PATCH JSON null limpa anulavel');
    l_request:=patch_body('description',NULL,TRUE); invoke_update(l_store_public_id,l_request,l_account_id); free_clob(l_request); parse_response;
    assert_true(json_is_null(l_envelope.get_object('data'),'description'),'JSON null nao limpou descricao.'); pass;

    start_test('PATCH vazio retorna 422');
    l_request:=patch_body(NULL,NULL); invoke_update(l_store_public_id,l_request,l_account_id); free_clob(l_request);
    assert_error(422,'BEX-STORE-012'); pass;

    start_test('PATCH bem sucedido executa COMMIT');
    l_request:=patch_body('description','Committed'); invoke_update(l_store_public_id,l_request,l_account_id); free_clob(l_request);
    ROLLBACK; SELECT COUNT(*) INTO l_count FROM BEX_STORE WHERE STR_PUBLIC_ID=l_store_public_id AND STR_DESCRIPTION='Committed';
    assert_true(l_count=1,'PATCH nao foi confirmado.'); pass;

    start_test('Falha de PATCH executa ROLLBACK');
    l_request:=patch_body('storeName','x'); invoke_update(l_store_public_id,l_request,l_account_id); free_clob(l_request);
    SELECT COUNT(*) INTO l_count FROM BEX_STORE WHERE STR_PUBLIC_ID=l_store_public_id AND STR_NAME='Updated API';
    assert_true(l_status=422 AND l_count=1,'Falha alterou STORE.'); pass;

    start_test('Body NULL retorna 400'); invoke_update(l_store_public_id,NULL,l_account_id); assert_error(400,'BEX-REQ-001'); pass;
    start_test('JSON invalido retorna 400'); invoke_update(l_store_public_id,'{',l_account_id); assert_error(400,'BEX-REQ-002'); pass;
    start_test('Raiz nao objeto retorna 400'); invoke_update(l_store_public_id,'[]',l_account_id); assert_error(400,'BEX-REQ-003'); pass;

    start_test('Campo desconhecido retorna 400');
    l_request:=create_body('Unknown','unknown-'||l_token,TRUE); invoke_create(l_account_public_id,l_request,l_account_id); free_clob(l_request);
    assert_error(400,'BEX-REQ-006'); pass;

    start_test('Ator ausente retorna 400'); invoke_get(l_store_public_id,NULL); assert_error(400,'BEX-REQ-004'); pass;
    start_test('STORE inexistente retorna 404'); invoke_get(LOWER(RAWTOHEX(SYS_GUID())),l_account_id); assert_error(404,'BEX-STORE-017'); pass;
    start_test('ACCOUNT inexistente retorna 404'); invoke_list(LOWER(RAWTOHEX(SYS_GUID())),l_account_id); assert_error(404,'BEX-STORE-018'); pass;

    start_test('ACCOUNT inelegivel retorna 422');
    l_request:=create_body('Blocked','blocked-'||l_token); invoke_create(l_blocked_account_public_id,l_request,l_account_id); free_clob(l_request);
    assert_error(422,'BEX-STORE-015'); pass;

    start_test('Nome invalido retorna 422');
    l_request:=create_body('x','invalid-name-'||l_token); invoke_create(l_account_public_id,l_request,l_account_id); free_clob(l_request);
    assert_error(422,'BEX-STORE-002'); pass;

    start_test('Opcionais e dados regionais invalidos retornam 422');
    l_request:=full_create_body('bad-logo-'||l_token,'ftp://invalid',NULL,'pt-BR','America/Sao_Paulo');
    invoke_create(l_account_public_id,l_request,l_account_id); free_clob(l_request); assert_error(422,'BEX-STORE-006');
    l_request:=full_create_body('bad-cover-'||l_token,NULL,'cover.invalid','pt-BR','America/Sao_Paulo');
    invoke_create(l_account_public_id,l_request,l_account_id); free_clob(l_request); assert_error(422,'BEX-STORE-007');
    l_request:=full_create_body('bad-locale-'||l_token,NULL,NULL,'en-US','America/Sao_Paulo');
    invoke_create(l_account_public_id,l_request,l_account_id); free_clob(l_request); assert_error(422,'BEX-STORE-008');
    l_request:=full_create_body('bad-timezone-'||l_token,NULL,NULL,'pt-BR','UTC');
    invoke_create(l_account_public_id,l_request,l_account_id); free_clob(l_request); assert_error(422,'BEX-STORE-009');
    pass;

    start_test('Slug invalido retorna 422');
    l_request:=create_body('Invalid Slug','!!!'); invoke_create(l_account_public_id,l_request,l_account_id); free_clob(l_request);
    assert_error(422,'BEX-STORE-003'); pass;

    start_test('Slug duplicado retorna 409');
    l_request:=create_body('Duplicate',l_store_slug); invoke_create(l_other_account_public_id,l_request,l_other_account_id); free_clob(l_request);
    assert_error(409,'BEX-STORE-016'); pass;

    start_test('Slug ocupado na atualizacao retorna 409');
    l_request:=patch_body('storeSlug','other-api-'||l_token); invoke_update(l_store_public_id,l_request,l_account_id); free_clob(l_request);
    assert_error(409,'BEX-STORE-016'); pass;

    start_test('Ativacao retorna ACTIVE e confirma transacao');
    invoke_activate(l_store_public_id,l_account_id); parse_response;
    assert_true(l_status=200 AND l_envelope.get_object('data').get_string('status')='ACTIVE','Ativacao incorreta.');
    ROLLBACK; SELECT COUNT(*) INTO l_count FROM BEX_STORE WHERE STR_PUBLIC_ID=l_store_public_id AND STR_STATUS='ACTIVE';
    assert_true(l_count=1,'Ativacao nao confirmada.'); pass;

    start_test('Slug nao editavel retorna 409');
    l_request:=patch_body('storeSlug','active-new-'||l_token); invoke_update(l_store_public_id,l_request,l_account_id); free_clob(l_request);
    assert_error(409,'BEX-STORE-013'); pass;

    start_test('Fechamento retorna CLOSED e confirma transacao');
    invoke_close(l_store_public_id,l_account_id); parse_response;
    assert_true(l_status=200 AND l_envelope.get_object('data').get_string('status')='CLOSED','Fechamento incorreto.'); pass;

    start_test('STORE fechada retorna 409 no PATCH');
    l_request:=patch_body('storeName','Closed Update'); invoke_update(l_store_public_id,l_request,l_account_id); free_clob(l_request);
    assert_error(409,'BEX-STORE-014'); pass;

    start_test('Transicao invalida retorna 409'); invoke_activate(l_store_public_id,l_account_id); assert_error(409,'BEX-STORE-011'); pass;

    start_test('Disponibilidade de slug livre retorna true');
    invoke_available('free-'||l_token,l_account_id); parse_response;
    assert_true(l_status=200 AND l_envelope.get_object('data').get_boolean('available'),'Slug livre incorreto.'); pass;

    start_test('Disponibilidade de slug ocupado retorna false');
    invoke_available(l_store_slug,l_account_id); parse_response;
    assert_false(l_envelope.get_object('data').get_boolean('available'),'Slug ocupado incorreto.'); pass;

    start_test('API nao conhece dependencias internas do Service');
    SELECT COUNT(*) INTO l_source_count FROM USER_SOURCE WHERE NAME='STR_API_PKG' AND TYPE='PACKAGE BODY'
      AND REGEXP_LIKE(UPPER(TEXT),'STR_(RULE|REPOSITORY)_PKG|ACC_SERVICE_PKG');
    assert_true(l_source_count=0,'API conhece dependencia interna.'); pass;

    start_test('API nao contem SQL ou IDs internos');
    SELECT COUNT(*) INTO l_source_count FROM USER_SOURCE WHERE NAME='STR_API_PKG' AND TYPE IN ('PACKAGE','PACKAGE BODY')
      AND REGEXP_LIKE(UPPER(TEXT),'(^|[^A-Z_])(SELECT|INSERT|UPDATE|DELETE|MERGE)([^A-Z_]|$)|STR_ID|ACC_ID|CREATED_BY|UPDATED_BY|SQLERRM');
    assert_true(l_source_count=0,'API possui SQL ou detalhe interno.'); pass;

    start_test('API chama somente STR_SERVICE_PKG');
    SELECT COUNT(*) INTO l_source_count FROM USER_DEPENDENCIES WHERE NAME='STR_API_PKG'
      AND REFERENCED_NAME IN ('STR_RULE_PKG','STR_REPOSITORY_PKG','ACC_SERVICE_PKG','BEX_STORE','BEX_ACCOUNT');
    assert_true(l_source_count=0,'Dependencia proibida encontrada.'); pass;
  END;
BEGIN
  l_token:=LOWER(SUBSTR(RAWTOHEX(SYS_GUID()),1,12));
  create_account('ACTIVE',l_account_id,l_account_public_id);
  create_account('ACTIVE',l_other_account_id,l_other_account_public_id);
  create_account('ACTIVE',l_empty_account_id,l_empty_account_public_id);
  create_account('BLOCKED',l_blocked_account_id,l_blocked_account_public_id);
  COMMIT;
  run_tests;
  IF g_test_count<>c_expected_test_count THEN fail('Quantidade invalida. Esperado='||c_expected_test_count||' executado='||g_test_count); END IF;
  free_clob(l_request); free_clob(l_response); clear_context; cleanup;
  DBMS_OUTPUT.PUT_LINE('STR_API_PKG: PASSED');
EXCEPTION WHEN OTHERS THEN
  free_clob(l_request); free_clob(l_response); clear_context; cleanup;
  DBMS_OUTPUT.PUT_LINE('FAIL - '||NVL(g_current_test,'initialization')); RAISE;
END;
/
