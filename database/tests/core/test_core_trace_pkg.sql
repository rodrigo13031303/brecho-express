SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  g_test_count PLS_INTEGER := 0;

  PROCEDURE assert_true(
    p_condition IN BOOLEAN,
    p_message   IN VARCHAR2
  ) IS
  BEGIN
    IF p_condition IS NULL OR NOT p_condition THEN
      RAISE_APPLICATION_ERROR(-20999, p_message);
    END IF;
  END assert_true;

  PROCEDURE pass(
    p_test_name IN VARCHAR2
  ) IS
  BEGIN
    g_test_count := g_test_count + 1;
    DBMS_OUTPUT.PUT_LINE('PASS ' || LPAD(g_test_count, 2, '0') || ' - ' || p_test_name);
  END pass;

  PROCEDURE test_initialize_generates_non_null IS
  BEGIN
    core_trace_pkg.clear;
    core_trace_pkg.initialize;

    assert_true(
      core_trace_pkg.current_trace_id IS NOT NULL,
      'initialize deve gerar trace nao nulo.'
    );

    pass('initialize gera trace nao nulo');
  END test_initialize_generates_non_null;

  PROCEDURE test_generated_length IS
  BEGIN
    core_trace_pkg.initialize;

    assert_true(
      LENGTH(core_trace_pkg.current_trace_id) = 32,
      'Trace gerado deve possuir 32 caracteres.'
    );

    pass('trace gerado possui 32 caracteres');
  END test_generated_length;

  PROCEDURE test_generated_is_hexadecimal IS
  BEGIN
    core_trace_pkg.initialize;

    assert_true(
      REGEXP_LIKE(core_trace_pkg.current_trace_id, '^[0-9A-F]{32}$', 'c'),
      'Trace gerado deve conter apenas hexadecimal maiusculo.'
    );

    pass('trace gerado contem somente hexadecimal');
  END test_generated_is_hexadecimal;

  PROCEDURE test_consecutive_initializations_differ IS
    l_first_trace  core_trace_pkg.t_trace_id;
    l_second_trace core_trace_pkg.t_trace_id;
  BEGIN
    core_trace_pkg.initialize;
    l_first_trace := core_trace_pkg.current_trace_id;

    core_trace_pkg.initialize;
    l_second_trace := core_trace_pkg.current_trace_id;

    assert_true(
      l_first_trace <> l_second_trace,
      'Inicializacoes consecutivas devem gerar traces diferentes.'
    );

    pass('inicializacoes consecutivas geram valores diferentes');
  END test_consecutive_initializations_differ;

  PROCEDURE test_initialize_accepts_valid_value IS
    l_expected CONSTANT core_trace_pkg.t_trace_id := '0123456789ABCDEF0123456789ABCDEF';
  BEGIN
    core_trace_pkg.initialize(l_expected);

    assert_true(
      core_trace_pkg.current_trace_id = l_expected,
      'initialize deve aceitar trace valido.'
    );

    pass('initialize aceita valor valido');
  END test_initialize_accepts_valid_value;

  PROCEDURE test_initialize_normalizes_lowercase IS
  BEGIN
    core_trace_pkg.initialize('abcdef0123456789abcdef0123456789');

    assert_true(
      core_trace_pkg.current_trace_id = 'ABCDEF0123456789ABCDEF0123456789',
      'initialize deve normalizar trace para maiusculas.'
    );

    pass('initialize normaliza letras minusculas');
  END test_initialize_normalizes_lowercase;

  PROCEDURE test_initialize_rejects_null IS
    l_rejected BOOLEAN := FALSE;
  BEGIN
    BEGIN
      core_trace_pkg.initialize(NULL);
    EXCEPTION
      WHEN core_trace_pkg.e_invalid_trace_id THEN
        l_rejected := TRUE;
    END;

    assert_true(l_rejected, 'initialize deve rejeitar NULL.');
    assert_true(NOT core_trace_pkg.has_trace, 'Trace deve permanecer limpo apos entrada NULL.');

    pass('initialize rejeita NULL');
  END test_initialize_rejects_null;

  PROCEDURE test_initialize_rejects_invalid_length IS
    l_rejected BOOLEAN := FALSE;
  BEGIN
    BEGIN
      core_trace_pkg.initialize('ABCDEF');
    EXCEPTION
      WHEN core_trace_pkg.e_invalid_trace_id THEN
        l_rejected := TRUE;
    END;

    assert_true(l_rejected, 'initialize deve rejeitar tamanho diferente de 32.');
    assert_true(NOT core_trace_pkg.has_trace, 'Trace deve permanecer limpo apos tamanho invalido.');

    pass('initialize rejeita tamanho diferente de 32');
  END test_initialize_rejects_invalid_length;

  PROCEDURE test_initialize_rejects_non_hexadecimal IS
    l_rejected BOOLEAN := FALSE;
  BEGIN
    BEGIN
      core_trace_pkg.initialize('0123456789ABCDEF0123456789ABCDEG');
    EXCEPTION
      WHEN core_trace_pkg.e_invalid_trace_id THEN
        l_rejected := TRUE;
    END;

    assert_true(l_rejected, 'initialize deve rejeitar caractere nao hexadecimal.');
    assert_true(NOT core_trace_pkg.has_trace, 'Trace deve permanecer limpo apos caractere invalido.');

    pass('initialize rejeita caracteres nao hexadecimais');
  END test_initialize_rejects_non_hexadecimal;

  PROCEDURE test_current_trace_is_stable IS
    l_first_read  core_trace_pkg.t_trace_id;
    l_second_read core_trace_pkg.t_trace_id;
  BEGIN
    core_trace_pkg.initialize;
    l_first_read := core_trace_pkg.current_trace_id;
    l_second_read := core_trace_pkg.current_trace_id;

    assert_true(
      l_first_read = l_second_read,
      'current_trace_id deve retornar o mesmo valor durante a execucao.'
    );

    pass('current_trace_id retorna o mesmo valor durante a execucao');
  END test_current_trace_is_stable;

  PROCEDURE test_current_trace_fails_without_initialization IS
    l_failed   BOOLEAN := FALSE;
    l_trace_id core_trace_pkg.t_trace_id;
  BEGIN
    core_trace_pkg.clear;

    BEGIN
      l_trace_id := core_trace_pkg.current_trace_id;
    EXCEPTION
      WHEN core_trace_pkg.e_trace_not_initialized THEN
        l_failed := TRUE;
    END;

    assert_true(l_failed, 'current_trace_id deve falhar sem inicializacao.');

    pass('current_trace_id falha quando nao inicializado');
  END test_current_trace_fails_without_initialization;

  PROCEDURE test_has_trace_before_initialization IS
  BEGIN
    core_trace_pkg.clear;

    assert_true(
      NOT core_trace_pkg.has_trace,
      'has_trace deve retornar FALSE antes da inicializacao.'
    );

    pass('has_trace retorna FALSE antes da inicializacao');
  END test_has_trace_before_initialization;

  PROCEDURE test_has_trace_after_initialization IS
  BEGIN
    core_trace_pkg.initialize;

    assert_true(
      core_trace_pkg.has_trace,
      'has_trace deve retornar TRUE depois da inicializacao.'
    );

    pass('has_trace retorna TRUE depois da inicializacao');
  END test_has_trace_after_initialization;

  PROCEDURE test_clear_removes_trace IS
  BEGIN
    core_trace_pkg.initialize;
    core_trace_pkg.clear;

    assert_true(NOT core_trace_pkg.has_trace, 'clear deve remover o trace.');

    pass('clear remove o trace');
  END test_clear_removes_trace;

  PROCEDURE test_clear_is_idempotent IS
  BEGIN
    core_trace_pkg.clear;
    core_trace_pkg.clear;

    assert_true(NOT core_trace_pkg.has_trace, 'clear repetido deve manter o estado limpo.');

    pass('clear pode ser executado duas vezes sem erro');
  END test_clear_is_idempotent;

  PROCEDURE test_initialize_after_clear_generates_new_trace IS
    l_first_trace  core_trace_pkg.t_trace_id;
    l_second_trace core_trace_pkg.t_trace_id;
  BEGIN
    core_trace_pkg.initialize;
    l_first_trace := core_trace_pkg.current_trace_id;

    core_trace_pkg.clear;
    core_trace_pkg.initialize;
    l_second_trace := core_trace_pkg.current_trace_id;

    assert_true(
      l_first_trace <> l_second_trace,
      'Nova inicializacao apos clear nao deve reutilizar o trace anterior.'
    );

    pass('nova inicializacao apos clear nao reutiliza trace anterior');
  END test_initialize_after_clear_generates_new_trace;

  PROCEDURE test_initialize_replaces_residual_state IS
  BEGIN
    core_trace_pkg.initialize('AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA');
    core_trace_pkg.initialize('BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB');

    assert_true(
      core_trace_pkg.current_trace_id = 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB',
      'initialize deve substituir defensivamente o estado residual.'
    );

    pass('initialize substitui estado residual');
  END test_initialize_replaces_residual_state;

  PROCEDURE test_has_no_transaction_control IS
    l_forbidden_count PLS_INTEGER;
  BEGIN
    SELECT COUNT(*)
      INTO l_forbidden_count
      FROM user_source
     WHERE name = 'CORE_TRACE_PKG'
       AND type IN ('PACKAGE', 'PACKAGE BODY')
       AND REGEXP_LIKE(text, '(^|[^A-Z])(COMMIT|ROLLBACK)([^A-Z]|$)', 'i');

    assert_true(
      l_forbidden_count = 0,
      'CORE_TRACE_PKG nao pode conter controle transacional.'
    );

    pass('implementacao nao contem controle transacional');
  END test_has_no_transaction_control;
BEGIN
  test_initialize_generates_non_null;
  test_generated_length;
  test_generated_is_hexadecimal;
  test_consecutive_initializations_differ;
  test_initialize_accepts_valid_value;
  test_initialize_normalizes_lowercase;
  test_initialize_rejects_null;
  test_initialize_rejects_invalid_length;
  test_initialize_rejects_non_hexadecimal;
  test_current_trace_is_stable;
  test_current_trace_fails_without_initialization;
  test_has_trace_before_initialization;
  test_has_trace_after_initialization;
  test_clear_removes_trace;
  test_clear_is_idempotent;
  test_initialize_after_clear_generates_new_trace;
  test_initialize_replaces_residual_state;
  test_has_no_transaction_control;

  core_trace_pkg.clear;
  DBMS_OUTPUT.PUT_LINE('SUCCESS - ' || g_test_count || ' testes executados.');
EXCEPTION
  WHEN OTHERS THEN
    core_trace_pkg.clear;
    RAISE;
END;
/
