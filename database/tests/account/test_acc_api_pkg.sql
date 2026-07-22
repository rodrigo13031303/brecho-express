SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  g_test_count   PLS_INTEGER := 0;
  g_current_test VARCHAR2(200);
  g_trace_id     core_trace_pkg.t_trace_id;

  c_expected_test_count CONSTANT PLS_INTEGER := 35;
  c_password            CONSTANT VARCHAR2(128) := 'ValidPassword123';

  l_email         VARCHAR2(255);
  l_second_email  VARCHAR2(255);
  l_no_context_email VARCHAR2(255);
  l_request_body  CLOB;
  l_response_body CLOB;
  l_status_code   PLS_INTEGER;
  l_envelope      JSON_OBJECT_T;
  l_data          JSON_OBJECT_T;
  l_error         JSON_OBJECT_T;
  l_account_id    BEX_ACCOUNT.ACC_ID%TYPE;
  l_count         PLS_INTEGER;
  l_source_count  PLS_INTEGER;

  PROCEDURE fail(
    p_message IN VARCHAR2
  ) IS
  BEGIN
    RAISE_APPLICATION_ERROR(-20999, p_message);
  END fail;

  PROCEDURE assert_true(
    p_condition IN BOOLEAN,
    p_message   IN VARCHAR2
  ) IS
  BEGIN
    IF p_condition IS NULL OR NOT p_condition THEN
      fail(p_message);
    END IF;
  END assert_true;

  PROCEDURE assert_false(
    p_condition IN BOOLEAN,
    p_message   IN VARCHAR2
  ) IS
  BEGIN
    IF p_condition IS NULL OR p_condition THEN
      fail(p_message);
    END IF;
  END assert_false;

  PROCEDURE start_test(
    p_test_name IN VARCHAR2
  ) IS
  BEGIN
    g_current_test := p_test_name;
  END start_test;

  PROCEDURE pass IS
  BEGIN
    g_test_count := g_test_count + 1;
    DBMS_OUTPUT.PUT_LINE(
      'PASS ' || LPAD(g_test_count, 2, '0') || ' - ' || g_current_test
    );
  END pass;

  PROCEDURE free_temporary_clob(
    io_value IN OUT NOCOPY CLOB
  ) IS
  BEGIN
    IF io_value IS NOT NULL
       AND DBMS_LOB.ISTEMPORARY(io_value) = 1 THEN
      DBMS_LOB.FREETEMPORARY(io_value);
    END IF;

    io_value := NULL;
  END free_temporary_clob;

  PROCEDURE clear_context IS
  BEGIN
    core_security_context_pkg.clear;
    core_context_pkg.clear;
    core_trace_pkg.clear;
  END clear_context;

  PROCEDURE initialize_anonymous_context IS
  BEGIN
    clear_context;
    core_trace_pkg.initialize;
    g_trace_id := core_trace_pkg.current_trace_id;

    core_context_pkg.initialize(
      p_execution_origin => core_context_pkg.c_origin_external,
      p_execution_mode   => core_context_pkg.c_mode_synchronous,
      p_actor_public_id  => NULL,
      p_authenticated    => FALSE
    );

    core_security_context_pkg.initialize(
      p_actor_type =>
        core_security_context_pkg.c_actor_type_anonymous,
      p_authentication_method =>
        core_security_context_pkg.c_authentication_method_none
    );
  END initialize_anonymous_context;

  FUNCTION build_request(
    p_email       IN VARCHAR2,
    p_password    IN VARCHAR2,
    p_unknown_key IN VARCHAR2 DEFAULT NULL
  ) RETURN CLOB IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
  BEGIN
    core_json_pkg.put_string(l_object, 'email', p_email);
    core_json_pkg.put_string(l_object, 'password', p_password);

    IF p_unknown_key IS NOT NULL THEN
      core_json_pkg.put_string(l_object, p_unknown_key, 'unexpected');
    END IF;

    RETURN core_json_pkg.serialize(l_object);
  END build_request;

  PROCEDURE invoke_create(
    p_request_body IN CLOB
  ) IS
  BEGIN
    free_temporary_clob(l_response_body);
    initialize_anonymous_context;

    BEGIN
      acc_api_pkg.create_account(
        p_request_body  => p_request_body,
        o_status_code   => l_status_code,
        o_response_body => l_response_body
      );
      clear_context;
    EXCEPTION
      WHEN OTHERS THEN
        clear_context;
        RAISE;
    END;
  END invoke_create;

  PROCEDURE parse_response IS
  BEGIN
    l_envelope := JSON_OBJECT_T.parse(l_response_body);
  END parse_response;

  PROCEDURE assert_error(
    p_status_code IN PLS_INTEGER,
    p_code        IN VARCHAR2,
    p_category    IN VARCHAR2,
    p_message     IN VARCHAR2
  ) IS
  BEGIN
    assert_true(
      l_status_code = p_status_code,
      'Status HTTP inesperado.'
    );
    assert_true(l_response_body IS NOT NULL, 'Body de erro ausente.');

    parse_response;
    l_error := l_envelope.get_object('error');

    assert_false(l_envelope.get_boolean('success'), 'Erro retornou sucesso.');
    assert_true(l_envelope.has('traceId'), 'Erro nao possui traceId.');
    assert_true(l_error.get_string('code') = p_code, 'Codigo incorreto.');
    assert_true(
      l_error.get_string('category') = p_category,
      'Categoria incorreta.'
    );
    assert_true(l_error.get_string('message') = p_message, 'Mensagem incorreta.');
    assert_false(l_error.get_boolean('retryable'), 'Erro nao deveria ser retryable.');
  END assert_error;

  PROCEDURE cleanup IS
  BEGIN
    DELETE FROM BEX_ACCOUNT
     WHERE ACC_EMAIL IN (l_email, l_second_email, l_no_context_email);
    COMMIT;
  END cleanup;

  PROCEDURE run_tests IS
  BEGIN
    l_request_body := build_request(
      '  ' || UPPER(l_email) || '  ',
      c_password
    );
    invoke_create(l_request_body);
    free_temporary_clob(l_request_body);

    start_test('CREATE_ACCOUNT retorna status 201');
    assert_true(l_status_code = 201, 'Status de criacao deveria ser 201.');
    pass;

    start_test('CREATE_ACCOUNT retorna JSON valido');
    parse_response;
    assert_true(l_envelope IS NOT NULL, 'Envelope JSON nao foi produzido.');
    pass;

    start_test('envelope de criacao indica sucesso');
    assert_true(l_envelope.get_boolean('success'), 'Envelope deveria indicar sucesso.');
    pass;

    start_test('envelope preserva traceId do contexto');
    assert_true(
      l_envelope.get_string('traceId') = g_trace_id,
      'TraceId da resposta diverge do contexto.'
    );
    pass;

    start_test('envelope de criacao possui data');
    l_data := l_envelope.get_object('data');
    assert_true(
      l_data IS NOT NULL
      AND NOT l_envelope.has('error')
      AND NOT l_envelope.has('meta')
      AND NOT l_envelope.has('httpStatus'),
      'Envelope de sucesso possui estrutura incorreta.'
    );
    pass;

    start_test('payload retorna publicId valido');
    assert_true(
      LENGTH(l_data.get_string('publicId')) = 32
      AND REGEXP_LIKE(l_data.get_string('publicId'), '^[0-9a-f]{32}$', 'c'),
      'Public ID invalido.'
    );
    pass;

    start_test('payload retorna email normalizado');
    assert_true(l_data.get_string('email') = l_email, 'Email nao foi normalizado.');
    pass;

    start_test('payload retorna status inicial');
    assert_true(
      l_data.get_string('status') = 'PENDING_EMAIL_VERIFICATION',
      'Status inicial incorreto.'
    );
    pass;

    start_test('payload retorna timestamps ISO');
    assert_true(
      REGEXP_LIKE(
        l_data.get_string('createdAt'),
        '^[0-9]{4}-[0-9]{2}-[0-9]{2}T'
      )
      AND REGEXP_LIKE(
        l_data.get_string('updatedAt'),
        '^[0-9]{4}-[0-9]{2}-[0-9]{2}T'
      ),
      'Timestamps nao seguem ISO-8601.'
    );
    pass;

    start_test('payload representa email nao verificado como null');
    assert_true(
      l_data.has('emailVerifiedAt')
      AND l_data.get('emailVerifiedAt').is_null,
      'emailVerifiedAt deveria ser JSON null.'
    );
    pass;

    start_test('payload nao expoe ID tecnico');
    assert_false(
      l_data.has('accountId')
      OR l_data.has('accId')
      OR l_data.has('createdBy')
      OR l_data.has('updatedBy'),
      'Payload expos identificador ou auditoria tecnica.'
    );
    pass;

    start_test('payload nao expoe senha ou credencial');
    assert_false(
      l_data.has('password')
      OR l_data.has('passwordHash')
      OR l_data.has('credential'),
      'Payload expos informacao de credencial.'
    );
    pass;

    start_test('CREATE_ACCOUNT persiste a conta');
    SELECT COUNT(*), MAX(ACC_ID)
      INTO l_count, l_account_id
      FROM BEX_ACCOUNT
     WHERE ACC_EMAIL = l_email;
    assert_true(l_count = 1 AND l_account_id IS NOT NULL, 'Conta nao foi persistida.');
    pass;

    start_test('CREATE_ACCOUNT confirma a transacao');
    ROLLBACK;
    SELECT COUNT(*)
      INTO l_count
      FROM BEX_ACCOUNT
     WHERE ACC_EMAIL = l_email;
    assert_true(l_count = 1, 'Conta nao permaneceu apos ROLLBACK do chamador.');
    pass;

    start_test('body NULL retorna request obrigatorio');
    invoke_create(NULL);
    assert_error(400, 'BEX-REQ-001', 'VALIDATION_ERROR', 'O corpo da requisicao e obrigatorio.');
    pass;

    start_test('body vazio retorna request obrigatorio');
    invoke_create(TO_CLOB(''));
    assert_error(400, 'BEX-REQ-001', 'VALIDATION_ERROR', 'O corpo da requisicao e obrigatorio.');
    pass;

    start_test('body com espacos retorna request obrigatorio');
    invoke_create(TO_CLOB('  ' || CHR(10) || CHR(9)));
    assert_error(400, 'BEX-REQ-001', 'VALIDATION_ERROR', 'O corpo da requisicao e obrigatorio.');
    pass;

    start_test('JSON malformado retorna erro estrutural');
    invoke_create(TO_CLOB('{"email":'));
    assert_error(400, 'BEX-REQ-002', 'VALIDATION_ERROR', 'O corpo da requisicao nao contem JSON valido.');
    pass;

    start_test('raiz array retorna tipo raiz invalido');
    invoke_create(TO_CLOB('["value"]'));
    assert_error(400, 'BEX-REQ-003', 'VALIDATION_ERROR', 'O corpo da requisicao deve ser um objeto JSON.');
    pass;

    start_test('email ausente retorna campo obrigatorio');
    invoke_create(TO_CLOB('{"password":"ValidPassword123"}'));
    assert_error(400, 'BEX-REQ-004', 'VALIDATION_ERROR', 'Um campo obrigatorio nao foi informado.');
    pass;

    start_test('senha ausente retorna campo obrigatorio');
    invoke_create(TO_CLOB('{"email":"missing.password@example.invalid"}'));
    assert_error(400, 'BEX-REQ-004', 'VALIDATION_ERROR', 'Um campo obrigatorio nao foi informado.');
    pass;

    start_test('email null retorna campo obrigatorio');
    invoke_create(TO_CLOB('{"email":null,"password":"ValidPassword123"}'));
    assert_error(400, 'BEX-REQ-004', 'VALIDATION_ERROR', 'Um campo obrigatorio nao foi informado.');
    pass;

    start_test('senha null retorna campo obrigatorio');
    invoke_create(TO_CLOB('{"email":"null.password@example.invalid","password":null}'));
    assert_error(400, 'BEX-REQ-004', 'VALIDATION_ERROR', 'Um campo obrigatorio nao foi informado.');
    pass;

    start_test('email numerico retorna tipo invalido');
    invoke_create(TO_CLOB('{"email":123,"password":"ValidPassword123"}'));
    assert_error(400, 'BEX-REQ-005', 'VALIDATION_ERROR', 'Um campo possui tipo invalido.');
    pass;

    start_test('senha booleana retorna tipo invalido');
    invoke_create(TO_CLOB('{"email":"typed@example.invalid","password":true}'));
    assert_error(400, 'BEX-REQ-005', 'VALIDATION_ERROR', 'Um campo possui tipo invalido.');
    pass;

    start_test('campo desconhecido e rejeitado');
    l_request_body := build_request(
      'unknown.field@example.invalid',
      c_password,
      'createdBy'
    );
    invoke_create(l_request_body);
    free_temporary_clob(l_request_body);
    assert_error(400, 'BEX-REQ-006', 'VALIDATION_ERROR', 'A requisicao contem campo desconhecido.');
    pass;

    start_test('email invalido retorna erro funcional');
    l_request_body := build_request('invalid-email', c_password);
    invoke_create(l_request_body);
    free_temporary_clob(l_request_body);
    assert_error(422, 'BEX-ACC-003', 'VALIDATION_ERROR', 'O email informado e invalido.');
    pass;

    start_test('senha invalida retorna erro funcional');
    l_request_body := build_request(
      'invalid.password@example.invalid',
      'short'
    );
    invoke_create(l_request_body);
    free_temporary_clob(l_request_body);
    assert_error(422, 'BEX-ACC-005', 'VALIDATION_ERROR', 'A senha informada e invalida.');
    pass;

    start_test('email duplicado retorna conflito');
    l_request_body := build_request(l_email, c_password);
    invoke_create(l_request_body);
    free_temporary_clob(l_request_body);
    assert_error(409, 'BEX-ACC-004', 'CONFLICT_ERROR', 'O email informado ja esta em uso.');
    pass;

    start_test('falha de validacao nao persiste conta');
    SELECT COUNT(*)
      INTO l_count
      FROM BEX_ACCOUNT
     WHERE ACC_EMAIL = 'invalid-email';
    assert_true(l_count = 0, 'Validacao deixou persistencia parcial.');
    pass;

    start_test('falha de envelope sem contexto executa rollback seguro');
    clear_context;
    free_temporary_clob(l_response_body);
    l_request_body := build_request(l_no_context_email, c_password);
    acc_api_pkg.create_account(
      l_request_body,
      l_status_code,
      l_response_body
    );
    free_temporary_clob(l_request_body);
    SELECT COUNT(*)
      INTO l_count
      FROM BEX_ACCOUNT
     WHERE ACC_EMAIL = l_no_context_email;
    assert_true(
      l_status_code = 500
      AND l_response_body IS NULL
      AND l_count = 0,
      'Fallback sem contexto nao preservou status e rollback seguros.'
    );
    pass;

    start_test('respostas de erro nao vazam detalhes tecnicos');
    l_request_body := build_request(l_email, c_password);
    invoke_create(l_request_body);
    free_temporary_clob(l_request_body);
    assert_false(
      REGEXP_LIKE(
        DBMS_LOB.SUBSTR(l_response_body, 32767, 1),
        'ORA-|PL/SQL|BEX_ACCOUNT|ACC_SERVICE_PKG|ACC_REPOSITORY_PKG|stack|backtrace',
        'i'
      ),
      'Resposta vazou detalhe tecnico.'
    );
    pass;

    start_test('API nao possui SQL nem dependencia de Repository');
    SELECT COUNT(*)
      INTO l_source_count
      FROM USER_SOURCE
     WHERE NAME = 'ACC_API_PKG'
       AND TYPE = 'PACKAGE BODY'
       AND (
         REGEXP_LIKE(
           UPPER(TEXT),
           '(^|[^A-Z_])(SELECT|INSERT|UPDATE|DELETE|MERGE|EXECUTE[[:space:]]+IMMEDIATE)([^A-Z_]|$)'
         )
         OR INSTR(UPPER(TEXT), 'ACC_REPOSITORY_PKG') > 0
       );
    assert_true(l_source_count = 0, 'API possui SQL ou dependencia de Repository.');
    pass;

    start_test('API nao chama Rule nem controla lifecycle do Core');
    SELECT COUNT(*)
      INTO l_source_count
      FROM USER_SOURCE
     WHERE NAME = 'ACC_API_PKG'
       AND TYPE = 'PACKAGE BODY'
       AND (
         (INSTR(UPPER(TEXT), 'ACC_RULE_PKG.') > 0
          AND INSTR(UPPER(TEXT), 'ACC_RULE_PKG.E_') = 0)
         OR REGEXP_LIKE(
              UPPER(TEXT),
              'CORE_[A-Z_]+_PKG[.](INITIALIZE|CLEAR)'
            )
       );
    assert_true(l_source_count = 0, 'API chamou Rule ou controlou lifecycle.');
    pass;

    start_test('API nao usa SQL dinamico nem concatenacao JSON');
    SELECT COUNT(*)
      INTO l_source_count
      FROM USER_SOURCE
     WHERE NAME = 'ACC_API_PKG'
       AND TYPE = 'PACKAGE BODY'
       AND (
         INSTR(UPPER(TEXT), 'EXECUTE IMMEDIATE') > 0
         OR INSTR(TEXT, '||') > 0
         OR REGEXP_LIKE(UPPER(TEXT), 'WHEN[[:space:]]+OTHERS[[:space:]]+THEN[[:space:]]+NULL')
       );
    assert_true(l_source_count = 0, 'API possui construcao ou tratamento proibido.');
    pass;
  END run_tests;
BEGIN
  l_email := 'acc.api.' || LOWER(RAWTOHEX(SYS_GUID())) || '@example.invalid';
  l_second_email := 'acc.api.second.' || LOWER(RAWTOHEX(SYS_GUID())) || '@example.invalid';
  l_no_context_email := 'acc.api.context.' || LOWER(RAWTOHEX(SYS_GUID())) || '@example.invalid';

  cleanup;
  run_tests;

  IF g_test_count <> c_expected_test_count THEN
    fail(
      'Quantidade de testes invalida. Esperado=' || c_expected_test_count
      || ', executado=' || g_test_count
    );
  END IF;

  free_temporary_clob(l_request_body);
  free_temporary_clob(l_response_body);
  clear_context;
  cleanup;
  DBMS_OUTPUT.PUT_LINE('ACC_API_PKG: PASSED');
EXCEPTION
  WHEN OTHERS THEN
    free_temporary_clob(l_request_body);
    free_temporary_clob(l_response_body);
    clear_context;
    cleanup;
    DBMS_OUTPUT.PUT_LINE(
      'FAIL - ' || NVL(g_current_test, 'initialization')
    );
    RAISE;
END;
/
