SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  g_count        PLS_INTEGER := 0;
  g_current_test VARCHAR2(200);
  c_expected     CONSTANT PLS_INTEGER := 18;
  l_creation     cat_rule_pkg.t_category_creation;
  l_raised       BOOLEAN;
  l_count        PLS_INTEGER;

  PROCEDURE fail(p_message IN VARCHAR2) IS
  BEGIN
    RAISE_APPLICATION_ERROR(-20999, p_message);
  END fail;

  PROCEDURE assert_true(p_condition BOOLEAN, p_message VARCHAR2) IS
  BEGIN
    IF p_condition IS NULL OR NOT p_condition THEN fail(p_message); END IF;
  END assert_true;

  PROCEDURE start_test(p_name VARCHAR2) IS
  BEGIN
    g_current_test := p_name;
  END start_test;

  PROCEDURE pass IS
  BEGIN
    g_count := g_count + 1;
    DBMS_OUTPUT.PUT_LINE(
      'PASS ' || LPAD(g_count, 2, '0') || ' - ' || g_current_test
    );
  END pass;
BEGIN
  start_test('Specification esta valida');
  SELECT COUNT(*) INTO l_count FROM USER_OBJECTS
   WHERE OBJECT_NAME = 'CAT_RULE_PKG'
     AND OBJECT_TYPE = 'PACKAGE'
     AND STATUS = 'VALID';
  assert_true(l_count = 1, 'Specification invalida.'); pass;

  start_test('Body esta valido e sem USER_ERRORS');
  SELECT COUNT(*) INTO l_count FROM USER_OBJECTS
   WHERE OBJECT_NAME = 'CAT_RULE_PKG'
     AND OBJECT_TYPE = 'PACKAGE BODY'
     AND STATUS = 'VALID';
  assert_true(l_count = 1, 'Body invalido.');
  SELECT COUNT(*) INTO l_count FROM USER_ERRORS
   WHERE NAME = 'CAT_RULE_PKG';
  assert_true(l_count = 0, 'Package possui USER_ERRORS.'); pass;

  start_test('Nome normaliza espacos');
  assert_true(
    cat_rule_pkg.normalize_name('  Moda   Feminina  ') = 'Moda Feminina',
    'Nome nao foi normalizado.'
  ); pass;

  start_test('Nome obrigatorio e limite sao validados');
  l_raised := FALSE;
  BEGIN cat_rule_pkg.validate_name(' ');
  EXCEPTION WHEN cat_rule_pkg.e_name_required THEN l_raised := TRUE; END;
  assert_true(l_raised, 'Nome vazio deveria falhar.');
  l_raised := FALSE;
  BEGIN cat_rule_pkg.validate_name(RPAD('x', 201, 'x'));
  EXCEPTION WHEN cat_rule_pkg.e_invalid_name THEN l_raised := TRUE; END;
  assert_true(l_raised, 'Nome longo deveria falhar.'); pass;

  start_test('Nome conta caracteres e aceita limite');
  cat_rule_pkg.validate_name(
    RPAD(UNISTR('\00E1'), 200, UNISTR('\00E1'))
  ); pass;

  start_test('Slug aplica forma canonica');
  assert_true(
    cat_rule_pkg.normalize_slug(
      '  Moda ' || UNISTR('\00CD') || 'ntima & Praia  '
    ) =
      'moda-intima-praia',
    'Slug canonico incorreto.'
  ); pass;

  start_test('Slug remove separadores repetidos');
  assert_true(
    cat_rule_pkg.normalize_slug('---Moda   Praia---') = 'moda-praia',
    'Separadores do slug incorretos.'
  ); pass;

  start_test('Slug obrigatorio e formato sao validados');
  l_raised := FALSE;
  BEGIN cat_rule_pkg.validate_slug('!!!');
  EXCEPTION WHEN cat_rule_pkg.e_slug_required THEN l_raised := TRUE; END;
  assert_true(l_raised, 'Slug vazio deveria falhar.');
  l_raised := FALSE;
  BEGIN cat_rule_pkg.validate_slug(RPAD('a', 121, 'a'));
  EXCEPTION WHEN cat_rule_pkg.e_invalid_slug THEN l_raised := TRUE; END;
  assert_true(l_raised, 'Slug longo deveria falhar.'); pass;

  start_test('Slug normalizado e idempotente');
  assert_true(
    cat_rule_pkg.normalize_slug(
      cat_rule_pkg.normalize_slug('Moda Casual')
    ) = 'moda-casual',
    'Slug nao e idempotente.'
  ); pass;

  start_test('Descricao aceita NULL e aplica TRIM');
  assert_true(
    cat_rule_pkg.normalize_description(NULL) IS NULL
    AND cat_rule_pkg.normalize_description('  Texto  ') = 'Texto',
    'Descricao nao foi normalizada.'
  ); pass;

  start_test('Descricao valida limite');
  l_raised := FALSE;
  BEGIN cat_rule_pkg.validate_description(RPAD('x', 1001, 'x'));
  EXCEPTION WHEN cat_rule_pkg.e_invalid_description THEN l_raised := TRUE; END;
  assert_true(l_raised, 'Descricao longa deveria falhar.'); pass;

  start_test('Status normaliza valores oficiais');
  assert_true(
    cat_rule_pkg.normalize_status(' active ') = 'ACTIVE'
    AND cat_rule_pkg.normalize_status('inactive') = 'INACTIVE',
    'Status nao foi normalizado.'
  ); pass;

  start_test('Status rejeita valor invalido');
  l_raised := FALSE;
  BEGIN cat_rule_pkg.validate_status('BLOCKED');
  EXCEPTION WHEN cat_rule_pkg.e_invalid_status THEN l_raised := TRUE; END;
  assert_true(l_raised, 'Status invalido deveria falhar.'); pass;

  start_test('Transicoes ACTIVE e INACTIVE sao validas');
  cat_rule_pkg.validate_status_transition('ACTIVE', 'INACTIVE');
  cat_rule_pkg.validate_status_transition('INACTIVE', 'ACTIVE'); pass;

  start_test('Transicao sem mudanca e rejeitada');
  l_raised := FALSE;
  BEGIN cat_rule_pkg.validate_status_transition('ACTIVE', ' active ');
  EXCEPTION WHEN cat_rule_pkg.e_invalid_transition THEN l_raised := TRUE; END;
  assert_true(l_raised, 'Transicao sem mudanca deveria falhar.'); pass;

  start_test('Criacao completa normaliza e valida');
  l_creation.name_value := '  Moda   Circular ';
  l_creation.slug_value := ' Moda Circular ';
  l_creation.description_value := '  Categoria oficial  ';
  l_creation.status_value := ' active ';
  cat_rule_pkg.normalize_and_validate_creation(l_creation);
  assert_true(
    l_creation.name_value = 'Moda Circular'
    AND l_creation.slug_value = 'moda-circular'
    AND l_creation.description_value = 'Categoria oficial'
    AND l_creation.status_value = 'ACTIVE',
    'Criacao nao foi preparada.'
  ); pass;

  start_test('Criacao minima aceita descricao NULL');
  l_creation.name_value := 'Calcados';
  l_creation.slug_value := 'calcados';
  l_creation.description_value := NULL;
  l_creation.status_value := 'ACTIVE';
  cat_rule_pkg.normalize_and_validate_creation(l_creation);
  assert_true(
    l_creation.description_value IS NULL,
    'Descricao NULL deveria ser preservada.'
  ); pass;

  start_test('Rule nao possui SQL Core JSON ou transacao');
  SELECT COUNT(*) INTO l_count FROM USER_SOURCE
   WHERE NAME = 'CAT_RULE_PKG'
     AND TYPE IN ('PACKAGE', 'PACKAGE BODY')
     AND REGEXP_LIKE(
       UPPER(TEXT),
       '(^|[^A-Z_])(SELECT|INSERT|UPDATE|DELETE|MERGE|COMMIT|ROLLBACK)([^A-Z_]|$)|' ||
       'CORE_|JSON|HTTP|ORDS|APEX|EXECUTE[[:space:]]+IMMEDIATE|DBMS_SQL'
     );
  assert_true(l_count = 0, 'Rule possui elemento proibido.'); pass;

  IF g_count <> c_expected THEN
    fail(
      'Quantidade invalida. Esperado=' || c_expected ||
      ' executado=' || g_count
    );
  END IF;
  DBMS_OUTPUT.PUT_LINE('CAT_RULE_PKG: PASSED');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('FAIL - ' || NVL(g_current_test, 'initialization'));
    RAISE;
END;
/
