SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  g_test_count   PLS_INTEGER := 0;
  g_current_test VARCHAR2(200);

  c_expected_test_count CONSTANT PLS_INTEGER := 40;

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

  PROCEDURE assert_equals(
    p_actual   IN VARCHAR2,
    p_expected IN VARCHAR2,
    p_message  IN VARCHAR2
  ) IS
  BEGIN
    IF p_actual IS NULL
       OR p_expected IS NULL
       OR p_actual <> p_expected THEN
      fail(p_message);
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
      'PASS ' || LPAD(g_test_count, 3, '0') || ' - ' || g_current_test
    );
  END pass;

  PROCEDURE assert_expected_exception(
    p_raised  IN BOOLEAN,
    p_message IN VARCHAR2
  ) IS
  BEGIN
    assert_true(p_raised, p_message);
  END assert_expected_exception;

  PROCEDURE run_display_normalize_equals(
    p_name     IN VARCHAR2,
    p_input    IN VARCHAR2,
    p_expected IN VARCHAR2
  ) IS
    l_actual VARCHAR2(32767);
  BEGIN
    start_test(p_name);
    l_actual := pfl_rule_pkg.normalize_display_name(p_input);
    assert_equals(l_actual, p_expected, 'Normalizacao diferente da esperada.');
    pass;
  END run_display_normalize_equals;

  PROCEDURE run_display_normalize_null(
    p_name  IN VARCHAR2,
    p_input IN VARCHAR2
  ) IS
    l_actual VARCHAR2(32767);
  BEGIN
    start_test(p_name);
    l_actual := pfl_rule_pkg.normalize_display_name(p_input);
    assert_null(l_actual, 'Normalizacao deveria retornar NULL.');
    pass;
  END run_display_normalize_null;

  PROCEDURE run_display_normalize_idempotent(
    p_name  IN VARCHAR2,
    p_input IN VARCHAR2
  ) IS
    l_first  VARCHAR2(32767);
    l_second VARCHAR2(32767);
  BEGIN
    start_test(p_name);
    l_first := pfl_rule_pkg.normalize_display_name(p_input);
    l_second := pfl_rule_pkg.normalize_display_name(l_first);
    assert_equals(l_second, l_first, 'Normalizacao deveria ser idempotente.');
    pass;
  END run_display_normalize_idempotent;

  PROCEDURE run_full_normalize_equals(
    p_name     IN VARCHAR2,
    p_input    IN VARCHAR2,
    p_expected IN VARCHAR2
  ) IS
    l_actual VARCHAR2(32767);
  BEGIN
    start_test(p_name);
    l_actual := pfl_rule_pkg.normalize_full_name(p_input);
    assert_equals(l_actual, p_expected, 'Normalizacao diferente da esperada.');
    pass;
  END run_full_normalize_equals;

  PROCEDURE run_full_normalize_null(
    p_name  IN VARCHAR2,
    p_input IN VARCHAR2
  ) IS
    l_actual VARCHAR2(32767);
  BEGIN
    start_test(p_name);
    l_actual := pfl_rule_pkg.normalize_full_name(p_input);
    assert_null(l_actual, 'Normalizacao deveria retornar NULL.');
    pass;
  END run_full_normalize_null;

  PROCEDURE run_full_normalize_idempotent(
    p_name  IN VARCHAR2,
    p_input IN VARCHAR2
  ) IS
    l_first  VARCHAR2(32767);
    l_second VARCHAR2(32767);
  BEGIN
    start_test(p_name);
    l_first := pfl_rule_pkg.normalize_full_name(p_input);
    l_second := pfl_rule_pkg.normalize_full_name(l_first);
    assert_equals(l_second, l_first, 'Normalizacao deveria ser idempotente.');
    pass;
  END run_full_normalize_idempotent;

  PROCEDURE run_validate_display_success(
    p_name  IN VARCHAR2,
    p_input IN VARCHAR2
  ) IS
  BEGIN
    start_test(p_name);
    pfl_rule_pkg.validate_display_name(p_input);
    pass;
  END run_validate_display_success;

  PROCEDURE run_validate_display_failure(
    p_name  IN VARCHAR2,
    p_input IN VARCHAR2
  ) IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test(p_name);
    BEGIN
      pfl_rule_pkg.validate_display_name(p_input);
    EXCEPTION
      WHEN pfl_rule_pkg.e_invalid_display_name THEN
        l_raised := TRUE;
      WHEN OTHERS THEN
        fail('validate_display_name levantou excecao diferente.');
    END;
    assert_expected_exception(l_raised, 'e_invalid_display_name era esperada.');
    pass;
  END run_validate_display_failure;

  PROCEDURE run_validate_full_success(
    p_name  IN VARCHAR2,
    p_input IN VARCHAR2
  ) IS
  BEGIN
    start_test(p_name);
    pfl_rule_pkg.validate_full_name(p_input);
    pass;
  END run_validate_full_success;

  PROCEDURE run_validate_full_failure(
    p_name  IN VARCHAR2,
    p_input IN VARCHAR2
  ) IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test(p_name);
    BEGIN
      pfl_rule_pkg.validate_full_name(p_input);
    EXCEPTION
      WHEN pfl_rule_pkg.e_invalid_full_name THEN
        l_raised := TRUE;
      WHEN OTHERS THEN
        fail('validate_full_name levantou excecao diferente.');
    END;
    assert_expected_exception(l_raised, 'e_invalid_full_name era esperada.');
    pass;
  END run_validate_full_failure;

  PROCEDURE run_validate_birth_success(
    p_name       IN VARCHAR2,
    p_birth_date IN DATE
  ) IS
  BEGIN
    start_test(p_name);
    pfl_rule_pkg.validate_birth_date(p_birth_date);
    pass;
  END run_validate_birth_success;

  PROCEDURE run_validate_birth_failure(
    p_name       IN VARCHAR2,
    p_birth_date IN DATE
  ) IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test(p_name);
    BEGIN
      pfl_rule_pkg.validate_birth_date(p_birth_date);
    EXCEPTION
      WHEN pfl_rule_pkg.e_invalid_birth_date THEN
        l_raised := TRUE;
      WHEN OTHERS THEN
        fail('validate_birth_date levantou excecao diferente.');
    END;
    assert_expected_exception(l_raised, 'e_invalid_birth_date era esperada.');
    pass;
  END run_validate_birth_failure;

  PROCEDURE run_validate_locale_success(
    p_name  IN VARCHAR2,
    p_input IN VARCHAR2
  ) IS
  BEGIN
    start_test(p_name);
    pfl_rule_pkg.validate_locale_code(p_input);
    pass;
  END run_validate_locale_success;

  PROCEDURE run_validate_locale_failure(
    p_name  IN VARCHAR2,
    p_input IN VARCHAR2
  ) IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test(p_name);
    BEGIN
      pfl_rule_pkg.validate_locale_code(p_input);
    EXCEPTION
      WHEN pfl_rule_pkg.e_invalid_locale_code THEN
        l_raised := TRUE;
      WHEN OTHERS THEN
        fail('validate_locale_code levantou excecao diferente.');
    END;
    assert_expected_exception(l_raised, 'e_invalid_locale_code era esperada.');
    pass;
  END run_validate_locale_failure;

  PROCEDURE run_validate_timezone_success(
    p_name  IN VARCHAR2,
    p_input IN VARCHAR2
  ) IS
  BEGIN
    start_test(p_name);
    pfl_rule_pkg.validate_timezone_name(p_input);
    pass;
  END run_validate_timezone_success;

  PROCEDURE run_validate_timezone_failure(
    p_name  IN VARCHAR2,
    p_input IN VARCHAR2
  ) IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test(p_name);
    BEGIN
      pfl_rule_pkg.validate_timezone_name(p_input);
    EXCEPTION
      WHEN pfl_rule_pkg.e_invalid_timezone_name THEN
        l_raised := TRUE;
      WHEN OTHERS THEN
        fail('validate_timezone_name levantou excecao diferente.');
    END;
    assert_expected_exception(l_raised, 'e_invalid_timezone_name era esperada.');
    pass;
  END run_validate_timezone_failure;
