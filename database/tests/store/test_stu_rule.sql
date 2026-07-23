SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  g_test_count   PLS_INTEGER := 0;
  g_current_test VARCHAR2(200);

  c_expected_test_count CONSTANT PLS_INTEGER := 18;

  PROCEDURE fail(p_message IN VARCHAR2) IS
  BEGIN
    RAISE_APPLICATION_ERROR(-20999, p_message);
  END fail;

  PROCEDURE start_test(p_name IN VARCHAR2) IS
  BEGIN
    g_current_test := p_name;
  END start_test;

  PROCEDURE pass IS
  BEGIN
    g_test_count := g_test_count + 1;
  END pass;

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

  PROCEDURE assert_equals(
    p_actual   IN VARCHAR2,
    p_expected IN VARCHAR2,
    p_message  IN VARCHAR2
  ) IS
  BEGIN
    IF p_actual IS NULL
       OR p_expected IS NULL
       OR p_actual <> p_expected THEN
      fail(
        p_message ||
        ' Esperado=[' || NVL(p_expected, 'NULL') ||
        '] Atual=[' || NVL(p_actual, 'NULL') || ']'
      );
    END IF;
  END assert_equals;

  PROCEDURE assert_null(
    p_actual  IN VARCHAR2,
    p_message IN VARCHAR2
  ) IS
  BEGIN
    IF p_actual IS NOT NULL THEN
      fail(p_message);
    END IF;
  END assert_null;

  PROCEDURE run_tests IS
    l_raised       BOOLEAN;
    l_count        PLS_INTEGER;
    l_public_error core_error_pkg.t_public_error;
    l_error_policy core_error_pkg.t_error_policy;
  BEGIN
    start_test('Constantes publicas de papel');
    assert_equals(stu_rule_pkg.c_role_admin, 'ADMIN', 'ADMIN incorreto.');
    assert_equals(stu_rule_pkg.c_role_manager, 'MANAGER', 'MANAGER incorreto.');
    assert_equals(
      stu_rule_pkg.c_role_attendant,
      'ATTENDANT',
      'ATTENDANT incorreto.'
    );
    assert_equals(
      stu_rule_pkg.c_role_collaborator,
      'COLLABORATOR',
      'COLLABORATOR incorreto.'
    );
    pass;

    start_test('Constantes publicas de status');
    assert_equals(
      stu_rule_pkg.c_status_active,
      'ACTIVE',
      'ACTIVE incorreto.'
    );
    assert_equals(
      stu_rule_pkg.c_status_inactive,
      'INACTIVE',
      'INACTIVE incorreto.'
    );
    pass;

    start_test('Normalizacao de papel remove espacos e converte caixa');
    assert_equals(
      stu_rule_pkg.normalize_role('  aDmIn  '),
      'ADMIN',
      'Papel nao foi normalizado.'
    );
    assert_equals(
      stu_rule_pkg.normalize_role(' manager '),
      'MANAGER',
      'Papel minusculo nao foi normalizado.'
    );
    pass;

    start_test('Normalizacao de status remove espacos e converte caixa');
    assert_equals(
      stu_rule_pkg.normalize_status('  aCtIvE  '),
      'ACTIVE',
      'Status nao foi normalizado.'
    );
    assert_equals(
      stu_rule_pkg.normalize_status(' inactive '),
      'INACTIVE',
      'Status minusculo nao foi normalizado.'
    );
    pass;

    start_test('Normalizacao preserva NULL e converte somente espacos em NULL');
    assert_null(stu_rule_pkg.normalize_role(NULL), 'Papel NULL deve permanecer NULL.');
    assert_null(stu_rule_pkg.normalize_role('   '), 'Papel vazio deve virar NULL.');
    assert_null(
      stu_rule_pkg.normalize_status(NULL),
      'Status NULL deve permanecer NULL.'
    );
    assert_null(
      stu_rule_pkg.normalize_status('   '),
      'Status vazio deve virar NULL.'
    );
    pass;

    start_test('Todos os papeis validos sao aceitos');
    assert_true(stu_rule_pkg.is_valid_role('ADMIN'), 'ADMIN deve ser valido.');
    assert_true(stu_rule_pkg.is_valid_role('manager'), 'manager deve ser valido.');
    assert_true(
      stu_rule_pkg.is_valid_role(' Attendant '),
      'Attendant deve ser valido.'
    );
    assert_true(
      stu_rule_pkg.is_valid_role('COLLABORATOR'),
      'COLLABORATOR deve ser valido.'
    );
    pass;

    start_test('Papeis invalidos, nulos e vazios sao rejeitados');
    assert_false(stu_rule_pkg.is_valid_role(NULL), 'NULL nao deve ser valido.');
    assert_false(stu_rule_pkg.is_valid_role('   '), 'Vazio nao deve ser valido.');
    assert_false(stu_rule_pkg.is_valid_role('OWNER'), 'OWNER nao deve ser valido.');
    assert_false(
      stu_rule_pkg.is_valid_role('ADMIN USER'),
      'Espaco interno nao deve ser removido.'
    );
    pass;

    start_test('Todos os status validos sao aceitos');
    assert_true(stu_rule_pkg.is_valid_status('ACTIVE'), 'ACTIVE deve ser valido.');
    assert_true(
      stu_rule_pkg.is_valid_status(' inactive '),
      'inactive deve ser valido.'
    );
    pass;

    start_test('Status invalidos, nulos e vazios sao rejeitados');
    assert_false(stu_rule_pkg.is_valid_status(NULL), 'NULL nao deve ser valido.');
    assert_false(stu_rule_pkg.is_valid_status('   '), 'Vazio nao deve ser valido.');
    assert_false(
      stu_rule_pkg.is_valid_status('PENDING'),
      'PENDING nao deve ser valido.'
    );
    pass;

    start_test('require_valid_role aceita valores normalizaveis');
    stu_rule_pkg.require_valid_role(' admin ');
    stu_rule_pkg.require_valid_role('MANAGER');
    stu_rule_pkg.require_valid_role('attendant');
    stu_rule_pkg.require_valid_role(' collaborator ');
    pass;

    start_test('require_valid_role lanca excecao conhecida');
    l_raised := FALSE;
    BEGIN
      stu_rule_pkg.require_valid_role(NULL);
    EXCEPTION
      WHEN stu_rule_pkg.e_invalid_role THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'Papel NULL deveria lancar e_invalid_role.');

    l_raised := FALSE;
    BEGIN
      stu_rule_pkg.require_valid_role('OWNER');
    EXCEPTION
      WHEN stu_rule_pkg.e_invalid_role THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'Papel invalido deveria lancar e_invalid_role.');
    pass;

    start_test('require_valid_status aceita valores normalizaveis');
    stu_rule_pkg.require_valid_status(' active ');
    stu_rule_pkg.require_valid_status('INACTIVE');
    pass;

    start_test('require_valid_status lanca excecao conhecida');
    l_raised := FALSE;
    BEGIN
      stu_rule_pkg.require_valid_status(' ');
    EXCEPTION
      WHEN stu_rule_pkg.e_invalid_status THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'Status vazio deveria lancar e_invalid_status.');

    l_raised := FALSE;
    BEGIN
      stu_rule_pkg.require_valid_status('BLOCKED');
    EXCEPTION
      WHEN stu_rule_pkg.e_invalid_status THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'Status invalido deveria lancar e_invalid_status.');
    pass;

    start_test('Transicoes entre ACTIVE e INACTIVE sao validas');
    stu_rule_pkg.validate_transition('ACTIVE', 'INACTIVE');
    stu_rule_pkg.validate_transition(' inactive ', ' active ');
    pass;

    start_test('Transicoes idempotentes sao validas');
    stu_rule_pkg.validate_transition('active', ' ACTIVE ');
    stu_rule_pkg.validate_transition('INACTIVE', 'inactive');
    pass;

    start_test('Transicao rejeita status de origem ou destino invalido');
    l_raised := FALSE;
    BEGIN
      stu_rule_pkg.validate_transition(NULL, 'ACTIVE');
    EXCEPTION
      WHEN stu_rule_pkg.e_invalid_status THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'Origem NULL deveria lancar e_invalid_status.');

    l_raised := FALSE;
    BEGIN
      stu_rule_pkg.validate_transition('ACTIVE', 'SUSPENDED');
    EXCEPTION
      WHEN stu_rule_pkg.e_invalid_status THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'Destino invalido deveria lancar e_invalid_status.');
    pass;

    start_test('Erros conhecidos usam CORE_ERROR_PKG');
    stu_rule_pkg.build_known_error(
      stu_rule_pkg.c_code_invalid_role,
      l_public_error,
      l_error_policy
    );
    assert_equals(
      l_public_error.code,
      'BEX-STU-001',
      'Codigo de papel incorreto.'
    );
    assert_equals(
      l_public_error.category,
      core_error_pkg.c_category_validation,
      'Categoria de papel incorreta.'
    );
    assert_false(l_public_error.retryable, 'Erro nao deve permitir retry.');
    assert_equals(
      l_error_policy.severity,
      core_error_pkg.c_severity_error,
      'Severidade incorreta.'
    );
    assert_false(l_error_policy.should_log, 'Erro conhecido nao deve solicitar log.');

    stu_rule_pkg.build_known_error(
      stu_rule_pkg.c_code_invalid_status,
      l_public_error,
      l_error_policy
    );
    assert_equals(
      l_public_error.code,
      'BEX-STU-002',
      'Codigo de status incorreto.'
    );

    stu_rule_pkg.build_known_error(
      stu_rule_pkg.c_code_invalid_transition,
      l_public_error,
      l_error_policy
    );
    assert_equals(
      l_public_error.category,
      core_error_pkg.c_category_business,
      'Categoria de transicao incorreta.'
    );
    pass;

    start_test('Package nao possui acesso a dados ou SQL dinamico');
    SELECT COUNT(*)
      INTO l_count
      FROM USER_SOURCE
     WHERE NAME = 'STU_RULE_PKG'
       AND TYPE IN ('PACKAGE', 'PACKAGE BODY')
       AND REGEXP_LIKE(
             UPPER(TEXT),
             '(^|[^A-Z_])(SELECT|INSERT|UPDATE|DELETE|MERGE|COMMIT|ROLLBACK)' ||
             '([^A-Z_]|$)|EXECUTE[[:space:]]+IMMEDIATE|' ||
             'BEX_STORE_USER|STU_REPOSITORY_PKG'
           );
    assert_true(l_count = 0, 'RULE contem acesso a dados ou elemento proibido.');
    pass;
  END run_tests;
BEGIN
  run_tests;

  IF g_test_count <> c_expected_test_count THEN
    fail(
      'Quantidade de testes invalida. Esperado=' ||
      c_expected_test_count || ' executado=' || g_test_count
    );
  END IF;

  DBMS_OUTPUT.PUT_LINE('STU_RULE_PKG: PASSED');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('FAIL - ' || NVL(g_current_test, 'initialization'));
    RAISE;
END;
/
