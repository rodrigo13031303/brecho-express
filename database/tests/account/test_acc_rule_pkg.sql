SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  g_test_count   PLS_INTEGER := 0;
  g_current_test VARCHAR2(200);

  c_expected_test_count CONSTANT PLS_INTEGER := 120;

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

  PROCEDURE run_normalize_equals(
    p_name     IN VARCHAR2,
    p_input    IN VARCHAR2,
    p_expected IN VARCHAR2
  ) IS
    l_actual VARCHAR2(32767);
  BEGIN
    start_test(p_name);
    l_actual := acc_rule_pkg.normalize_email(p_input);
    assert_equals(l_actual, p_expected, 'Normalizacao diferente da esperada.');
    pass;
  END run_normalize_equals;

  PROCEDURE run_normalize_null(
    p_name  IN VARCHAR2,
    p_input IN VARCHAR2
  ) IS
    l_actual VARCHAR2(32767);
  BEGIN
    start_test(p_name);
    l_actual := acc_rule_pkg.normalize_email(p_input);
    assert_null(l_actual, 'Normalizacao deveria retornar NULL.');
    pass;
  END run_normalize_null;

  PROCEDURE run_normalize_idempotent(
    p_name  IN VARCHAR2,
    p_input IN VARCHAR2
  ) IS
    l_first  VARCHAR2(32767);
    l_second VARCHAR2(32767);
  BEGIN
    start_test(p_name);
    l_first := acc_rule_pkg.normalize_email(p_input);
    l_second := acc_rule_pkg.normalize_email(l_first);
    assert_equals(l_second, l_first, 'Normalizacao deveria ser idempotente.');
    pass;
  END run_normalize_idempotent;

  PROCEDURE run_email_predicate(
    p_name     IN VARCHAR2,
    p_input    IN VARCHAR2,
    p_expected IN BOOLEAN
  ) IS
    l_actual BOOLEAN;
  BEGIN
    start_test(p_name);
    l_actual := acc_rule_pkg.is_valid_email(p_input);
    IF p_expected THEN
      assert_true(l_actual, 'E-mail deveria ser valido.');
    ELSE
      assert_false(l_actual, 'E-mail deveria ser invalido.');
    END IF;
    pass;
  END run_email_predicate;

  PROCEDURE run_validate_email_success(
    p_name  IN VARCHAR2,
    p_input IN VARCHAR2
  ) IS
  BEGIN
    start_test(p_name);
    acc_rule_pkg.validate_email(p_input);
    pass;
  END run_validate_email_success;

  PROCEDURE run_validate_email_failure(
    p_name  IN VARCHAR2,
    p_input IN VARCHAR2
  ) IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test(p_name);
    BEGIN
      acc_rule_pkg.validate_email(p_input);
    EXCEPTION
      WHEN acc_rule_pkg.e_invalid_email THEN
        l_raised := TRUE;
      WHEN OTHERS THEN
        fail('validate_email levantou excecao diferente.');
    END;
    assert_expected_exception(l_raised, 'e_invalid_email era esperada.');
    pass;
  END run_validate_email_failure;

  PROCEDURE run_validate_password_success(
    p_name     IN VARCHAR2,
    p_password IN VARCHAR2
  ) IS
  BEGIN
    start_test(p_name);
    acc_rule_pkg.validate_password(p_password);
    pass;
  END run_validate_password_success;

  PROCEDURE run_validate_password_failure(
    p_name     IN VARCHAR2,
    p_password IN VARCHAR2
  ) IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test(p_name);
    BEGIN
      acc_rule_pkg.validate_password(p_password);
    EXCEPTION
      WHEN acc_rule_pkg.e_invalid_password THEN
        l_raised := TRUE;
      WHEN OTHERS THEN
        fail('validate_password levantou excecao diferente.');
    END;
    assert_expected_exception(l_raised, 'e_invalid_password era esperada.');
    pass;
  END run_validate_password_failure;

  PROCEDURE run_public_id_predicate(
    p_name     IN VARCHAR2,
    p_input    IN VARCHAR2,
    p_expected IN BOOLEAN
  ) IS
    l_actual BOOLEAN;
  BEGIN
    start_test(p_name);
    l_actual := acc_rule_pkg.is_valid_public_id(p_input);
    IF p_expected THEN
      assert_true(l_actual, 'Public ID deveria ser valido.');
    ELSE
      assert_false(l_actual, 'Public ID deveria ser invalido.');
    END IF;
    pass;
  END run_public_id_predicate;

  PROCEDURE run_validate_public_id_success(
    p_name  IN VARCHAR2,
    p_input IN VARCHAR2
  ) IS
  BEGIN
    start_test(p_name);
    acc_rule_pkg.validate_public_id(p_input);
    pass;
  END run_validate_public_id_success;

  PROCEDURE run_validate_public_id_failure(
    p_name  IN VARCHAR2,
    p_input IN VARCHAR2
  ) IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test(p_name);
    BEGIN
      acc_rule_pkg.validate_public_id(p_input);
    EXCEPTION
      WHEN acc_rule_pkg.e_invalid_public_id THEN
        l_raised := TRUE;
      WHEN OTHERS THEN
        fail('validate_public_id levantou excecao diferente.');
    END;
    assert_expected_exception(l_raised, 'e_invalid_public_id era esperada.');
    pass;
  END run_validate_public_id_failure;

  PROCEDURE run_status_predicate(
    p_name     IN VARCHAR2,
    p_input    IN VARCHAR2,
    p_expected IN BOOLEAN
  ) IS
    l_actual BOOLEAN;
  BEGIN
    start_test(p_name);
    l_actual := acc_rule_pkg.is_valid_status(p_input);
    IF p_expected THEN
      assert_true(l_actual, 'Status deveria ser valido.');
    ELSE
      assert_false(l_actual, 'Status deveria ser invalido.');
    END IF;
    pass;
  END run_status_predicate;

  PROCEDURE run_validate_status_success(
    p_name  IN VARCHAR2,
    p_input IN VARCHAR2
  ) IS
  BEGIN
    start_test(p_name);
    acc_rule_pkg.validate_status(p_input);
    pass;
  END run_validate_status_success;

  PROCEDURE run_validate_status_failure(
    p_name  IN VARCHAR2,
    p_input IN VARCHAR2
  ) IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test(p_name);
    BEGIN
      acc_rule_pkg.validate_status(p_input);
    EXCEPTION
      WHEN acc_rule_pkg.e_invalid_status THEN
        l_raised := TRUE;
      WHEN OTHERS THEN
        fail('validate_status levantou excecao diferente.');
    END;
    assert_expected_exception(l_raised, 'e_invalid_status era esperada.');
    pass;
  END run_validate_status_failure;

  PROCEDURE run_active_case(
    p_name     IN VARCHAR2,
    p_input    IN VARCHAR2,
    p_expected IN BOOLEAN
  ) IS
  BEGIN
    start_test(p_name);
    IF p_expected THEN
      assert_true(acc_rule_pkg.is_active(p_input), 'is_active deveria retornar TRUE.');
    ELSE
      assert_false(acc_rule_pkg.is_active(p_input), 'is_active deveria retornar FALSE.');
    END IF;
    pass;
  END run_active_case;

  PROCEDURE run_active_other_statuses(
    p_name IN VARCHAR2
  ) IS
  BEGIN
    start_test(p_name);
    assert_false(acc_rule_pkg.is_active('PENDING_EMAIL_VERIFICATION'), 'PENDING nao e ACTIVE.');
    assert_false(acc_rule_pkg.is_active('BLOCKED'), 'BLOCKED nao e ACTIVE.');
    assert_false(acc_rule_pkg.is_active('DISABLED'), 'DISABLED nao e ACTIVE.');
    pass;
  END run_active_other_statuses;

  PROCEDURE run_blocked_case(
    p_name     IN VARCHAR2,
    p_input    IN VARCHAR2,
    p_expected IN BOOLEAN
  ) IS
  BEGIN
    start_test(p_name);
    IF p_expected THEN
      assert_true(acc_rule_pkg.is_blocked(p_input), 'is_blocked deveria retornar TRUE.');
    ELSE
      assert_false(acc_rule_pkg.is_blocked(p_input), 'is_blocked deveria retornar FALSE.');
    END IF;
    pass;
  END run_blocked_case;

  PROCEDURE run_blocked_other_statuses(
    p_name IN VARCHAR2
  ) IS
  BEGIN
    start_test(p_name);
    assert_false(acc_rule_pkg.is_blocked('PENDING_EMAIL_VERIFICATION'), 'PENDING nao e BLOCKED.');
    assert_false(acc_rule_pkg.is_blocked('ACTIVE'), 'ACTIVE nao e BLOCKED.');
    assert_false(acc_rule_pkg.is_blocked('DISABLED'), 'DISABLED nao e BLOCKED.');
    pass;
  END run_blocked_other_statuses;

  PROCEDURE run_disabled_case(
    p_name     IN VARCHAR2,
    p_input    IN VARCHAR2,
    p_expected IN BOOLEAN
  ) IS
  BEGIN
    start_test(p_name);
    IF p_expected THEN
      assert_true(acc_rule_pkg.is_disabled(p_input), 'is_disabled deveria retornar TRUE.');
    ELSE
      assert_false(acc_rule_pkg.is_disabled(p_input), 'is_disabled deveria retornar FALSE.');
    END IF;
    pass;
  END run_disabled_case;

  PROCEDURE run_disabled_other_statuses(
    p_name IN VARCHAR2
  ) IS
  BEGIN
    start_test(p_name);
    assert_false(acc_rule_pkg.is_disabled('PENDING_EMAIL_VERIFICATION'), 'PENDING nao e DISABLED.');
    assert_false(acc_rule_pkg.is_disabled('ACTIVE'), 'ACTIVE nao e DISABLED.');
    assert_false(acc_rule_pkg.is_disabled('BLOCKED'), 'BLOCKED nao e DISABLED.');
    pass;
  END run_disabled_other_statuses;

  PROCEDURE run_transition_success(
    p_name    IN VARCHAR2,
    p_current IN VARCHAR2,
    p_new     IN VARCHAR2
  ) IS
  BEGIN
    start_test(p_name);
    acc_rule_pkg.validate_status_transition(p_current, p_new);
    pass;
  END run_transition_success;

  PROCEDURE run_transition_failure(
    p_name    IN VARCHAR2,
    p_current IN VARCHAR2,
    p_new     IN VARCHAR2
  ) IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test(p_name);
    BEGIN
      acc_rule_pkg.validate_status_transition(p_current, p_new);
    EXCEPTION
      WHEN acc_rule_pkg.e_invalid_status_transition THEN
        l_raised := TRUE;
      WHEN OTHERS THEN
        fail('Transicao invalida levantou excecao diferente.');
    END;
    assert_expected_exception(
      l_raised,
      'e_invalid_status_transition era esperada.'
    );
    pass;
  END run_transition_failure;

  PROCEDURE run_transition_invalid_status(
    p_name    IN VARCHAR2,
    p_current IN VARCHAR2,
    p_new     IN VARCHAR2
  ) IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test(p_name);
    BEGIN
      acc_rule_pkg.validate_status_transition(p_current, p_new);
    EXCEPTION
      WHEN acc_rule_pkg.e_invalid_status THEN
        l_raised := TRUE;
      WHEN OTHERS THEN
        fail('Status invalido levantou excecao diferente.');
    END;
    assert_expected_exception(l_raised, 'e_invalid_status era esperada.');
    pass;
  END run_transition_invalid_status;

  PROCEDURE run_email_available_success(
    p_name   IN VARCHAR2,
    p_exists IN BOOLEAN
  ) IS
  BEGIN
    start_test(p_name);
    acc_rule_pkg.assert_email_available(p_exists);
    pass;
  END run_email_available_success;

  PROCEDURE run_email_available_used(
    p_name IN VARCHAR2
  ) IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test(p_name);
    BEGIN
      acc_rule_pkg.assert_email_available(TRUE);
    EXCEPTION
      WHEN acc_rule_pkg.e_email_already_used THEN
        l_raised := TRUE;
      WHEN OTHERS THEN
        fail('Email utilizado levantou excecao diferente.');
    END;
    assert_expected_exception(l_raised, 'e_email_already_used era esperada.');
    pass;
  END run_email_available_used;

  PROCEDURE run_email_available_null(
    p_name IN VARCHAR2
  ) IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test(p_name);
    BEGIN
      acc_rule_pkg.assert_email_available(NULL);
    EXCEPTION
      WHEN VALUE_ERROR THEN
        l_raised := TRUE;
      WHEN OTHERS THEN
        fail('BOOLEAN NULL levantou excecao diferente.');
    END;
    assert_expected_exception(l_raised, 'VALUE_ERROR era esperada.');
    pass;
  END run_email_available_null;

  PROCEDURE run_account_exists_success(
    p_name   IN VARCHAR2,
    p_exists IN BOOLEAN
  ) IS
  BEGIN
    start_test(p_name);
    acc_rule_pkg.assert_account_exists(p_exists);
    pass;
  END run_account_exists_success;

  PROCEDURE run_account_not_found(
    p_name IN VARCHAR2
  ) IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test(p_name);
    BEGIN
      acc_rule_pkg.assert_account_exists(FALSE);
    EXCEPTION
      WHEN acc_rule_pkg.e_account_not_found THEN
        l_raised := TRUE;
      WHEN OTHERS THEN
        fail('Conta inexistente levantou excecao diferente.');
    END;
    assert_expected_exception(l_raised, 'e_account_not_found era esperada.');
    pass;
  END run_account_not_found;

  PROCEDURE run_account_exists_null(
    p_name IN VARCHAR2
  ) IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test(p_name);
    BEGIN
      acc_rule_pkg.assert_account_exists(NULL);
    EXCEPTION
      WHEN VALUE_ERROR THEN
        l_raised := TRUE;
      WHEN OTHERS THEN
        fail('BOOLEAN NULL levantou excecao diferente.');
    END;
    assert_expected_exception(l_raised, 'VALUE_ERROR era esperada.');
    pass;
  END run_account_exists_null;
