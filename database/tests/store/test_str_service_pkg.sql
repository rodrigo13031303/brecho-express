SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  g_test_count   PLS_INTEGER := 0;
  g_current_test VARCHAR2(200);

  c_expected_test_count CONSTANT PLS_INTEGER := 55;
  c_create_actor        CONSTANT NUMBER := 5101;
  c_update_actor        CONSTANT NUMBER := 5102;
  c_state_actor         CONSTANT NUMBER := 5103;

  l_run_token          VARCHAR2(12);
  l_account_id         BEX_ACCOUNT.ACC_ID%TYPE;
  l_other_account_id   BEX_ACCOUNT.ACC_ID%TYPE;
  l_empty_account_id   BEX_ACCOUNT.ACC_ID%TYPE;
  l_blocked_account_id BEX_ACCOUNT.ACC_ID%TYPE;
  l_account_public_id         BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE;
  l_other_account_public_id   BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE;
  l_empty_account_public_id   BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE;
  l_blocked_account_public_id BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE;
  l_store        str_service_pkg.t_store_record;
  l_aux_store    str_service_pkg.t_store_record;
  l_state_store  str_service_pkg.t_store_record;
  l_draft_close  str_service_pkg.t_store_record;
  l_original     str_repository_pkg.t_store_record;
  l_internal     str_repository_pkg.t_store_record;
  l_stores       str_service_pkg.t_store_table;
  l_patch        str_service_pkg.t_store_patch;
  l_raised       BOOLEAN;

  PROCEDURE fail(p_message IN VARCHAR2) IS
  BEGIN
    RAISE_APPLICATION_ERROR(-20999, p_message);
  END fail;

  PROCEDURE assert_true(p_condition IN BOOLEAN, p_message IN VARCHAR2) IS
  BEGIN
    IF p_condition IS NULL OR NOT p_condition THEN
      fail(p_message);
    END IF;
  END assert_true;

  PROCEDURE assert_false(p_condition IN BOOLEAN, p_message IN VARCHAR2) IS
  BEGIN
    IF p_condition IS NULL OR p_condition THEN
      fail(p_message);
    END IF;
  END assert_false;

  PROCEDURE start_test(p_name IN VARCHAR2) IS
  BEGIN
    g_current_test := p_name;
  END start_test;

  PROCEDURE pass IS
  BEGIN
    g_test_count := g_test_count + 1;
    DBMS_OUTPUT.PUT_LINE(
      'PASS ' || LPAD(g_test_count, 2, '0') || ' - ' || g_current_test
    );
  END pass;

  PROCEDURE reset_patch(
    o_patch OUT NOCOPY str_service_pkg.t_store_patch
  ) IS
  BEGIN
    o_patch.set_name := FALSE;
    o_patch.name_value := NULL;
    o_patch.set_slug := FALSE;
    o_patch.slug_value := NULL;
    o_patch.set_description := FALSE;
    o_patch.description_value := NULL;
    o_patch.set_logo_url := FALSE;
    o_patch.logo_url_value := NULL;
    o_patch.set_cover_url := FALSE;
    o_patch.cover_url_value := NULL;
    o_patch.set_locale_code := FALSE;
    o_patch.locale_code_value := NULL;
    o_patch.set_timezone_name := FALSE;
    o_patch.timezone_value := NULL;
  END reset_patch;

  PROCEDURE create_account_fixture(
    p_status            IN BEX_ACCOUNT.ACC_STATUS%TYPE,
    o_account_id        OUT BEX_ACCOUNT.ACC_ID%TYPE,
    o_account_public_id OUT BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE
  ) IS
    l_email BEX_ACCOUNT.ACC_EMAIL%TYPE;
  BEGIN
    o_account_public_id := LOWER(RAWTOHEX(SYS_GUID()));
    l_email := 'store.service.' || LOWER(RAWTOHEX(SYS_GUID())) ||
               '@example.invalid';
    INSERT INTO BEX_ACCOUNT
    (
      ACC_PUBLIC_ID, ACC_EMAIL, ACC_PASSWORD_HASH,
      ACC_PASSWORD_CHANGED_AT, ACC_STATUS
    )
    VALUES
    (
      o_account_public_id, l_email, 'store-service-test-credential',
      SYSTIMESTAMP, p_status
    )
    RETURNING ACC_ID INTO o_account_id;
  END create_account_fixture;

  FUNCTION create_store(
    p_account_public_id IN BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE,
    p_name              IN BEX_STORE.STR_NAME%TYPE,
    p_slug              IN BEX_STORE.STR_SLUG%TYPE,
    p_actor             IN BEX_STORE.STR_CREATED_BY%TYPE := c_create_actor
  ) RETURN str_service_pkg.t_store_record IS
  BEGIN
    RETURN str_service_pkg.create_by_account_public_id(
      p_account_public_id => p_account_public_id,
      p_name              => p_name,
      p_slug              => p_slug,
      p_audit_actor_id    => p_actor
    );
  END create_store;

  PROCEDURE assert_public_exception_code(
    p_index         IN PLS_INTEGER,
    p_expected_code IN PLS_INTEGER
  ) IS
  BEGIN
    BEGIN
      CASE p_index
        WHEN 1 THEN RAISE str_service_pkg.e_store_not_found;
        WHEN 2 THEN RAISE str_service_pkg.e_account_not_found;
        WHEN 3 THEN RAISE str_service_pkg.e_name_required;
        WHEN 4 THEN RAISE str_service_pkg.e_invalid_name;
        WHEN 5 THEN RAISE str_service_pkg.e_slug_required;
        WHEN 6 THEN RAISE str_service_pkg.e_invalid_slug;
        WHEN 7 THEN RAISE str_service_pkg.e_invalid_description;
        WHEN 8 THEN RAISE str_service_pkg.e_invalid_logo_url;
        WHEN 9 THEN RAISE str_service_pkg.e_invalid_cover_url;
        WHEN 10 THEN RAISE str_service_pkg.e_invalid_locale;
        WHEN 11 THEN RAISE str_service_pkg.e_invalid_timezone;
        WHEN 12 THEN RAISE str_service_pkg.e_invalid_status;
        WHEN 13 THEN RAISE str_service_pkg.e_invalid_transition;
        WHEN 14 THEN RAISE str_service_pkg.e_empty_patch;
        WHEN 15 THEN RAISE str_service_pkg.e_slug_not_editable;
        WHEN 16 THEN RAISE str_service_pkg.e_store_closed;
        WHEN 17 THEN RAISE str_service_pkg.e_account_ineligible;
        WHEN 18 THEN RAISE str_service_pkg.e_slug_already_used;
        ELSE RAISE VALUE_ERROR;
      END CASE;
    EXCEPTION
      WHEN OTHERS THEN
        IF SQLCODE <> p_expected_code THEN
          fail(
            'Codigo Oracle incorreto para excecao ' || p_index ||
            '. Esperado=' || p_expected_code || ' atual=' || SQLCODE
          );
        END IF;
    END;
  END assert_public_exception_code;

  PROCEDURE run_tests IS
    l_count        PLS_INTEGER;
    l_source_count PLS_INTEGER;
    l_before       TIMESTAMP(6);
  BEGIN
    start_test('Specification esta valida');
    SELECT COUNT(*) INTO l_count FROM USER_OBJECTS
     WHERE OBJECT_NAME = 'STR_SERVICE_PKG' AND OBJECT_TYPE = 'PACKAGE'
       AND STATUS = 'VALID';
    assert_true(l_count = 1, 'Specification deve estar VALID.'); pass;

    start_test('Body esta valido e sem USER_ERRORS');
    SELECT COUNT(*) INTO l_count FROM USER_OBJECTS
     WHERE OBJECT_NAME = 'STR_SERVICE_PKG' AND OBJECT_TYPE = 'PACKAGE BODY'
       AND STATUS = 'VALID';
    assert_true(l_count = 1, 'Body deve estar VALID.');
    SELECT COUNT(*) INTO l_count FROM USER_ERRORS
     WHERE NAME = 'STR_SERVICE_PKG' AND TYPE IN ('PACKAGE', 'PACKAGE BODY');
    assert_true(l_count = 0, 'Service nao pode possuir USER_ERRORS.'); pass;

    start_test('Excecoes publicas possuem codigos Oracle estaveis');
    assert_public_exception_code(1, -20860);
    assert_public_exception_code(2, -20840);
    FOR i IN 3..18 LOOP
      assert_public_exception_code(i, -20858 - i);
    END LOOP;
    pass;

    start_test('Criacao retorna STORE valida');
    l_store := create_store(
      l_account_public_id,
      '  Loja   Service Principal  ',
      ' Loja Service ' || l_run_token
    );
    assert_true(l_store.store_public_id IS NOT NULL, 'STORE nao foi criada.'); pass;

    start_test('Criacao gera Public ID hexadecimal minusculo');
    assert_true(
      LENGTH(TRIM(l_store.store_public_id)) = 32
      AND REGEXP_LIKE(TRIM(l_store.store_public_id), '^[0-9a-f]{32}$', 'c'),
      'Public ID deve ter 32 caracteres hexadecimais minusculos.'
    ); pass;

    start_test('Criacao associa ACCOUNT correta sem PROFILE');
    l_internal := str_repository_pkg.get_by_public_id(l_store.store_public_id);
    assert_true(l_internal.acc_id = l_account_id, 'ACCOUNT incorreta.'); pass;

    start_test('Criacao normaliza nome e slug');
    assert_true(
      l_store.store_name = 'Loja Service Principal'
      AND l_store.store_slug = 'loja-service-' || l_run_token,
      'Nome ou slug nao foi normalizado.'
    ); pass;

    start_test('Criacao aplica status locale e timezone iniciais');
    assert_true(
      l_store.status = 'DRAFT'
      AND l_store.locale_code = 'pt-BR'
      AND l_store.timezone_name = 'America/Sao_Paulo',
      'Defaults de criacao incorretos.'
    ); pass;

    start_test('Criacao minima aceita opcionais nulos e timestamps');
    assert_true(
      l_store.description IS NULL AND l_store.logo_url IS NULL
      AND l_store.cover_url IS NULL AND l_store.created_at IS NOT NULL
      AND l_store.updated_at IS NOT NULL,
      'Opcionais ou timestamps incorretos.'
    ); pass;

    start_test('Criacao persiste auditoria inicial');
    assert_true(
      l_internal.str_created_by = c_create_actor
      AND l_internal.str_updated_by = c_create_actor,
      'Auditoria inicial incorreta.'
    ); pass;

    start_test('Criacao completa persiste opcionais');
    l_aux_store := str_service_pkg.create_by_account_public_id(
      l_account_public_id, 'Loja Completa', 'completa-' || l_run_token,
      ' descricao ', ' https://example.invalid/logo ',
      ' https://example.invalid/cover ', ' pt-BR ',
      ' America/Sao_Paulo ', c_create_actor
    );
    assert_true(
      l_aux_store.description = 'descricao'
      AND l_aux_store.logo_url = 'https://example.invalid/logo'
      AND l_aux_store.cover_url = 'https://example.invalid/cover',
      'Opcionais completos incorretos.'
    ); pass;

    start_test('Criacao rejeita ACCOUNT inexistente');
    l_raised := FALSE;
    BEGIN
      l_aux_store := create_store(LOWER(RAWTOHEX(SYS_GUID())), 'Loja', 'missing-' || l_run_token);
    EXCEPTION WHEN str_service_pkg.e_account_not_found THEN l_raised := SQLCODE = -20840; END;
    assert_true(l_raised, 'ACCOUNT inexistente deveria falhar.'); pass;

    start_test('Criacao rejeita ACCOUNT inelegivel');
    l_raised := FALSE;
    BEGIN
      l_aux_store := create_store(l_blocked_account_public_id, 'Loja', 'blocked-' || l_run_token);
    EXCEPTION WHEN str_service_pkg.e_account_ineligible THEN l_raised := SQLCODE = -20875; END;
    assert_true(l_raised, 'ACCOUNT BLOCKED deveria falhar.'); pass;

    start_test('Criacao rejeita nome invalido');
    l_raised := FALSE;
    BEGIN
      l_aux_store := create_store(l_account_public_id, 'x', 'valid-' || l_run_token);
    EXCEPTION WHEN str_service_pkg.e_invalid_name THEN l_raised := SQLCODE = -20862; END;
    assert_true(l_raised, 'Nome invalido deveria falhar.'); pass;

    start_test('Criacao traduz nome obrigatorio');
    l_raised := FALSE;
    BEGIN
      l_aux_store := create_store(
        l_account_public_id, NULL, 'required-name-' || l_run_token
      );
    EXCEPTION
      WHEN str_service_pkg.e_name_required THEN
        l_raised := SQLCODE = -20861;
    END;
    assert_true(l_raised, 'Nome obrigatorio nao foi traduzido.'); pass;

    start_test('Criacao rejeita slug invalido');
    l_raised := FALSE;
    BEGIN
      l_aux_store := create_store(l_account_public_id, 'Valid Name', '!!!');
    EXCEPTION WHEN str_service_pkg.e_slug_required THEN l_raised := SQLCODE = -20863; END;
    assert_true(l_raised, 'Slug invalido deveria falhar.'); pass;

    start_test('Criacao traduz logo invalido');
    l_raised := FALSE;
    BEGIN
      l_aux_store := str_service_pkg.create_by_account_public_id(
        l_account_public_id, 'Invalid Logo', 'invalid-logo-' || l_run_token,
        p_logo_url => 'ftp://example.invalid/logo'
      );
    EXCEPTION
      WHEN str_service_pkg.e_invalid_logo_url THEN
        l_raised := SQLCODE = -20866;
    END;
    assert_true(l_raised, 'Logo invalido nao foi traduzido.'); pass;

    start_test('Criacao traduz cover invalido');
    l_raised := FALSE;
    BEGIN
      l_aux_store := str_service_pkg.create_by_account_public_id(
        l_account_public_id, 'Invalid Cover', 'invalid-cover-' || l_run_token,
        p_cover_url => 'cover.invalid'
      );
    EXCEPTION
      WHEN str_service_pkg.e_invalid_cover_url THEN
        l_raised := SQLCODE = -20867;
    END;
    assert_true(l_raised, 'Cover invalido nao foi traduzido.'); pass;

    start_test('Criacao traduz locale e timezone invalidos');
    l_raised := FALSE;
    BEGIN
      l_aux_store := str_service_pkg.create_by_account_public_id(
        l_account_public_id, 'Invalid Locale', 'invalid-locale-' || l_run_token,
        p_locale_code => 'en-US'
      );
    EXCEPTION
      WHEN str_service_pkg.e_invalid_locale THEN
        l_raised := SQLCODE = -20868;
    END;
    assert_true(l_raised, 'Locale invalido nao foi traduzido.');
    l_raised := FALSE;
    BEGIN
      l_aux_store := str_service_pkg.create_by_account_public_id(
        l_account_public_id, 'Invalid Timezone', 'invalid-timezone-' || l_run_token,
        p_timezone_name => 'UTC'
      );
    EXCEPTION
      WHEN str_service_pkg.e_invalid_timezone THEN
        l_raised := SQLCODE = -20869;
    END;
    assert_true(l_raised, 'Timezone invalido nao foi traduzido.'); pass;

    start_test('Criacao traduz slug duplicado para excecao nominal');
    l_raised := FALSE;
    BEGIN
      l_aux_store := create_store(l_other_account_public_id, 'Duplicate', l_store.store_slug);
    EXCEPTION WHEN str_service_pkg.e_slug_already_used THEN l_raised := SQLCODE = -20876; END;
    assert_true(l_raised, 'Slug duplicado deve gerar E_SLUG_ALREADY_USED.'); pass;

    start_test('Duplicidade considera caixa e espacos apos normalizacao');
    l_raised := FALSE;
    BEGIN
      l_aux_store := create_store(
        l_other_account_public_id, 'Duplicate Normalized',
        '  ' || UPPER(l_store.store_slug) || '  '
      );
    EXCEPTION WHEN str_service_pkg.e_slug_already_used THEN l_raised := SQLCODE = -20876; END;
    assert_true(l_raised, 'Slug normalizado duplicado deveria falhar.'); pass;

    start_test('GET_BY_PUBLIC_ID retorna existente');
    l_aux_store := str_service_pkg.get_by_public_id(l_store.store_public_id);
    assert_true(l_aux_store.store_slug = l_store.store_slug, 'GET incorreto.'); pass;

    start_test('GET_BY_PUBLIC_ID inexistente retorna vazio');
    l_aux_store := str_service_pkg.get_by_public_id(LOWER(RAWTOHEX(SYS_GUID())));
    assert_true(l_aux_store.store_public_id IS NULL, 'GET inexistente deve retornar vazio.'); pass;

    start_test('REQUIRE_BY_PUBLIC_ID retorna existente');
    l_aux_store := str_service_pkg.require_by_public_id(l_store.store_public_id);
    assert_true(l_aux_store.store_name = l_store.store_name, 'REQUIRE incorreto.'); pass;

    start_test('REQUIRE_BY_PUBLIC_ID rejeita inexistente');
    l_raised := FALSE;
    BEGIN
      l_aux_store := str_service_pkg.require_by_public_id(LOWER(RAWTOHEX(SYS_GUID())));
    EXCEPTION WHEN str_service_pkg.e_store_not_found THEN l_raised := SQLCODE = -20860; END;
    assert_true(l_raised, 'REQUIRE inexistente deveria usar -20860.'); pass;

    start_test('GET_BY_SLUG normaliza e retorna existente');
    l_aux_store := str_service_pkg.get_by_slug(' ' || UPPER(l_store.store_slug) || ' ');
    assert_true(l_aux_store.store_public_id = l_store.store_public_id, 'GET por slug incorreto.'); pass;

    start_test('GET_BY_SLUG inexistente retorna vazio');
    l_aux_store := str_service_pkg.get_by_slug('absent-' || l_run_token);
    assert_true(l_aux_store.store_public_id IS NULL, 'Slug inexistente deve retornar vazio.'); pass;

    start_test('REQUIRE_BY_SLUG retorna existente');
    l_aux_store := str_service_pkg.require_by_slug(l_store.store_slug);
    assert_true(l_aux_store.store_public_id = l_store.store_public_id, 'REQUIRE por slug incorreto.'); pass;

    start_test('REQUIRE_BY_SLUG rejeita inexistente');
    l_raised := FALSE;
    BEGIN
      l_aux_store := str_service_pkg.require_by_slug('missing-' || l_run_token);
    EXCEPTION WHEN str_service_pkg.e_store_not_found THEN l_raised := TRUE; END;
    assert_true(l_raised, 'REQUIRE por slug deveria falhar.'); pass;

    start_test('LIST retorna varias STORE da mesma ACCOUNT');
    l_stores := str_service_pkg.list_by_account_public_id(l_account_public_id);
    assert_true(l_stores.COUNT = 2, 'LIST deveria retornar duas lojas.'); pass;

    start_test('LIST nao mistura ACCOUNTs');
    l_aux_store := create_store(l_other_account_public_id, 'Other Store', 'other-' || l_run_token);
    l_stores := str_service_pkg.list_by_account_public_id(l_account_public_id);
    assert_true(l_stores.COUNT = 2, 'LIST misturou outra ACCOUNT.'); pass;

    start_test('LIST de ACCOUNT vazia retorna colecao vazia');
    l_stores := str_service_pkg.list_by_account_public_id(l_empty_account_public_id);
    assert_true(l_stores.COUNT = 0, 'LIST vazia deveria retornar zero.'); pass;

    start_test('LIST exige ACCOUNT existente');
    l_raised := FALSE;
    BEGIN
      l_stores := str_service_pkg.list_by_account_public_id(LOWER(RAWTOHEX(SYS_GUID())));
    EXCEPTION WHEN str_service_pkg.e_account_not_found THEN l_raised := SQLCODE = -20840; END;
    assert_true(l_raised, 'LIST deveria exigir ACCOUNT existente.'); pass;

    l_original := str_repository_pkg.get_by_public_id(l_store.store_public_id);
    start_test('UPDATE normaliza e altera nome');
    reset_patch(l_patch); l_patch.set_name := TRUE; l_patch.name_value := ' Nome   Atualizado ';
    l_store := str_service_pkg.update_by_public_id(l_store.store_public_id, l_patch, c_update_actor);
    assert_true(l_store.store_name = 'Nome Atualizado', 'Nome nao atualizado.'); pass;

    start_test('UPDATE altera e limpa descricao');
    reset_patch(l_patch); l_patch.set_description := TRUE; l_patch.description_value := ' descricao nova ';
    l_store := str_service_pkg.update_by_public_id(l_store.store_public_id, l_patch, c_update_actor);
    assert_true(l_store.description = 'descricao nova', 'Descricao nao atualizada.');
    reset_patch(l_patch); l_patch.set_description := TRUE; l_patch.description_value := NULL;
    l_store := str_service_pkg.update_by_public_id(l_store.store_public_id, l_patch, c_update_actor);
    assert_true(l_store.description IS NULL, 'Descricao nao foi limpa.'); pass;

    start_test('UPDATE altera e limpa logo');
    reset_patch(l_patch); l_patch.set_logo_url := TRUE; l_patch.logo_url_value := ' https://example.invalid/new-logo ';
    l_store := str_service_pkg.update_by_public_id(l_store.store_public_id, l_patch, c_update_actor);
    assert_true(l_store.logo_url = 'https://example.invalid/new-logo', 'Logo nao atualizado.');
    reset_patch(l_patch); l_patch.set_logo_url := TRUE; l_patch.logo_url_value := NULL;
    l_store := str_service_pkg.update_by_public_id(l_store.store_public_id, l_patch, c_update_actor);
    assert_true(l_store.logo_url IS NULL, 'Logo nao foi limpo.'); pass;

    start_test('UPDATE altera e limpa cover');
    reset_patch(l_patch); l_patch.set_cover_url := TRUE; l_patch.cover_url_value := ' https://example.invalid/new-cover ';
    l_store := str_service_pkg.update_by_public_id(l_store.store_public_id, l_patch, c_update_actor);
    assert_true(l_store.cover_url = 'https://example.invalid/new-cover', 'Cover nao atualizado.');
    reset_patch(l_patch); l_patch.set_cover_url := TRUE; l_patch.cover_url_value := NULL;
    l_store := str_service_pkg.update_by_public_id(l_store.store_public_id, l_patch, c_update_actor);
    assert_true(l_store.cover_url IS NULL, 'Cover nao foi limpo.'); pass;

    start_test('UPDATE altera locale e timezone');
    reset_patch(l_patch); l_patch.set_locale_code := TRUE; l_patch.locale_code_value := ' pt-BR ';
    l_patch.set_timezone_name := TRUE; l_patch.timezone_value := ' America/Sao_Paulo ';
    l_store := str_service_pkg.update_by_public_id(l_store.store_public_id, l_patch, c_update_actor);
    assert_true(l_store.locale_code = 'pt-BR' AND l_store.timezone_name = 'America/Sao_Paulo', 'Dados regionais incorretos.'); pass;

    start_test('UPDATE altera slug em DRAFT');
    reset_patch(l_patch); l_patch.set_slug := TRUE; l_patch.slug_value := ' Slug Novo ' || l_run_token;
    l_store := str_service_pkg.update_by_public_id(l_store.store_public_id, l_patch, c_update_actor);
    assert_true(l_store.store_slug = 'slug-novo-' || l_run_token, 'Slug DRAFT nao atualizado.'); pass;

    start_test('UPDATE rejeita slug duplicado nominalmente');
    reset_patch(l_patch); l_patch.set_slug := TRUE; l_patch.slug_value := l_aux_store.store_slug;
    l_raised := FALSE;
    BEGIN l_store := str_service_pkg.update_by_public_id(l_store.store_public_id, l_patch, c_update_actor);
    EXCEPTION WHEN str_service_pkg.e_slug_already_used THEN l_raised := SQLCODE = -20876; END;
    assert_true(l_raised, 'Slug duplicado em UPDATE deveria falhar nominalmente.'); pass;

    start_test('UPDATE rejeita PATCH vazio');
    reset_patch(l_patch); l_raised := FALSE;
    BEGIN l_store := str_service_pkg.update_by_public_id(l_store.store_public_id, l_patch, c_update_actor);
    EXCEPTION WHEN str_service_pkg.e_empty_patch THEN l_raised := SQLCODE = -20872; END;
    assert_true(l_raised, 'PATCH vazio deveria falhar.'); pass;

    start_test('UPDATE rejeita STORE inexistente');
    reset_patch(l_patch); l_patch.set_name := TRUE; l_patch.name_value := 'Valid Name'; l_raised := FALSE;
    BEGIN l_aux_store := str_service_pkg.update_by_public_id(LOWER(RAWTOHEX(SYS_GUID())), l_patch, c_update_actor);
    EXCEPTION WHEN str_service_pkg.e_store_not_found THEN l_raised := TRUE; END;
    assert_true(l_raised, 'UPDATE inexistente deveria falhar.'); pass;

    start_test('UPDATE atualiza auditoria e preserva imutaveis');
    l_internal := str_repository_pkg.get_by_public_id(l_store.store_public_id);
    assert_true(
      l_internal.str_updated_at >= l_original.str_updated_at
      AND l_internal.str_updated_by = c_update_actor
      AND l_internal.str_created_at = l_original.str_created_at
      AND l_internal.str_created_by = l_original.str_created_by
      AND l_internal.acc_id = l_original.acc_id,
      'Auditoria ou imutaveis incorretos.'
    ); pass;

    start_test('UPDATE preserva campos ausentes');
    assert_true(
      l_store.locale_code = 'pt-BR'
      AND l_store.timezone_name = 'America/Sao_Paulo',
      'Campos ausentes nao foram preservados.'
    ); pass;

    start_test('DRAFT transiciona para ACTIVE com auditoria');
    l_state_store := create_store(l_account_public_id, 'State Store', 'state-' || l_run_token);
    l_before := l_state_store.updated_at;
    l_state_store := str_service_pkg.activate_by_public_id(l_state_store.store_public_id, c_state_actor);
    l_internal := str_repository_pkg.get_by_public_id(l_state_store.store_public_id);
    assert_true(
      l_state_store.status = 'ACTIVE' AND l_state_store.updated_at >= l_before
      AND l_internal.str_updated_by = c_state_actor,
      'Ativacao ou auditoria incorreta.'
    ); pass;

    start_test('Slug nao e editavel apos ativacao');
    reset_patch(l_patch); l_patch.set_slug := TRUE; l_patch.slug_value := 'active-new-' || l_run_token; l_raised := FALSE;
    BEGIN l_state_store := str_service_pkg.update_by_public_id(l_state_store.store_public_id, l_patch, c_update_actor);
    EXCEPTION WHEN str_service_pkg.e_slug_not_editable THEN l_raised := SQLCODE = -20873; END;
    assert_true(l_raised, 'Slug ACTIVE deveria ser imutavel.'); pass;

    start_test('ACTIVE transiciona para CLOSED com auditoria');
    l_state_store := str_service_pkg.close_by_public_id(l_state_store.store_public_id, c_state_actor);
    l_internal := str_repository_pkg.get_by_public_id(l_state_store.store_public_id);
    assert_true(l_state_store.status = 'CLOSED' AND l_internal.str_updated_by = c_state_actor, 'Fechamento incorreto.'); pass;

    start_test('CLOSED rejeita UPDATE comum');
    reset_patch(l_patch); l_patch.set_name := TRUE; l_patch.name_value := 'Closed Name'; l_raised := FALSE;
    BEGIN l_state_store := str_service_pkg.update_by_public_id(l_state_store.store_public_id, l_patch, c_update_actor);
    EXCEPTION WHEN str_service_pkg.e_store_closed THEN l_raised := SQLCODE = -20874; END;
    assert_true(l_raised, 'STORE fechada deveria rejeitar UPDATE.'); pass;

    start_test('Transicao invalida e rejeitada');
    l_raised := FALSE;
    BEGIN l_state_store := str_service_pkg.activate_by_public_id(l_state_store.store_public_id, c_state_actor);
    EXCEPTION WHEN str_service_pkg.e_invalid_transition THEN l_raised := SQLCODE = -20871; END;
    assert_true(l_raised, 'CLOSED para ACTIVE deveria falhar.'); pass;

    start_test('DRAFT pode transicionar diretamente para CLOSED');
    l_draft_close := create_store(l_account_public_id, 'Draft Close', 'draft-close-' || l_run_token);
    l_draft_close := str_service_pkg.close_by_public_id(l_draft_close.store_public_id, c_state_actor);
    assert_true(l_draft_close.status = 'CLOSED', 'DRAFT para CLOSED deveria funcionar.'); pass;

    start_test('Operacoes de estado rejeitam STORE inexistente');
    l_raised := FALSE;
    BEGIN l_aux_store := str_service_pkg.activate_by_public_id(LOWER(RAWTOHEX(SYS_GUID())), c_state_actor);
    EXCEPTION WHEN str_service_pkg.e_store_not_found THEN l_raised := TRUE; END;
    assert_true(l_raised, 'Ativacao inexistente deveria falhar.');
    l_raised := FALSE;
    BEGIN l_aux_store := str_service_pkg.close_by_public_id(LOWER(RAWTOHEX(SYS_GUID())), c_state_actor);
    EXCEPTION WHEN str_service_pkg.e_store_not_found THEN l_raised := TRUE; END;
    assert_true(l_raised, 'Fechamento inexistente deveria falhar.'); pass;

    start_test('SLUG_AVAILABLE identifica livre e ocupado');
    assert_true(str_service_pkg.slug_available('free-' || l_run_token), 'Slug livre deveria estar disponivel.');
    assert_false(str_service_pkg.slug_available(' ' || UPPER(l_store.store_slug) || ' '), 'Slug ocupado normalizado deveria falhar.'); pass;

    start_test('SLUG_AVAILABLE rejeita slug invalido');
    l_raised := FALSE;
    BEGIN l_raised := str_service_pkg.slug_available('!!!');
    EXCEPTION WHEN str_service_pkg.e_slug_required THEN l_raised := SQLCODE = -20863; END;
    assert_true(l_raised, 'Slug invalido deveria ser rejeitado.'); pass;

    start_test('Service nao possui SQL transacao ou apresentacao');
    SELECT COUNT(*) INTO l_source_count FROM USER_SOURCE
     WHERE NAME = 'STR_SERVICE_PKG' AND TYPE = 'PACKAGE BODY'
       AND REGEXP_LIKE(
         UPPER(TEXT),
         '(^|[^A-Z_])(SELECT|INSERT|UPDATE|DELETE|MERGE|COMMIT|ROLLBACK)([^A-Z_]|$)|' ||
         'EXECUTE[[:space:]]+IMMEDIATE|DBMS_SQL|SQLERRM|JSON|HTTP|ORDS|APEX|' ||
         'WHEN[[:space:]]+OTHERS'
       );
    assert_true(l_source_count = 0, 'Service possui elemento proibido.'); pass;

    start_test('Service usa somente dependencias de camada aprovadas');
    SELECT COUNT(*) INTO l_source_count FROM USER_SOURCE
     WHERE NAME = 'STR_SERVICE_PKG' AND TYPE = 'PACKAGE BODY'
       AND REGEXP_LIKE(UPPER(TEXT), 'ACC_(RULE|REPOSITORY)_PKG|BEX_PROFILE|PFL_');
    assert_true(l_source_count = 0, 'Service possui dependencia externa proibida.'); pass;
  END run_tests;
BEGIN
  l_run_token := LOWER(SUBSTR(RAWTOHEX(SYS_GUID()), 1, 12));
  create_account_fixture('ACTIVE', l_account_id, l_account_public_id);
  create_account_fixture('ACTIVE', l_other_account_id, l_other_account_public_id);
  create_account_fixture('ACTIVE', l_empty_account_id, l_empty_account_public_id);
  create_account_fixture('BLOCKED', l_blocked_account_id, l_blocked_account_public_id);

  run_tests;
  IF g_test_count <> c_expected_test_count THEN
    fail(
      'Quantidade de testes invalida. Esperado=' || c_expected_test_count ||
      ', executado=' || g_test_count
    );
  END IF;
  ROLLBACK;
  DBMS_OUTPUT.PUT_LINE('STR_SERVICE_PKG: PASSED');
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('FAIL - ' || NVL(g_current_test, 'initialization'));
    RAISE;
END;
/
