SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  g_test_count   PLS_INTEGER := 0;
  g_current_test VARCHAR2(200);
  g_trace_id     core_trace_pkg.t_trace_id;

  c_expected_test_count CONSTANT PLS_INTEGER := 44;

  l_account_id               BEX_ACCOUNT.ACC_ID%TYPE;
  l_account_public_id        BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE;
  l_second_account_id        BEX_ACCOUNT.ACC_ID%TYPE;
  l_second_account_public_id BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE;
  l_profile_public_id        BEX_PROFILE.PFL_PUBLIC_ID%TYPE;
  l_request_body             CLOB;
  l_response_body            CLOB;
  l_status_code              PLS_INTEGER;
  l_envelope                 JSON_OBJECT_T;
  l_data                     JSON_OBJECT_T;
  l_error                    JSON_OBJECT_T;
  l_profile_before           BEX_PROFILE%ROWTYPE;
  l_profile_after            BEX_PROFILE%ROWTYPE;
  l_count                    PLS_INTEGER;
  l_source_count             PLS_INTEGER;

  PROCEDURE fail(p_message IN VARCHAR2) IS
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

  PROCEDURE start_test(p_test_name IN VARCHAR2) IS
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

  PROCEDURE initialize_context IS
  BEGIN
    clear_context;
    core_trace_pkg.initialize;
    g_trace_id := core_trace_pkg.current_trace_id;
    core_context_pkg.initialize(
      p_execution_origin => core_context_pkg.c_origin_external,
      p_execution_mode   => core_context_pkg.c_mode_synchronous,
      p_actor_public_id  => l_account_public_id,
      p_authenticated    => TRUE
    );
    core_security_context_pkg.initialize(
      p_actor_type => core_security_context_pkg.c_actor_type_user,
      p_authentication_method =>
        core_security_context_pkg.c_authentication_method_session
    );
  END initialize_context;

  PROCEDURE create_account_fixture(
    o_account_id        OUT BEX_ACCOUNT.ACC_ID%TYPE,
    o_account_public_id OUT BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE
  ) IS
    l_value   VARCHAR2(32);
    l_email   VARCHAR2(255);
    l_account BEX_ACCOUNT%ROWTYPE;
  BEGIN
    l_value := LOWER(RAWTOHEX(SYS_GUID()));
    l_email := 'profile.api.' || SUBSTR(l_value, 1, 20)
               || '@example.invalid';
    acc_repository_pkg.insert_account(
      p_public_id => l_value,
      p_email => l_email,
      p_email_verified_at => NULL,
      p_credential => 'profile-api-test-credential',
      p_password_changed_at => SYSTIMESTAMP,
      p_status => 'ACTIVE',
      p_last_login_at => NULL,
      p_created_by => NULL,
      p_updated_by => NULL
    );
    l_account := acc_repository_pkg.get_by_email(l_email);
    o_account_id := l_account.ACC_ID;
    o_account_public_id := l_account.ACC_PUBLIC_ID;
  END create_account_fixture;

  FUNCTION build_request(
    p_display_name  IN VARCHAR2,
    p_full_name     IN VARCHAR2 DEFAULT NULL,
    p_birth_date    IN VARCHAR2 DEFAULT NULL,
    p_locale_code   IN VARCHAR2 DEFAULT 'pt-BR',
    p_timezone_name IN VARCHAR2 DEFAULT 'America/Sao_Paulo',
    p_unknown_field IN BOOLEAN DEFAULT FALSE
  ) RETURN CLOB IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
  BEGIN
    core_json_pkg.put_string(l_object, 'displayName', p_display_name);
    IF p_full_name IS NULL THEN core_json_pkg.put_null(l_object, 'fullName');
    ELSE core_json_pkg.put_string(l_object, 'fullName', p_full_name); END IF;
    IF p_birth_date IS NULL THEN core_json_pkg.put_null(l_object, 'birthDate');
    ELSE core_json_pkg.put_string(l_object, 'birthDate', p_birth_date); END IF;
    core_json_pkg.put_string(l_object, 'bio', 'Profile API biography');
    core_json_pkg.put_string(
      l_object,
      'avatarUrl',
      'https://example.invalid/profile-api.png'
    );
    core_json_pkg.put_string(l_object, 'localeCode', p_locale_code);
    core_json_pkg.put_string(l_object, 'timezoneName', p_timezone_name);
    IF p_unknown_field THEN
      core_json_pkg.put_string(l_object, 'accountId', 'forbidden');
    END IF;
    RETURN core_json_pkg.serialize(l_object);
  END build_request;

  FUNCTION build_patch_request(
    p_field_name IN VARCHAR2 DEFAULT NULL,
    p_value      IN VARCHAR2 DEFAULT NULL,
    p_json_null  IN BOOLEAN DEFAULT FALSE
  ) RETURN CLOB IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
  BEGIN
    IF p_field_name IS NOT NULL THEN
      IF p_json_null THEN
        core_json_pkg.put_null(l_object, p_field_name);
      ELSE
        core_json_pkg.put_string(l_object, p_field_name, p_value);
      END IF;
    END IF;

    RETURN core_json_pkg.serialize(l_object);
  END build_patch_request;

  PROCEDURE parse_response IS
  BEGIN
    l_envelope := JSON_OBJECT_T.parse(l_response_body);
  END parse_response;

  PROCEDURE assert_error(
    p_status_code IN PLS_INTEGER,
    p_code        IN VARCHAR2
  ) IS
  BEGIN
    assert_true(l_status_code = p_status_code, 'Status HTTP inesperado.');
    assert_true(l_response_body IS NOT NULL, 'Body de erro ausente.');
    parse_response;
    l_error := l_envelope.get_object('error');
    assert_false(l_envelope.get_boolean('success'), 'Erro retornou sucesso.');
    assert_true(l_envelope.has('traceId'), 'Erro nao possui traceId.');
    assert_true(l_error.get_string('code') = p_code, 'Codigo incorreto.');
  END assert_error;

  PROCEDURE invoke_create(
    p_account_public_id IN VARCHAR2,
    p_request_body      IN CLOB,
    p_actor_id          IN NUMBER
  ) IS
  BEGIN
    free_temporary_clob(l_response_body);
    initialize_context;
    pfl_api_pkg.create_profile(
      p_account_public_id,
      p_request_body,
      p_actor_id,
      l_status_code,
      l_response_body
    );
    clear_context;
  END invoke_create;

  PROCEDURE invoke_get_profile(
    p_public_id IN VARCHAR2,
    p_actor_id  IN NUMBER
  ) IS
  BEGIN
    free_temporary_clob(l_response_body);
    initialize_context;
    pfl_api_pkg.get_profile(
      p_public_id,
      p_actor_id,
      l_status_code,
      l_response_body
    );
    clear_context;
  END invoke_get_profile;

  PROCEDURE invoke_get_by_account(
    p_public_id IN VARCHAR2,
    p_actor_id  IN NUMBER
  ) IS
  BEGIN
    free_temporary_clob(l_response_body);
    initialize_context;
    pfl_api_pkg.get_profile_by_account(
      p_public_id,
      p_actor_id,
      l_status_code,
      l_response_body
    );
    clear_context;
  END invoke_get_by_account;

  PROCEDURE invoke_update(
    p_profile_public_id IN VARCHAR2,
    p_request_body      IN CLOB,
    p_actor_id          IN NUMBER
  ) IS
  BEGIN
    free_temporary_clob(l_response_body);
    initialize_context;
    pfl_api_pkg.update_profile(
      p_profile_public_id,
      p_request_body,
      p_actor_id,
      l_status_code,
      l_response_body
    );
    clear_context;
  END invoke_update;

  PROCEDURE cleanup IS
  BEGIN
    DELETE FROM BEX_PROFILE
     WHERE ACC_ID IN (l_account_id, l_second_account_id);
    DELETE FROM BEX_ACCOUNT
     WHERE ACC_ID IN (l_account_id, l_second_account_id);
    COMMIT;
  END cleanup;

  PROCEDURE run_tests IS
  BEGIN
    l_request_body := build_request(
      '  Profile    API  ',
      '  Profile    API Full Name  ',
      '1990-05-10'
    );
    invoke_create(l_account_public_id, l_request_body, l_account_id);
    free_temporary_clob(l_request_body);

    start_test('CREATE_PROFILE retorna status 201');
    assert_true(l_status_code = 201, 'Status de criacao incorreto.');
    pass;

    start_test('CREATE_PROFILE retorna envelope oficial');
    parse_response;
    assert_true(
      l_envelope.get_boolean('success')
      AND l_envelope.get_string('traceId') = g_trace_id
      AND l_envelope.has('data'),
      'Envelope de criacao incorreto.'
    );
    pass;

    start_test('payload retorna campos publicos do PROFILE');
    l_data := l_envelope.get_object('data');
    l_profile_public_id := l_data.get_string('profilePublicId');
    assert_true(
      LENGTH(l_profile_public_id) = 32
      AND l_data.get_string('displayName') = 'Profile API'
      AND l_data.get_string('fullName') = 'Profile API Full Name'
      AND l_data.get_string('birthDate') = '1990-05-10',
      'Payload publico incorreto.'
    );
    pass;

    start_test('payload nao expoe identificadores internos');
    assert_false(
      l_data.has('profileId') OR l_data.has('pflId')
      OR l_data.has('accountId') OR l_data.has('accId'),
      'Payload expos identificador interno.'
    );
    pass;

    start_test('payload nao expoe auditoria tecnica');
    assert_false(
      l_data.has('createdBy') OR l_data.has('updatedBy'),
      'Payload expos auditoria tecnica.'
    );
    pass;

    start_test('CREATE_PROFILE confirma transacao');
    ROLLBACK;
    SELECT COUNT(*) INTO l_count FROM BEX_PROFILE
     WHERE PFL_PUBLIC_ID = l_profile_public_id;
    assert_true(l_count = 1, 'Criacao nao permaneceu apos ROLLBACK externo.');
    pass;

    start_test('GET_PROFILE retorna PROFILE por public ID');
    invoke_get_profile(l_profile_public_id, l_account_id);
    parse_response;
    l_data := l_envelope.get_object('data');
    assert_true(
      l_status_code = 200
      AND l_data.get_string('profilePublicId') = l_profile_public_id,
      'Consulta por profilePublicId incorreta.'
    );
    pass;

    start_test('GET_PROFILE_BY_ACCOUNT retorna PROFILE');
    invoke_get_by_account(l_account_public_id, l_account_id);
    parse_response;
    l_data := l_envelope.get_object('data');
    assert_true(
      l_status_code = 200
      AND l_data.get_string('profilePublicId') = l_profile_public_id,
      'Consulta por accountPublicId incorreta.'
    );
    pass;

    start_test('UPDATE_PROFILE retorna status 200');
    l_request_body := build_request(
      'Updated Profile',
      'Updated Full Name',
      '1991-06-11'
    );
    invoke_update(l_profile_public_id, l_request_body, l_account_id);
    free_temporary_clob(l_request_body);
    assert_true(l_status_code = 200, 'Status de atualizacao incorreto.');
    pass;

    start_test('UPDATE_PROFILE retorna dados atualizados');
    parse_response;
    l_data := l_envelope.get_object('data');
    assert_true(
      l_data.get_string('displayName') = 'Updated Profile'
      AND l_data.get_string('fullName') = 'Updated Full Name'
      AND l_data.get_string('birthDate') = '1991-06-11',
      'Payload atualizado incorreto.'
    );
    pass;

    start_test('UPDATE_PROFILE confirma transacao');
    ROLLBACK;
    SELECT COUNT(*) INTO l_count FROM BEX_PROFILE
     WHERE PFL_PUBLIC_ID = l_profile_public_id
       AND PFL_DISPLAY_NAME = 'Updated Profile';
    assert_true(l_count = 1, 'Atualizacao nao permaneceu apos ROLLBACK externo.');
    pass;

    start_test('GET_PROFILE exige ator');
    invoke_get_profile(l_profile_public_id, NULL);
    assert_error(400, 'BEX-REQ-004');
    pass;

    start_test('GET_PROFILE_BY_ACCOUNT exige ator');
    invoke_get_by_account(l_account_public_id, NULL);
    assert_error(400, 'BEX-REQ-004');
    pass;

    l_profile_before := pfl_repository_pkg.get_by_public_id(
      l_profile_public_id
    );

    start_test('PATCH somente de bio preserva demais campos');
    l_request_body := build_patch_request(
      'bio',
      'Biography changed by PATCH'
    );
    invoke_update(l_profile_public_id, l_request_body, l_account_id);
    free_temporary_clob(l_request_body);
    l_profile_after := pfl_repository_pkg.get_by_public_id(l_profile_public_id);
    assert_true(
      l_profile_after.PFL_BIO = 'Biography changed by PATCH'
      AND l_profile_after.PFL_DISPLAY_NAME = l_profile_before.PFL_DISPLAY_NAME
      AND l_profile_after.PFL_FULL_NAME = l_profile_before.PFL_FULL_NAME
      AND l_profile_after.PFL_BIRTH_DATE = l_profile_before.PFL_BIRTH_DATE
      AND l_profile_after.PFL_AVATAR_URL = l_profile_before.PFL_AVATAR_URL
      AND l_profile_after.PFL_LOCALE_CODE = l_profile_before.PFL_LOCALE_CODE
      AND l_profile_after.PFL_TIMEZONE_NAME = l_profile_before.PFL_TIMEZONE_NAME,
      'PATCH de bio alterou campos ausentes.'
    );
    pass;

    l_profile_before := l_profile_after;

    start_test('PATCH somente de avatarUrl preserva demais campos');
    l_request_body := build_patch_request(
      'avatarUrl',
      'https://example.invalid/patched-avatar.png'
    );
    invoke_update(l_profile_public_id, l_request_body, l_account_id);
    free_temporary_clob(l_request_body);
    l_profile_after := pfl_repository_pkg.get_by_public_id(l_profile_public_id);
    assert_true(
      l_profile_after.PFL_AVATAR_URL =
        'https://example.invalid/patched-avatar.png'
      AND l_profile_after.PFL_DISPLAY_NAME = l_profile_before.PFL_DISPLAY_NAME
      AND l_profile_after.PFL_FULL_NAME = l_profile_before.PFL_FULL_NAME
      AND l_profile_after.PFL_BIRTH_DATE = l_profile_before.PFL_BIRTH_DATE
      AND l_profile_after.PFL_BIO = l_profile_before.PFL_BIO
      AND l_profile_after.PFL_LOCALE_CODE = l_profile_before.PFL_LOCALE_CODE
      AND l_profile_after.PFL_TIMEZONE_NAME = l_profile_before.PFL_TIMEZONE_NAME,
      'PATCH de avatarUrl alterou campos ausentes.'
    );
    pass;

    start_test('campo opcional ausente nao vira NULL');
    assert_true(
      l_profile_after.PFL_FULL_NAME = 'Updated Full Name'
      AND l_profile_after.PFL_BIRTH_DATE = DATE '1991-06-11'
      AND l_profile_after.PFL_BIO = 'Biography changed by PATCH',
      'Campo opcional ausente foi limpo.'
    );
    pass;

    start_test('JSON null limpa bio');
    l_request_body := build_patch_request('bio', NULL, TRUE);
    invoke_update(l_profile_public_id, l_request_body, l_account_id);
    free_temporary_clob(l_request_body);
    l_profile_after := pfl_repository_pkg.get_by_public_id(l_profile_public_id);
    assert_true(l_profile_after.PFL_BIO IS NULL, 'BIO nao foi limpo.');
    pass;

    start_test('JSON null limpa avatarUrl');
    l_request_body := build_patch_request('avatarUrl', NULL, TRUE);
    invoke_update(l_profile_public_id, l_request_body, l_account_id);
    free_temporary_clob(l_request_body);
    l_profile_after := pfl_repository_pkg.get_by_public_id(l_profile_public_id);
    assert_true(l_profile_after.PFL_AVATAR_URL IS NULL, 'AVATAR_URL nao foi limpo.');
    pass;

    start_test('JSON null limpa fullName');
    l_request_body := build_patch_request('fullName', NULL, TRUE);
    invoke_update(l_profile_public_id, l_request_body, l_account_id);
    free_temporary_clob(l_request_body);
    l_profile_after := pfl_repository_pkg.get_by_public_id(l_profile_public_id);
    assert_true(l_profile_after.PFL_FULL_NAME IS NULL, 'FULL_NAME nao foi limpo.');
    pass;

    start_test('JSON null limpa birthDate');
    l_request_body := build_patch_request('birthDate', NULL, TRUE);
    invoke_update(l_profile_public_id, l_request_body, l_account_id);
    free_temporary_clob(l_request_body);
    l_profile_after := pfl_repository_pkg.get_by_public_id(l_profile_public_id);
    assert_true(l_profile_after.PFL_BIRTH_DATE IS NULL, 'BIRTH_DATE nao foi limpa.');
    pass;

    start_test('JSON null em displayName e rejeitado');
    l_request_body := build_patch_request('displayName', NULL, TRUE);
    invoke_update(l_profile_public_id, l_request_body, l_account_id);
    free_temporary_clob(l_request_body);
    assert_error(400, 'BEX-REQ-004');
    pass;

    start_test('JSON null em localeCode e rejeitado');
    l_request_body := build_patch_request('localeCode', NULL, TRUE);
    invoke_update(l_profile_public_id, l_request_body, l_account_id);
    free_temporary_clob(l_request_body);
    assert_error(400, 'BEX-REQ-004');
    pass;

    start_test('JSON null em timezoneName e rejeitado');
    l_request_body := build_patch_request('timezoneName', NULL, TRUE);
    invoke_update(l_profile_public_id, l_request_body, l_account_id);
    free_temporary_clob(l_request_body);
    assert_error(400, 'BEX-REQ-004');
    pass;

    start_test('PATCH com objeto vazio e rejeitado');
    l_request_body := build_patch_request;
    invoke_update(l_profile_public_id, l_request_body, l_account_id);
    free_temporary_clob(l_request_body);
    assert_error(400, 'BEX-REQ-004');
    pass;

    start_test('PATCH preserva profilePublicId');
    l_profile_after := pfl_repository_pkg.get_by_public_id(l_profile_public_id);
    assert_true(
      l_profile_after.PFL_PUBLIC_ID = l_profile_public_id,
      'PATCH alterou PFL_PUBLIC_ID.'
    );
    pass;

    start_test('PATCH preserva accountId interno');
    assert_true(
      l_profile_after.ACC_ID = l_account_id,
      'PATCH alterou ACC_ID.'
    );
    pass;

    start_test('PATCH executa COMMIT somente em sucesso');
    l_request_body := build_patch_request('bio', 'Committed PATCH');
    invoke_update(l_profile_public_id, l_request_body, l_account_id);
    free_temporary_clob(l_request_body);
    ROLLBACK;
    l_profile_after := pfl_repository_pkg.get_by_public_id(l_profile_public_id);
    assert_true(
      l_profile_after.PFL_BIO = 'Committed PATCH',
      'PATCH bem-sucedido nao confirmou a transacao.'
    );
    pass;

    start_test('PATCH executa ROLLBACK em erro');
    l_profile_before := l_profile_after;
    l_request_body := build_patch_request('displayName', 'x');
    invoke_update(l_profile_public_id, l_request_body, l_account_id);
    free_temporary_clob(l_request_body);
    l_profile_after := pfl_repository_pkg.get_by_public_id(l_profile_public_id);
    assert_true(
      l_status_code = 422
      AND l_profile_after.PFL_DISPLAY_NAME = l_profile_before.PFL_DISPLAY_NAME
      AND l_profile_after.PFL_BIO = l_profile_before.PFL_BIO,
      'PATCH invalido deixou alteracao persistida.'
    );
    pass;

    start_test('body NULL retorna request obrigatorio');
    invoke_update(l_profile_public_id, NULL, l_account_id);
    assert_error(400, 'BEX-REQ-001');
    pass;

    start_test('campo desconhecido e rejeitado');
    l_request_body := build_request('Valid Name', NULL, NULL, 'pt-BR',
      'America/Sao_Paulo', TRUE);
    invoke_update(l_profile_public_id, l_request_body, l_account_id);
    free_temporary_clob(l_request_body);
    assert_error(400, 'BEX-REQ-006');
    pass;

    start_test('data malformada e rejeitada');
    l_request_body := build_request('Valid Name', NULL, '2024-02-31');
    invoke_update(l_profile_public_id, l_request_body, l_account_id);
    free_temporary_clob(l_request_body);
    assert_error(400, 'BEX-REQ-007');
    pass;

    start_test('display name invalido retorna 422');
    l_request_body := build_request('x');
    invoke_update(l_profile_public_id, l_request_body, l_account_id);
    free_temporary_clob(l_request_body);
    assert_error(422, 'BEX-PRF-005');
    pass;

    start_test('ator ausente e rejeitado');
    l_request_body := build_request('Valid Name');
    invoke_update(l_profile_public_id, l_request_body, NULL);
    free_temporary_clob(l_request_body);
    assert_error(400, 'BEX-REQ-004');
    pass;

    start_test('segunda criacao retorna conflito');
    l_request_body := build_request('Duplicate Profile');
    invoke_create(l_account_public_id, l_request_body, l_account_id);
    free_temporary_clob(l_request_body);
    assert_error(409, 'BEX-PRF-004');
    pass;

    start_test('criacao para conta inexistente retorna 404');
    l_request_body := build_request('Missing Account');
    invoke_create(LOWER(RAWTOHEX(SYS_GUID())), l_request_body, l_account_id);
    free_temporary_clob(l_request_body);
    assert_error(404, 'BEX-PRF-001');
    pass;

    start_test('PROFILE inexistente retorna 404');
    invoke_get_profile(LOWER(RAWTOHEX(SYS_GUID())), l_account_id);
    assert_error(404, 'BEX-PRF-002');
    pass;

    start_test('conta inexistente retorna erro distinto');
    invoke_get_by_account(LOWER(RAWTOHEX(SYS_GUID())), l_account_id);
    assert_error(404, 'BEX-PRF-001');
    pass;

    start_test('conta sem PROFILE retorna erro distinto');
    invoke_get_by_account(l_second_account_public_id, l_account_id);
    assert_error(404, 'BEX-PRF-003');
    pass;

    start_test('atualizacao de PROFILE inexistente retorna 404');
    l_request_body := build_request('Missing Profile');
    invoke_update(LOWER(RAWTOHEX(SYS_GUID())), l_request_body, l_account_id);
    free_temporary_clob(l_request_body);
    assert_error(404, 'BEX-PRF-002');
    pass;

    start_test('API depende somente da Service PROFILE');
    SELECT COUNT(*) INTO l_source_count FROM USER_SOURCE
     WHERE NAME = 'PFL_API_PKG' AND TYPE = 'PACKAGE BODY'
       AND REGEXP_LIKE(UPPER(TEXT),
         'PFL_(RULE|REPOSITORY)_PKG|ACC_(SERVICE|RULE|REPOSITORY)_PKG');
    assert_true(l_source_count = 0, 'API possui dependencia de dominio proibida.');
    pass;

    start_test('API nao contem SQL de dominio');
    SELECT COUNT(*) INTO l_source_count FROM USER_SOURCE
     WHERE NAME = 'PFL_API_PKG' AND TYPE = 'PACKAGE BODY'
       AND REGEXP_LIKE(UPPER(TEXT),
         '(^|[^A-Z_])(SELECT|INSERT|UPDATE|DELETE|MERGE|EXECUTE[[:space:]]+IMMEDIATE)([^A-Z_]|$)');
    assert_true(l_source_count = 0, 'API possui SQL de dominio.');
    pass;

    start_test('contrato publico nao recebe IDs internos');
    SELECT COUNT(*) INTO l_source_count FROM USER_SOURCE
     WHERE NAME = 'PFL_API_PKG' AND TYPE = 'PACKAGE'
       AND REGEXP_LIKE(UPPER(TEXT), 'P_(ACCOUNT|PROFILE)_ID');
    assert_true(l_source_count = 0, 'Contrato recebe identificador interno.');
    pass;

    start_test('API utiliza somente operacoes publicas aprovadas');
    SELECT COUNT(*) INTO l_source_count FROM USER_SOURCE
     WHERE NAME = 'PFL_API_PKG' AND TYPE = 'PACKAGE BODY'
       AND INSTR(UPPER(TEXT), 'PFL_SERVICE_PKG.') > 0
       AND NOT REGEXP_LIKE(UPPER(TEXT),
         'PFL_SERVICE_PKG[.](CREATE_BY_ACCOUNT_PUBLIC_ID|GET_BY_PUBLIC_ID|GET_BY_ACCOUNT_PUBLIC_ID|UPDATE_BY_PUBLIC_ID|E_)');
    assert_true(l_source_count = 0, 'API chamou operacao nao aprovada.');
    pass;

    start_test('API nao utiliza SQL dinamico ou SQLERRM');
    SELECT COUNT(*) INTO l_source_count FROM USER_SOURCE
     WHERE NAME = 'PFL_API_PKG' AND TYPE = 'PACKAGE BODY'
       AND REGEXP_LIKE(UPPER(TEXT), 'EXECUTE[[:space:]]+IMMEDIATE|DBMS_SQL|SQLERRM');
    assert_true(l_source_count = 0, 'API usa recurso proibido.');
    pass;
  END run_tests;
BEGIN
  create_account_fixture(l_account_id, l_account_public_id);
  create_account_fixture(l_second_account_id, l_second_account_public_id);
  COMMIT;
  run_tests;

  IF g_test_count <> c_expected_test_count THEN
    fail('Quantidade de testes invalida. Esperado=' || c_expected_test_count
      || ', executado=' || g_test_count);
  END IF;

  free_temporary_clob(l_request_body);
  free_temporary_clob(l_response_body);
  clear_context;
  cleanup;
  DBMS_OUTPUT.PUT_LINE('PFL_API_PKG: PASSED');
EXCEPTION
  WHEN OTHERS THEN
    free_temporary_clob(l_request_body);
    free_temporary_clob(l_response_body);
    clear_context;
    cleanup;
    DBMS_OUTPUT.PUT_LINE('FAIL - ' || NVL(g_current_test, 'initialization'));
    RAISE;
END;
/