BEGIN
  run_normalize_equals('normalizacao preserva email normalizado', 'user@example.com', 'user@example.com');
  run_normalize_equals('normalizacao converte maiusculas', 'USER@EXAMPLE.COM', 'user@example.com');
  run_normalize_equals('normalizacao remove espacos externos', '  user@example.com  ', 'user@example.com');
  run_normalize_equals('normalizacao preserva alias', 'user+tag@example.com', 'user+tag@example.com');
  run_normalize_equals('normalizacao preserva pontos', 'first.last@example.com', 'first.last@example.com');
  run_normalize_equals('normalizacao preserva espacos internos', 'user name@example.com', 'user name@example.com');
  run_normalize_null('normalizacao de NULL retorna NULL', NULL);
  run_normalize_null('normalizacao de espacos retorna NULL', '   ');
  run_normalize_idempotent('normalizacao e idempotente', '  USER+tag@Example.COM  ');
  run_email_predicate('email simples e valido', 'user@example.com', TRUE);
  run_email_predicate('email com maiusculas e valido', 'USER@EXAMPLE.COM', TRUE);
  run_email_predicate('email com alias e valido', 'user+tag@example.com', TRUE);
  run_email_predicate('email com pontos locais e valido', 'first.last@example.com', TRUE);
  run_email_predicate('email com subdominio e valido', 'user@mail.example.com', TRUE);
  run_email_predicate('email com hifen no dominio e valido', 'user@my-domain.com', TRUE);
  run_email_predicate('email NULL e invalido', NULL, FALSE);
  run_email_predicate('email vazio e invalido', '', FALSE);
  run_email_predicate('email com somente espacos e invalido', '   ', FALSE);
  run_email_predicate('email sem arroba e invalido', 'user.example.com', FALSE);
  run_email_predicate('email com multiplos arrobas e invalido', 'user@@example.com', FALSE);
  run_email_predicate('email sem parte local e invalido', '@example.com', FALSE);
  run_email_predicate('email sem dominio e invalido', 'user@', FALSE);
  run_email_predicate('email com dominio sem ponto e invalido', 'user@example', FALSE);
  run_email_predicate('email com espaco interno e invalido', 'user name@example.com', FALSE);
  run_email_predicate('email com parte local iniciando em ponto e invalido', '.user@example.com', FALSE);
  run_email_predicate('email com parte local terminando em ponto e invalido', 'user.@example.com', FALSE);
  run_email_predicate('email com pontos locais consecutivos e invalido', 'user..name@example.com', FALSE);
  run_email_predicate('email com dominio iniciando em ponto e invalido', 'user@.example.com', FALSE);
  run_email_predicate('email com dominio terminando em ponto e invalido', 'user@example.com.', FALSE);
  run_email_predicate('email com pontos consecutivos no dominio e invalido', 'user@example..com', FALSE);
  run_email_predicate('email com label iniciando em hifen e invalido', 'user@-example.com', FALSE);
  run_email_predicate('email com label terminando em hifen e invalido', 'user@example-.com', FALSE);
  run_email_predicate('email com caractere invalido e invalido', 'user(),@example.com', FALSE);
  run_email_predicate('email acima de 255 caracteres e invalido', RPAD('a', 250, 'a') || '@a.com', FALSE);
  run_validate_email_success('validate_email aceita valor valido', 'user@example.com');
  run_validate_email_failure('validate_email rejeita valor invalido', 'invalid');
  run_validate_email_failure('validate_email rejeita NULL', NULL);
  run_validate_password_success('senha com 8 caracteres e valida', 'abcdefgh');
  run_validate_password_success('senha com 128 caracteres e valida', RPAD('a', 128, 'a'));
  run_validate_password_failure('senha com 7 caracteres e invalida', 'abcdefg');
  run_validate_password_failure('senha com 129 caracteres e invalida', RPAD('a', 129, 'a'));
  run_validate_password_failure('senha NULL e invalida', NULL);
  run_validate_password_success('senha com 8 espacos e valida', RPAD(' ', 8, ' '));
  run_validate_password_success('espacos externos da senha sao significativos', ' abcdef ');
  run_validate_password_success('senha simples e valida', 'password');
  run_public_id_predicate('public id numerico e valido', '01234567890123456789012345678901', TRUE);
  run_public_id_predicate('public id hexadecimal minusculo e valido', 'abcdefabcdefabcdefabcdefabcdefab', TRUE);
  run_public_id_predicate('public id hexadecimal maiusculo e valido', 'ABCDEFABCDEFABCDEFABCDEFABCDEFAB', TRUE);
  run_public_id_predicate('public id hexadecimal combinado e valido', '0123456789abcdefABCDEF0123456789', TRUE);
  run_public_id_predicate('public id NULL e invalido', NULL, FALSE);
  run_public_id_predicate('public id com 31 caracteres e invalido', 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA', FALSE);
  run_public_id_predicate('public id com 33 caracteres e invalido', 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA', FALSE);
  run_public_id_predicate('public id com hifen e invalido', 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA-', FALSE);
  run_public_id_predicate('public id com chaves e invalido', '{AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA}', FALSE);
  run_public_id_predicate('public id com espaco e invalido', 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA ', FALSE);
  run_public_id_predicate('public id nao hexadecimal e invalido', 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAG', FALSE);
  run_public_id_predicate('public id UUID com separadores e invalido', '550e8400-e29b-41d4-a716-446655440000', FALSE);
  run_validate_public_id_success('validate_public_id aceita valor valido', '0123456789ABCDEF0123456789ABCDEF');
  run_validate_public_id_failure('validate_public_id rejeita valor invalido', 'INVALID');
  run_validate_public_id_failure('validate_public_id rejeita NULL', NULL);
  run_status_predicate('status PENDING_EMAIL_VERIFICATION e valido', 'PENDING_EMAIL_VERIFICATION', TRUE);
  run_status_predicate('status ACTIVE e valido', 'ACTIVE', TRUE);
  run_status_predicate('status BLOCKED e valido', 'BLOCKED', TRUE);
  run_status_predicate('status DISABLED e valido', 'DISABLED', TRUE);
  run_status_predicate('status minusculo e valido', 'active', TRUE);
  run_status_predicate('status com espacos externos e valido', '  blocked  ', TRUE);
  run_status_predicate('status NULL e invalido', NULL, FALSE);
  run_status_predicate('status vazio e invalido', '', FALSE);
  run_status_predicate('status desconhecido e invalido', 'UNKNOWN', FALSE);
  run_status_predicate('status com caracteres adicionais e invalido', 'ACTIVE_EXTRA', FALSE);
  run_status_predicate('status oficial com espaco interno e invalido', 'PENDING EMAIL VERIFICATION', FALSE);
  run_validate_status_success('validate_status aceita PENDING_EMAIL_VERIFICATION', 'PENDING_EMAIL_VERIFICATION');
  run_validate_status_success('validate_status aceita ACTIVE', 'ACTIVE');
  run_validate_status_success('validate_status aceita BLOCKED', 'BLOCKED');
  run_validate_status_success('validate_status aceita DISABLED', 'DISABLED');
  run_validate_status_success('validate_status normaliza caixa e espacos', '  active  ');
  run_validate_status_failure('validate_status rejeita desconhecido', 'UNKNOWN');
  run_validate_status_failure('validate_status rejeita NULL', NULL);
  run_active_case('is_active reconhece ACTIVE', 'ACTIVE', TRUE);
  run_active_case('is_active normaliza caixa e espacos', '  active  ', TRUE);
  run_active_other_statuses('is_active rejeita demais status');
  run_active_case('is_active rejeita NULL', NULL, FALSE);
  run_active_case('is_active rejeita status invalido', 'UNKNOWN', FALSE);
  run_blocked_case('is_blocked reconhece BLOCKED', 'BLOCKED', TRUE);
  run_blocked_case('is_blocked normaliza caixa e espacos', '  blocked  ', TRUE);
  run_blocked_other_statuses('is_blocked rejeita demais status');
  run_blocked_case('is_blocked rejeita NULL', NULL, FALSE);
  run_blocked_case('is_blocked rejeita status invalido', 'UNKNOWN', FALSE);
  run_disabled_case('is_disabled reconhece DISABLED', 'DISABLED', TRUE);
  run_disabled_case('is_disabled normaliza caixa e espacos', '  disabled  ', TRUE);
  run_disabled_other_statuses('is_disabled rejeita demais status');
  run_disabled_case('is_disabled rejeita NULL', NULL, FALSE);
  run_disabled_case('is_disabled rejeita status invalido', 'UNKNOWN', FALSE);
  run_transition_success('transicao pending para active e valida', 'PENDING_EMAIL_VERIFICATION', 'ACTIVE');
  run_transition_success('transicao active para blocked e valida', 'ACTIVE', 'BLOCKED');
  run_transition_success('transicao blocked para active e valida', 'BLOCKED', 'ACTIVE');
  run_transition_success('transicao active para disabled e valida', 'ACTIVE', 'DISABLED');
  run_transition_success('transicao blocked para disabled e valida', 'BLOCKED', 'DISABLED');
  run_transition_success('transicao disabled para active e valida', 'DISABLED', 'ACTIVE');
  run_transition_success('transicao pending idempotente e valida', 'PENDING_EMAIL_VERIFICATION', 'PENDING_EMAIL_VERIFICATION');
  run_transition_success('transicao active idempotente e valida', 'ACTIVE', 'ACTIVE');
  run_transition_success('transicao blocked idempotente e valida', 'BLOCKED', 'BLOCKED');
  run_transition_success('transicao disabled idempotente e valida', 'DISABLED', 'DISABLED');
  run_transition_success('transicao normaliza caixa e espacos', '  active  ', '  blocked  ');
  run_transition_failure('transicao pending para blocked e invalida', 'PENDING_EMAIL_VERIFICATION', 'BLOCKED');
  run_transition_failure('transicao pending para disabled e invalida', 'PENDING_EMAIL_VERIFICATION', 'DISABLED');
  run_transition_failure('transicao active para pending e invalida', 'ACTIVE', 'PENDING_EMAIL_VERIFICATION');
  run_transition_failure('transicao blocked para pending e invalida', 'BLOCKED', 'PENDING_EMAIL_VERIFICATION');
  run_transition_failure('transicao disabled para pending e invalida', 'DISABLED', 'PENDING_EMAIL_VERIFICATION');
  run_transition_failure('transicao disabled para blocked e invalida', 'DISABLED', 'BLOCKED');
  run_transition_invalid_status('transicao rejeita status atual invalido', 'UNKNOWN', 'ACTIVE');
  run_transition_invalid_status('transicao rejeita novo status invalido', 'ACTIVE', 'UNKNOWN');
  run_transition_invalid_status('transicao rejeita status atual NULL', NULL, 'ACTIVE');
  run_transition_invalid_status('transicao rejeita novo status NULL', 'ACTIVE', NULL);
  run_email_available_success('email inexistente esta disponivel', FALSE);
  run_email_available_used('email existente nao esta disponivel');
  run_email_available_null('email disponivel rejeita BOOLEAN NULL');
  run_account_exists_success('conta existente e aceita', TRUE);
  run_account_not_found('conta inexistente e rejeitada');
  run_account_exists_null('conta existente rejeita BOOLEAN NULL');

  IF g_test_count <> c_expected_test_count THEN
    fail('Quantidade de testes executados diferente de 120.');
  END IF;

  DBMS_OUTPUT.PUT_LINE('SUCCESS - ACC_RULE_PKG (120 testes)');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('FAIL - ' || g_current_test);
    RAISE;
END;
/