BEGIN
  run_display_normalize_null('display name NULL retorna NULL', NULL);
  run_display_normalize_null('display name vazio retorna NULL', '');
  run_display_normalize_equals('display name remove espacos externos', '  Rodrigo Paes  ', 'Rodrigo Paes');
  run_display_normalize_equals('display name remove espacos duplicados', 'Rodrigo    Paes', 'Rodrigo Paes');
  run_display_normalize_idempotent('display name e idempotente', '  Rodrigo    Paes  ');

  run_full_normalize_null('full name NULL retorna NULL', NULL);
  run_full_normalize_null('full name vazio retorna NULL', '');
  run_full_normalize_equals('full name remove espacos externos', '  Rodrigo Paes  ', 'Rodrigo Paes');
  run_full_normalize_equals('full name remove espacos duplicados', 'Rodrigo    Paes', 'Rodrigo Paes');
  run_full_normalize_idempotent('full name e idempotente', '  Rodrigo    Paes  ');

  run_validate_display_success('display name valido e aceito', 'Rodrigo');
  run_validate_display_failure('display name NULL e invalido', NULL);
  run_validate_display_failure('display name vazio e invalido', '');
  run_validate_display_failure('display name com 1 caractere e invalido', 'A');
  run_validate_display_success('display name com 2 caracteres e valido', 'AB');
  run_validate_display_success('display name com 100 caracteres e valido', RPAD('A', 100, 'A'));
  run_validate_display_failure('display name com 101 caracteres e invalido', RPAD('A', 101, 'A'));
  run_validate_display_failure('display name levanta excecao nominal', '   ');

  run_validate_full_success('full name NULL e valido', NULL);
  run_validate_full_success('full name valido e aceito', 'Rodrigo Paes');
  run_validate_full_failure('full name com 1 caractere e invalido', 'A');
  run_validate_full_success('full name com 2 caracteres e valido', 'AB');
  run_validate_full_success('full name com 200 caracteres e valido', RPAD('A', 200, 'A'));
  run_validate_full_failure('full name com 201 caracteres e invalido', RPAD('A', 201, 'A'));
  run_validate_full_failure('full name levanta excecao nominal', RPAD('A', 202, 'A'));

  run_validate_birth_success('birth date NULL e valida', NULL);
  run_validate_birth_success('birth date ontem e valida', TRUNC(SYSDATE) - 1);
  run_validate_birth_success('birth date hoje e valida', TRUNC(SYSDATE));
  run_validate_birth_failure('birth date amanha e invalida', TRUNC(SYSDATE) + 1);
  run_validate_birth_failure('birth date levanta excecao nominal', TRUNC(SYSDATE) + 30);

  run_validate_locale_success('locale pt-BR e valido', 'pt-BR');
  run_validate_locale_failure('locale en-US e invalido', 'en-US');
  run_validate_locale_failure('locale vazio e invalido', '');
  run_validate_locale_failure('locale NULL e invalido', NULL);
  run_validate_locale_failure('locale levanta excecao nominal', 'pt-br');

  run_validate_timezone_success('timezone America Sao Paulo e valida', 'America/Sao_Paulo');
  run_validate_timezone_failure('timezone UTC e invalida', 'UTC');
  run_validate_timezone_failure('timezone vazia e invalida', '');
  run_validate_timezone_failure('timezone NULL e invalida', NULL);
  run_validate_timezone_failure('timezone levanta excecao nominal', 'Europe/London');

  IF g_test_count <> c_expected_test_count THEN
    fail('Quantidade de testes executados diferente de 40.');
  END IF;

  DBMS_OUTPUT.PUT_LINE('SUCCESS - PFL_RULE_PKG (40 testes)');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('FAIL - ' || g_current_test);
    RAISE;
END;
/
