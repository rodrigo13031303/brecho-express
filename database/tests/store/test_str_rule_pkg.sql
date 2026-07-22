SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  g_test_count   PLS_INTEGER := 0;
  g_current_test VARCHAR2(200);

  c_expected_test_count CONSTANT PLS_INTEGER := 34;

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

  PROCEDURE assert_equals(
    p_actual IN VARCHAR2, p_expected IN VARCHAR2, p_message IN VARCHAR2
  ) IS
  BEGIN
    IF p_actual IS NULL OR p_expected IS NULL OR p_actual <> p_expected THEN
      fail(p_message || ' expected=' || p_expected || ' actual=' || p_actual);
    END IF;
  END assert_equals;

  PROCEDURE assert_null(p_actual IN VARCHAR2, p_message IN VARCHAR2) IS
  BEGIN
    IF p_actual IS NOT NULL THEN
      fail(p_message);
    END IF;
  END assert_null;

  PROCEDURE start_test(p_name IN VARCHAR2) IS
  BEGIN
    g_current_test := p_name;
  END start_test;

  PROCEDURE pass IS
  BEGIN
    g_test_count := g_test_count + 1;
    DBMS_OUTPUT.PUT_LINE(
      'PASS ' || LPAD(g_test_count, 3, '0') || ' - ' || g_current_test
    );
  END pass;

  PROCEDURE reset_patch(
    o_patch OUT NOCOPY str_rule_pkg.t_store_patch
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

  FUNCTION transition_allowed(
    p_current IN VARCHAR2,
    p_new     IN VARCHAR2
  ) RETURN BOOLEAN IS
  BEGIN
    RETURN (p_current = 'DRAFT' AND p_new IN ('ACTIVE', 'CLOSED'))
       OR (p_current = 'ACTIVE' AND p_new IN ('SUSPENDED', 'CLOSED'))
       OR (p_current = 'SUSPENDED' AND p_new IN ('ACTIVE', 'CLOSED'));
  END transition_allowed;

  FUNCTION error_code(p_index IN PLS_INTEGER)
    RETURN core_error_pkg.t_error_code IS
  BEGIN
    CASE p_index
      WHEN 1 THEN RETURN str_rule_pkg.c_code_name_required;
      WHEN 2 THEN RETURN str_rule_pkg.c_code_invalid_name;
      WHEN 3 THEN RETURN str_rule_pkg.c_code_slug_required;
      WHEN 4 THEN RETURN str_rule_pkg.c_code_invalid_slug;
      WHEN 5 THEN RETURN str_rule_pkg.c_code_invalid_description;
      WHEN 6 THEN RETURN str_rule_pkg.c_code_invalid_logo_url;
      WHEN 7 THEN RETURN str_rule_pkg.c_code_invalid_cover_url;
      WHEN 8 THEN RETURN str_rule_pkg.c_code_invalid_locale;
      WHEN 9 THEN RETURN str_rule_pkg.c_code_invalid_timezone;
      WHEN 10 THEN RETURN str_rule_pkg.c_code_invalid_status;
      WHEN 11 THEN RETURN str_rule_pkg.c_code_invalid_transition;
      WHEN 12 THEN RETURN str_rule_pkg.c_code_empty_patch;
      WHEN 13 THEN RETURN str_rule_pkg.c_code_slug_not_editable;
      WHEN 14 THEN RETURN str_rule_pkg.c_code_store_closed;
      WHEN 15 THEN RETURN str_rule_pkg.c_code_account_ineligible;
      WHEN 16 THEN RETURN str_rule_pkg.c_code_slug_already_used;
      ELSE RAISE VALUE_ERROR;
    END CASE;
  END error_code;

  FUNCTION expected_message(p_index IN PLS_INTEGER)
    RETURN core_error_pkg.t_external_message IS
  BEGIN
    CASE p_index
      WHEN 1 THEN RETURN 'O nome da STORE e obrigatorio.';
      WHEN 2 THEN RETURN 'O nome da STORE e invalido.';
      WHEN 3 THEN RETURN 'O slug da STORE e obrigatorio.';
      WHEN 4 THEN RETURN 'O slug da STORE e invalido.';
      WHEN 5 THEN RETURN 'A descricao da STORE e invalida.';
      WHEN 6 THEN RETURN 'A URL do logo da STORE e invalida.';
      WHEN 7 THEN RETURN 'A URL da capa da STORE e invalida.';
      WHEN 8 THEN RETURN 'O locale da STORE e invalido.';
      WHEN 9 THEN RETURN 'O timezone da STORE e invalido.';
      WHEN 10 THEN RETURN 'O status da STORE e invalido.';
      WHEN 11 THEN RETURN 'A transicao de status da STORE e invalida.';
      WHEN 12 THEN RETURN 'A atualizacao da STORE nao possui campos.';
      WHEN 13 THEN RETURN 'O slug da STORE nao pode ser alterado neste estado.';
      WHEN 14 THEN RETURN 'A STORE encerrada nao pode ser alterada.';
      WHEN 15 THEN RETURN 'A ACCOUNT nao esta elegivel para possuir STORE.';
      WHEN 16 THEN RETURN 'O slug da STORE ja esta em uso.';
      ELSE RAISE VALUE_ERROR;
    END CASE;
  END expected_message;

  PROCEDURE run_tests IS
    TYPE t_statuses IS TABLE OF VARCHAR2(20);
    l_statuses t_statuses := t_statuses('DRAFT', 'ACTIVE', 'SUSPENDED', 'CLOSED');
    l_count       PLS_INTEGER;
    l_raised      BOOLEAN;
    l_first       VARCHAR2(32767);
    l_second      VARCHAR2(32767);
    l_patch       str_rule_pkg.t_store_patch;
    l_creation    str_rule_pkg.t_store_creation;
    l_public_error core_error_pkg.t_public_error;
    l_error_policy core_error_pkg.t_error_policy;
  BEGIN
    start_test('Specification esta valida');
    SELECT COUNT(*) INTO l_count FROM USER_OBJECTS
     WHERE OBJECT_NAME = 'STR_RULE_PKG' AND OBJECT_TYPE = 'PACKAGE' AND STATUS = 'VALID';
    assert_true(l_count = 1, 'Specification deve estar VALID.'); pass;

    start_test('Body esta valido');
    SELECT COUNT(*) INTO l_count FROM USER_OBJECTS
     WHERE OBJECT_NAME = 'STR_RULE_PKG' AND OBJECT_TYPE = 'PACKAGE BODY' AND STATUS = 'VALID';
    assert_true(l_count = 1, 'Body deve estar VALID.'); pass;

    start_test('Package sem USER_ERRORS e dependencias proibidas');
    SELECT COUNT(*) INTO l_count FROM USER_ERRORS
     WHERE NAME = 'STR_RULE_PKG' AND TYPE IN ('PACKAGE', 'PACKAGE BODY');
    assert_true(l_count = 0, 'Package nao pode possuir USER_ERRORS.');
    SELECT COUNT(*) INTO l_count FROM USER_DEPENDENCIES
     WHERE NAME = 'STR_RULE_PKG'
       AND REFERENCED_NAME IN ('STR_REPOSITORY_PKG', 'BEX_ACCOUNT', 'BEX_PROFILE');
    assert_true(l_count = 0, 'Rule possui dependencia proibida.'); pass;

    start_test('Nome normaliza TRIM e espacos internos');
    assert_equals(str_rule_pkg.normalize_name('  Brecho   Sao Paulo  '), 'Brecho Sao Paulo', 'Nome normalizado incorreto.');
    l_first := 'Brech' || UNISTR('\00F3') || ' ' || UNISTR('\00C1') || 'gil';
    assert_equals(str_rule_pkg.normalize_name(l_first), l_first, 'Acentos devem ser preservados.');
    assert_null(str_rule_pkg.normalize_name(NULL), 'Nome NULL deve permanecer NULL.'); pass;

    start_test('Nome valida obrigatoriedade e limites');
    str_rule_pkg.validate_name('AB');
    str_rule_pkg.validate_name(RPAD('A', 200, 'A'));
    l_raised := FALSE; BEGIN str_rule_pkg.validate_name(NULL); EXCEPTION WHEN str_rule_pkg.e_name_required THEN l_raised := TRUE; END;
    assert_true(l_raised, 'Nome NULL deveria falhar.');
    l_raised := FALSE; BEGIN str_rule_pkg.validate_name(' '); EXCEPTION WHEN str_rule_pkg.e_name_required THEN l_raised := TRUE; END;
    assert_true(l_raised, 'Nome vazio deveria falhar.');
    l_raised := FALSE; BEGIN str_rule_pkg.validate_name('A'); EXCEPTION WHEN str_rule_pkg.e_invalid_name THEN l_raised := TRUE; END;
    assert_true(l_raised, 'Nome abaixo do limite deveria falhar.');
    l_raised := FALSE; BEGIN str_rule_pkg.validate_name(RPAD('A', 201, 'A')); EXCEPTION WHEN str_rule_pkg.e_invalid_name THEN l_raised := TRUE; END;
    assert_true(l_raised, 'Nome acima do limite deveria falhar.'); pass;

    start_test('Nome conta caracteres multibyte');
    str_rule_pkg.validate_name(RPAD(UNISTR('\00E1'), 200, UNISTR('\00E1')));
    l_raised := FALSE; BEGIN str_rule_pkg.validate_name(RPAD(UNISTR('\00E1'), 201, UNISTR('\00E1'))); EXCEPTION WHEN str_rule_pkg.e_invalid_name THEN l_raised := TRUE; END;
    assert_true(l_raised, 'Limite multibyte deve usar caracteres.'); pass;

    start_test('Slug aplica normalizacao canonica');
    assert_equals(
      str_rule_pkg.normalize_slug(
        '  Brech' || UNISTR('\00F3') || ' ' || UNISTR('\00C1') || 'gil 2026  '
      ),
      'brecho-agil-2026',
      'Slug com acento incorreto.'
    );
    assert_equals(str_rule_pkg.normalize_slug('--Loja---Nova--'), 'loja-nova', 'Hifens incorretos.');
    assert_equals(str_rule_pkg.normalize_slug('Loja & Nova!'), 'loja-nova', 'Especiais incorretos.'); pass;

    start_test('Slug translitera integralmente o mapa aprovado');
    assert_equals(
      str_rule_pkg.normalize_slug(
        UNISTR(
          '\00E1\00E0\00E2\00E3\00E4 ' ||
          '\00E9\00E8\00EA\00EB ' ||
          '\00ED\00EC\00EE\00EF ' ||
          '\00F3\00F2\00F4\00F5\00F6 ' ||
          '\00FA\00F9\00FB\00FC ' ||
          '\00E7 \00F1'
        )
      ),
      'aaaaa-eeee-iiii-ooooo-uuuu-c-n',
      'Mapa integral de transliteracao incorreto.'
    );
    pass;

    start_test('Slug valida obrigatoriedade formato e limites');
    str_rule_pkg.validate_slug('slug-valido');
    str_rule_pkg.validate_slug(RPAD('a', 100, 'a'));
    l_raised := FALSE; BEGIN str_rule_pkg.validate_slug(NULL); EXCEPTION WHEN str_rule_pkg.e_slug_required THEN l_raised := TRUE; END;
    assert_true(l_raised, 'Slug NULL deveria falhar.');
    l_raised := FALSE; BEGIN str_rule_pkg.validate_slug('!@#'); EXCEPTION WHEN str_rule_pkg.e_slug_required THEN l_raised := TRUE; END;
    assert_true(l_raised, 'Slug removivel deveria falhar.');
    l_raised := FALSE; BEGIN str_rule_pkg.validate_slug(RPAD('a', 101, 'a')); EXCEPTION WHEN str_rule_pkg.e_invalid_slug THEN l_raised := TRUE; END;
    assert_true(l_raised, 'Slug acima do limite deveria falhar.'); pass;

    start_test('Slug e deterministico e idempotente');
    l_first := str_rule_pkg.normalize_slug(
      '  S' || UNISTR('\00E3') || 'o---Paulo & Moda '
    );
    l_second := str_rule_pkg.normalize_slug(l_first);
    assert_equals(l_first, 'sao-paulo-moda', 'Slug esperado incorreto.');
    assert_equals(l_second, l_first, 'Slug deve ser idempotente.'); pass;

    start_test('Descricao aceita NULL, TRIM, limite e multibyte');
    assert_null(str_rule_pkg.normalize_optional_text('   '), 'Espacos devem virar NULL.');
    assert_equals(str_rule_pkg.normalize_optional_text('  texto  '), 'texto', 'Descricao deve usar TRIM.');
    str_rule_pkg.validate_description(NULL);
    str_rule_pkg.validate_description(RPAD(UNISTR('\00E1'), 1000, UNISTR('\00E1')));
    l_raised := FALSE; BEGIN str_rule_pkg.validate_description(RPAD(UNISTR('\00E1'), 1001, UNISTR('\00E1'))); EXCEPTION WHEN str_rule_pkg.e_invalid_description THEN l_raised := TRUE; END;
    assert_true(l_raised, 'Descricao acima do limite deveria falhar.'); pass;

    start_test('Logo URL valida opcionalidade protocolo e tamanho');
    str_rule_pkg.validate_logo_url(NULL);
    str_rule_pkg.validate_logo_url('   ');
    str_rule_pkg.validate_logo_url('https://example.invalid/logo.png');
    str_rule_pkg.validate_logo_url('http://' || RPAD('a', 993, 'a'));
    l_raised := FALSE; BEGIN str_rule_pkg.validate_logo_url('ftp://example.invalid/logo'); EXCEPTION WHEN str_rule_pkg.e_invalid_logo_url THEN l_raised := TRUE; END;
    assert_true(l_raised, 'Protocolo de logo deveria falhar.');
    l_raised := FALSE; BEGIN str_rule_pkg.validate_logo_url('https://' || RPAD('a', 994, 'a')); EXCEPTION WHEN str_rule_pkg.e_invalid_logo_url THEN l_raised := TRUE; END;
    assert_true(l_raised, 'Logo acima do limite deveria falhar.'); pass;

    start_test('Cover URL valida opcionalidade protocolo e tamanho');
    str_rule_pkg.validate_cover_url(NULL);
    str_rule_pkg.validate_cover_url('   ');
    str_rule_pkg.validate_cover_url('https://example.invalid/cover.png');
    str_rule_pkg.validate_cover_url('http://' || RPAD('b', 993, 'b'));
    l_raised := FALSE; BEGIN str_rule_pkg.validate_cover_url('cover.invalid'); EXCEPTION WHEN str_rule_pkg.e_invalid_cover_url THEN l_raised := TRUE; END;
    assert_true(l_raised, 'Cover sem protocolo deveria falhar.');
    l_raised := FALSE; BEGIN str_rule_pkg.validate_cover_url('https://' || RPAD('b', 994, 'b')); EXCEPTION WHEN str_rule_pkg.e_invalid_cover_url THEN l_raised := TRUE; END;
    assert_true(l_raised, 'Cover acima do limite deveria falhar.'); pass;

    start_test('Locale aceita apenas pt-BR normalizado por TRIM');
    str_rule_pkg.validate_locale_code(' pt-BR ');
    FOR i IN 1..4 LOOP
      l_raised := FALSE;
      BEGIN str_rule_pkg.validate_locale_code(CASE i WHEN 1 THEN NULL WHEN 2 THEN 'pt-br' WHEN 3 THEN 'en-US' ELSE RPAD('p', 11, 'p') END);
      EXCEPTION WHEN str_rule_pkg.e_invalid_locale THEN l_raised := TRUE; END;
      assert_true(l_raised, 'Locale invalido foi aceito.');
    END LOOP; pass;

    start_test('Timezone aceita apenas America Sao Paulo');
    str_rule_pkg.validate_timezone_name(' America/Sao_Paulo ');
    FOR i IN 1..3 LOOP
      l_raised := FALSE;
      BEGIN str_rule_pkg.validate_timezone_name(CASE i WHEN 1 THEN NULL WHEN 2 THEN 'UTC' ELSE RPAD('A', 65, 'A') END);
      EXCEPTION WHEN str_rule_pkg.e_invalid_timezone THEN l_raised := TRUE; END;
      assert_true(l_raised, 'Timezone invalido foi aceito.');
    END LOOP; pass;

    start_test('Status aceita exatamente quatro valores e normaliza');
    FOR i IN 1..l_statuses.COUNT LOOP str_rule_pkg.validate_status(' ' || LOWER(l_statuses(i)) || ' '); END LOOP;
    assert_equals(str_rule_pkg.normalize_status(' active '), 'ACTIVE', 'Status nao normalizado.');
    FOR i IN 1..3 LOOP
      l_raised := FALSE;
      BEGIN str_rule_pkg.validate_status(CASE i WHEN 1 THEN NULL WHEN 2 THEN '' ELSE 'INACTIVE' END);
      EXCEPTION WHEN str_rule_pkg.e_invalid_status THEN l_raised := TRUE; END;
      assert_true(l_raised, 'Status invalido foi aceito.');
    END LOOP; pass;

    start_test('Matriz classifica todas as 16 transicoes');
    FOR i IN 1..4 LOOP
      FOR j IN 1..4 LOOP
        l_raised := FALSE;
        BEGIN str_rule_pkg.validate_status_transition(l_statuses(i), l_statuses(j));
        EXCEPTION WHEN str_rule_pkg.e_invalid_transition THEN l_raised := TRUE; END;
        IF transition_allowed(l_statuses(i), l_statuses(j)) THEN
          assert_false(l_raised, 'Transicao aprovada foi rejeitada.');
        ELSE
          assert_true(l_raised, 'Transicao proibida foi aceita.');
        END IF;
      END LOOP;
    END LOOP; pass;

    start_test('CLOSED bloqueia alteracao funcional e saida de estado');
    l_raised := FALSE; BEGIN str_rule_pkg.assert_store_editable('CLOSED'); EXCEPTION WHEN str_rule_pkg.e_store_closed THEN l_raised := TRUE; END;
    assert_true(l_raised, 'CLOSED deveria bloquear alteracao.');
    l_raised := FALSE; BEGIN str_rule_pkg.validate_status_transition('CLOSED', 'ACTIVE'); EXCEPTION WHEN str_rule_pkg.e_invalid_transition THEN l_raised := TRUE; END;
    assert_true(l_raised, 'CLOSED nao pode reabrir.');
    reset_patch(l_patch);
    l_raised := FALSE; BEGIN str_rule_pkg.normalize_and_validate_patch('CLOSED', 'slug', l_patch); EXCEPTION WHEN str_rule_pkg.e_store_closed THEN l_raised := TRUE; END;
    assert_true(l_raised, 'PATCH vazio em CLOSED deve acusar encerramento.'); pass;

    start_test('Slug efetivamente alterado somente em DRAFT');
    str_rule_pkg.validate_slug_change('DRAFT', TRUE, 'slug-atual', 'slug-novo');
    FOR i IN 2..4 LOOP
      l_raised := FALSE;
      BEGIN str_rule_pkg.validate_slug_change(l_statuses(i), TRUE, 'slug-atual', 'slug-novo');
      EXCEPTION WHEN str_rule_pkg.e_slug_not_editable THEN l_raised := TRUE; END;
      assert_true(l_raised, 'Estado nao DRAFT permitiu alterar slug.');
    END LOOP; pass;

    start_test('Slug ausente ou igual normalizado nao e alteracao');
    FOR i IN 1..4 LOOP
      str_rule_pkg.validate_slug_change(l_statuses(i), FALSE, 'slug-atual', 'outro');
      str_rule_pkg.validate_slug_change(l_statuses(i), TRUE, 'Slug Atual', 'slug-atual');
    END LOOP; pass;

    start_test('PATCH vazio rejeita todas as flags falsas');
    reset_patch(l_patch);
    l_raised := FALSE; BEGIN str_rule_pkg.validate_patch_not_empty(l_patch); EXCEPTION WHEN str_rule_pkg.e_empty_patch THEN l_raised := TRUE; END;
    assert_true(l_raised, 'PATCH vazio deveria falhar.'); pass;

    start_test('Cada flag individual torna PATCH nao vazio');
    FOR i IN 1..7 LOOP
      reset_patch(l_patch);
      CASE i WHEN 1 THEN l_patch.set_name := TRUE; WHEN 2 THEN l_patch.set_slug := TRUE;
        WHEN 3 THEN l_patch.set_description := TRUE; WHEN 4 THEN l_patch.set_logo_url := TRUE;
        WHEN 5 THEN l_patch.set_cover_url := TRUE; WHEN 6 THEN l_patch.set_locale_code := TRUE;
        WHEN 7 THEN l_patch.set_timezone_name := TRUE; END CASE;
      str_rule_pkg.validate_patch_not_empty(l_patch);
    END LOOP; pass;

    start_test('Campo ausente nao e validado');
    reset_patch(l_patch);
    l_patch.name_value := NULL; l_patch.slug_value := '---';
    l_patch.set_description := TRUE; l_patch.description_value := ' texto ';
    str_rule_pkg.normalize_and_validate_patch('DRAFT', 'slug-atual', l_patch);
    assert_equals(l_patch.description_value, 'texto', 'Campo presente nao normalizado.');
    assert_equals(
      l_patch.slug_value,
      '---',
      'Campo ausente foi alterado ou normalizado.'
    );
    pass;

    start_test('Obrigatorios presentes com NULL falham');
    reset_patch(l_patch); l_patch.set_name := TRUE;
    l_raised := FALSE; BEGIN str_rule_pkg.normalize_and_validate_patch('DRAFT', 'slug', l_patch); EXCEPTION WHEN str_rule_pkg.e_name_required THEN l_raised := TRUE; END;
    assert_true(l_raised, 'Name NULL deveria falhar.');
    reset_patch(l_patch); l_patch.set_slug := TRUE;
    l_raised := FALSE; BEGIN str_rule_pkg.normalize_and_validate_patch('DRAFT', 'slug', l_patch); EXCEPTION WHEN str_rule_pkg.e_slug_required THEN l_raised := TRUE; END;
    assert_true(l_raised, 'Slug NULL deveria falhar.'); pass;

    start_test('Anulaveis presentes com NULL permitem limpeza');
    reset_patch(l_patch);
    l_patch.set_description := TRUE; l_patch.set_logo_url := TRUE; l_patch.set_cover_url := TRUE;
    str_rule_pkg.normalize_and_validate_patch('DRAFT', 'slug', l_patch);
    assert_true(l_patch.description_value IS NULL AND l_patch.logo_url_value IS NULL AND l_patch.cover_url_value IS NULL, 'Limpeza deveria ser aceita.'); pass;

    start_test('PATCH normaliza todos os campos presentes');
    reset_patch(l_patch);
    l_patch.set_name := TRUE; l_patch.name_value := ' Loja  Nova ';
    l_patch.set_slug := TRUE;
    l_patch.slug_value := ' Loja ' || UNISTR('\00C1') || 'gil ';
    l_patch.set_description := TRUE; l_patch.description_value := ' texto ';
    l_patch.set_logo_url := TRUE; l_patch.logo_url_value := ' https://example.invalid/logo ';
    l_patch.set_cover_url := TRUE; l_patch.cover_url_value := ' http://example.invalid/cover ';
    l_patch.set_locale_code := TRUE; l_patch.locale_code_value := ' pt-BR ';
    l_patch.set_timezone_name := TRUE; l_patch.timezone_value := ' America/Sao_Paulo ';
    str_rule_pkg.normalize_and_validate_patch('DRAFT', 'slug-antigo', l_patch);
    assert_equals(l_patch.name_value, 'Loja Nova', 'Nome PATCH incorreto.');
    assert_equals(l_patch.slug_value, 'loja-agil', 'Slug PATCH incorreto.');
    assert_equals(l_patch.locale_code_value, 'pt-BR', 'Locale PATCH incorreto.'); pass;

    start_test('Criacao minima aplica defaults puros');
    l_creation.name_value := ' Loja  Nova ';
    l_creation.slug_value := ' Loja Nova ';
    l_creation.description_value := NULL; l_creation.logo_url_value := NULL; l_creation.cover_url_value := NULL;
    l_creation.locale_code_value := NULL; l_creation.timezone_value := NULL; l_creation.status_value := 'ACTIVE';
    str_rule_pkg.normalize_and_validate_creation(l_creation);
    assert_equals(l_creation.name_value, 'Loja Nova', 'Nome de criacao incorreto.');
    assert_equals(l_creation.slug_value, 'loja-nova', 'Slug de criacao incorreto.');
    assert_equals(l_creation.status_value, 'DRAFT', 'Status inicial deve ser DRAFT.');
    assert_equals(l_creation.locale_code_value, 'pt-BR', 'Locale default incorreto.');
    assert_equals(l_creation.timezone_value, 'America/Sao_Paulo', 'Timezone default incorreto.'); pass;

    start_test('Criacao completa normaliza e valida opcionais');
    l_creation.name_value := 'Brech' || UNISTR('\00F3') || ' Completo';
    l_creation.slug_value := 'Brech' || UNISTR('\00F3') || ' Completo';
    l_creation.description_value := ' descricao '; l_creation.logo_url_value := ' https://example.invalid/logo ';
    l_creation.cover_url_value := ' https://example.invalid/cover '; l_creation.locale_code_value := 'pt-BR';
    l_creation.timezone_value := 'America/Sao_Paulo';
    str_rule_pkg.normalize_and_validate_creation(l_creation);
    assert_equals(l_creation.slug_value, 'brecho-completo', 'Slug completo incorreto.');
    assert_equals(l_creation.description_value, 'descricao', 'Descricao completa incorreta.'); pass;

    start_test('Criacao rejeita nome e slug invalidos');
    l_creation.name_value := NULL; l_creation.slug_value := 'slug'; l_creation.locale_code_value := NULL; l_creation.timezone_value := NULL;
    l_raised := FALSE; BEGIN str_rule_pkg.normalize_and_validate_creation(l_creation); EXCEPTION WHEN str_rule_pkg.e_name_required THEN l_raised := TRUE; END;
    assert_true(l_raised, 'Criacao sem nome deveria falhar.');
    l_creation.name_value := 'Loja'; l_creation.slug_value := '!!!';
    l_raised := FALSE; BEGIN str_rule_pkg.normalize_and_validate_creation(l_creation); EXCEPTION WHEN str_rule_pkg.e_slug_required THEN l_raised := TRUE; END;
    assert_true(l_raised, 'Criacao sem slug efetivo deveria falhar.'); pass;

    start_test('Elegibilidade exige ACCOUNT existente e ACTIVE');
    str_rule_pkg.assert_account_eligible(TRUE, ' active ');
    FOR i IN 1..4 LOOP
      l_raised := FALSE;
      BEGIN
        str_rule_pkg.assert_account_eligible(
          CASE i WHEN 1 THEN FALSE WHEN 4 THEN NULL ELSE TRUE END,
          CASE i WHEN 1 THEN 'ACTIVE' WHEN 2 THEN 'BLOCKED' WHEN 3 THEN NULL ELSE 'ACTIVE' END
        );
      EXCEPTION WHEN str_rule_pkg.e_account_ineligible THEN l_raised := TRUE; END;
      assert_true(l_raised, 'ACCOUNT inelegivel foi aceita.');
    END LOOP; pass;

    start_test('Catalogo constroi os 16 erros conhecidos');
    assert_equals(
      str_rule_pkg.c_code_slug_already_used,
      'BEX-STORE-016',
      'Codigo de conflito de slug incorreto.'
    );
    FOR i IN 1..16 LOOP
      str_rule_pkg.build_known_error(error_code(i), l_public_error, l_error_policy);
      assert_equals(l_public_error.code, error_code(i), 'Codigo conhecido incorreto.');
      IF i <= 10 OR i = 12 THEN
        assert_equals(l_public_error.category, 'VALIDATION_ERROR', 'Categoria conhecida incorreta.');
      ELSIF i = 16 THEN
        assert_equals(
          l_public_error.category,
          core_error_pkg.c_category_conflict,
          'Categoria de conflito de slug incorreta.'
        );
      ELSE
        assert_equals(l_public_error.category, 'BUSINESS_ERROR', 'Categoria conhecida incorreta.');
      END IF;
      assert_equals(l_public_error.external_message, expected_message(i), 'Mensagem conhecida incorreta.');
      assert_equals(l_error_policy.severity, 'ERROR', 'Severidade conhecida incorreta.');
      assert_false(l_public_error.retryable, 'Erro conhecido nao deve ser retryable.');
      assert_false(l_error_policy.should_log, 'Erro conhecido nao deve solicitar log.');
    END LOOP; pass;

    start_test('Constantes publicas coincidem com CK_STR_STATUS');
    assert_equals(str_rule_pkg.c_status_draft, 'DRAFT', 'DRAFT incorreto.');
    assert_equals(str_rule_pkg.c_status_active, 'ACTIVE', 'ACTIVE incorreto.');
    assert_equals(str_rule_pkg.c_status_suspended, 'SUSPENDED', 'SUSPENDED incorreto.');
    assert_equals(str_rule_pkg.c_status_closed, 'CLOSED', 'CLOSED incorreto.'); pass;

    start_test('Rule nao possui SQL, transacao, JSON ou geracao tecnica');
    SELECT COUNT(*) INTO l_count FROM USER_SOURCE
     WHERE NAME = 'STR_RULE_PKG' AND TYPE IN ('PACKAGE', 'PACKAGE BODY')
       AND REGEXP_LIKE(
         UPPER(TEXT),
         '(^|[^A-Z_])(SELECT|INSERT|UPDATE|DELETE|MERGE|COMMIT|ROLLBACK|SAVEPOINT|SYSTIMESTAMP|SYSDATE|SYS_GUID)([^A-Z_]|$)|' ||
         'AUTONOMOUS_TRANSACTION|EXECUTE[[:space:]]+IMMEDIATE|STR_REPOSITORY_PKG|' ||
         'CORE_RESPONSE_PKG|CORE_JSON_PKG|CORE_CONTEXT_PKG|JSON_OBJECT|JSON_ARRAY'
       );
    assert_true(l_count = 0, 'Rule contem elemento proibido.'); pass;

    start_test('Normalizadores nao geram Public ID ou timestamp');
    assert_equals(str_rule_pkg.normalize_name(' Loja '), 'Loja', 'Nome deterministico incorreto.');
    assert_equals(str_rule_pkg.normalize_slug(' Loja '), 'loja', 'Slug deterministico incorreto.');
    assert_equals(str_rule_pkg.normalize_status(' draft '), 'DRAFT', 'Status deterministico incorreto.'); pass;
  END run_tests;
BEGIN
  run_tests;
  IF g_test_count <> c_expected_test_count THEN
    fail('Quantidade de testes invalida. Esperado=34 executado=' || g_test_count);
  END IF;
  DBMS_OUTPUT.PUT_LINE('STR_RULE_PKG: PASSED');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('FAIL - ' || NVL(g_current_test, 'initialization'));
    RAISE;
END;
/
