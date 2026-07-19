SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  g_test_count   PLS_INTEGER := 0;
  g_current_test VARCHAR2(200);
  g_public_error core_error_pkg.t_public_error;
  g_error_policy core_error_pkg.t_error_policy;

  c_code     CONSTANT core_error_pkg.t_error_code := 'BEX-CORE-001';
  c_message  CONSTANT core_error_pkg.t_external_message := 'Falha segura.';
  c_trace_id CONSTANT core_trace_pkg.t_trace_id :=
    '0123456789ABCDEF0123456789ABCDEF';

  PROCEDURE assert_true(p_condition IN BOOLEAN, p_message IN VARCHAR2) IS
  BEGIN
    IF p_condition IS NULL OR NOT p_condition THEN
      RAISE_APPLICATION_ERROR(-20999, p_message);
    END IF;
  END assert_true;

  PROCEDURE assert_false(p_condition IN BOOLEAN, p_message IN VARCHAR2) IS
  BEGIN
    IF p_condition IS NULL OR p_condition THEN
      RAISE_APPLICATION_ERROR(-20999, p_message);
    END IF;
  END assert_false;

  PROCEDURE assert_equals(
    p_actual IN VARCHAR2, p_expected IN VARCHAR2, p_message IN VARCHAR2
  ) IS
  BEGIN
    IF p_actual IS NULL OR p_expected IS NULL OR p_actual <> p_expected THEN
      RAISE_APPLICATION_ERROR(-20999, p_message);
    END IF;
  END assert_equals;

  PROCEDURE assert_null(p_actual IN VARCHAR2, p_message IN VARCHAR2) IS
  BEGIN
    IF p_actual IS NOT NULL THEN
      RAISE_APPLICATION_ERROR(-20999, p_message);
    END IF;
  END assert_null;

  PROCEDURE assert_boolean_equals(
    p_actual IN BOOLEAN, p_expected IN BOOLEAN, p_message IN VARCHAR2
  ) IS
  BEGIN
    IF p_actual IS NULL OR p_expected IS NULL OR p_actual <> p_expected THEN
      RAISE_APPLICATION_ERROR(-20999, p_message);
    END IF;
  END assert_boolean_equals;

  PROCEDURE assert_boolean_null(p_actual IN BOOLEAN, p_message IN VARCHAR2) IS
  BEGIN
    IF p_actual IS NOT NULL THEN
      RAISE_APPLICATION_ERROR(-20999, p_message);
    END IF;
  END assert_boolean_null;

  PROCEDURE assert_raises(p_raised IN BOOLEAN, p_message IN VARCHAR2) IS
  BEGIN
    assert_true(p_raised, p_message);
  END assert_raises;

  PROCEDURE reset_records IS
  BEGIN
    g_public_error.code := NULL;
    g_public_error.category := NULL;
    g_public_error.external_message := NULL;
    g_public_error.retryable := NULL;
    g_public_error.trace_id := NULL;
    g_error_policy.severity := NULL;
    g_error_policy.should_log := NULL;
  END reset_records;

  PROCEDURE start_test(p_name IN VARCHAR2) IS
  BEGIN
    g_current_test := p_name;
    core_trace_pkg.clear;
    reset_records;
  END start_test;

  PROCEDURE pass IS
  BEGIN
    core_trace_pkg.clear;
    reset_records;
    g_test_count := g_test_count + 1;
    DBMS_OUTPUT.PUT_LINE(
      'PASS ' || LPAD(g_test_count, 2, '0') || ' - ' || g_current_test
    );
  END pass;

  PROCEDURE build_known(
    p_code       IN core_error_pkg.t_error_code := c_code,
    p_category   IN core_error_pkg.t_category := core_error_pkg.c_category_technical,
    p_message    IN core_error_pkg.t_external_message := c_message,
    p_severity   IN core_error_pkg.t_severity := core_error_pkg.c_severity_error,
    p_retryable  IN BOOLEAN := FALSE,
    p_should_log IN BOOLEAN := TRUE
  ) IS
  BEGIN
    core_error_pkg.build_known_error(
      p_code, p_category, p_message, p_severity,
      p_retryable, p_should_log, g_public_error, g_error_policy
    );
  END build_known;

  PROCEDURE build_technical(
    p_code      IN core_error_pkg.t_error_code := c_code,
    p_message   IN core_error_pkg.t_external_message := c_message,
    p_retryable IN BOOLEAN := FALSE
  ) IS
  BEGIN
    core_error_pkg.build_technical_error(
      p_code, p_message, p_retryable, g_public_error, g_error_policy
    );
  END build_technical;

  PROCEDURE assert_invalid_code(p_code IN core_error_pkg.t_error_code) IS
  BEGIN
    assert_false(core_error_pkg.is_valid_code(p_code), 'Codigo deveria ser invalido.');
  END assert_invalid_code;

  PROCEDURE test_01_valid_minimum_code IS
  BEGIN
    start_test('codigo valido minimo');
    assert_true(core_error_pkg.is_valid_code('BEX-ABC-001'), 'Codigo minimo deve ser valido.');
    pass;
  END test_01_valid_minimum_code;

  PROCEDURE test_02_valid_alphanumeric_context IS
  BEGIN
    start_test('codigo valido com contexto alfanumerico');
    assert_true(core_error_pkg.is_valid_code('BEX-A1B2C3-999'), 'Contexto alfanumerico deve ser valido.');
    pass;
  END test_02_valid_alphanumeric_context;

  PROCEDURE test_03_lowercase_code_normalized IS
  BEGIN
    start_test('codigo minusculo aceito e normalizado');
    build_known(p_code => 'bex-core-001');
    assert_equals(g_public_error.code, c_code, 'Codigo deve ser normalizado.');
    pass;
  END test_03_lowercase_code_normalized;

  PROCEDURE test_04_null_code IS
  BEGIN
    start_test('codigo NULL invalido'); assert_invalid_code(NULL); pass;
  END test_04_null_code;

  PROCEDURE test_05_wrong_prefix IS
  BEGIN
    start_test('prefixo diferente de BEX invalido'); assert_invalid_code('ABC-CORE-001'); pass;
  END test_05_wrong_prefix;

  PROCEDURE test_06_short_context IS
  BEGIN
    start_test('contexto menor que tres caracteres invalido'); assert_invalid_code('BEX-AB-001'); pass;
  END test_06_short_context;

  PROCEDURE test_07_long_context IS
  BEGIN
    start_test('contexto maior que vinte caracteres invalido');
    assert_invalid_code('BEX-ABCDEFGHIJKLMNOPQRSTU-001'); pass;
  END test_07_long_context;

  PROCEDURE test_08_hyphenated_context IS
  BEGIN
    start_test('contexto contendo hifen invalido'); assert_invalid_code('BEX-CO-RE-001'); pass;
  END test_08_hyphenated_context;

  PROCEDURE test_09_short_suffix IS
  BEGIN
    start_test('sufixo com menos de tres digitos invalido'); assert_invalid_code('BEX-CORE-01'); pass;
  END test_09_short_suffix;

  PROCEDURE test_10_long_suffix IS
  BEGIN
    start_test('sufixo com mais de tres digitos invalido'); assert_invalid_code('BEX-CORE-0001'); pass;
  END test_10_long_suffix;

  PROCEDURE test_11_non_numeric_suffix IS
  BEGIN
    start_test('sufixo nao numerico invalido'); assert_invalid_code('BEX-CORE-0A1'); pass;
  END test_11_non_numeric_suffix;

  PROCEDURE test_12_external_spaces IS
  BEGIN
    start_test('espacos externos sao normalizados');
    build_known(p_code => '  bex-core-001  ');
    assert_equals(g_public_error.code, c_code, 'Espacos externos devem ser removidos.'); pass;
  END test_12_external_spaces;

  PROCEDURE test_13_official_categories IS
    TYPE t_values IS TABLE OF core_error_pkg.t_category;
    l_values t_values := t_values(
      core_error_pkg.c_category_validation, core_error_pkg.c_category_business,
      core_error_pkg.c_category_not_found, core_error_pkg.c_category_authentication,
      core_error_pkg.c_category_authorization, core_error_pkg.c_category_security,
      core_error_pkg.c_category_conflict, core_error_pkg.c_category_technical,
      core_error_pkg.c_category_integration
    );
  BEGIN
    start_test('nove categorias oficiais validas');
    FOR i IN 1..l_values.COUNT LOOP
      assert_true(core_error_pkg.is_valid_category(l_values(i)), 'Categoria oficial invalida.');
    END LOOP;
    pass;
  END test_13_official_categories;

  PROCEDURE test_14_null_category IS
  BEGIN
    start_test('categoria NULL invalida');
    assert_false(core_error_pkg.is_valid_category(NULL), 'Categoria NULL deve ser invalida.'); pass;
  END test_14_null_category;

  PROCEDURE test_15_unknown_category IS
  BEGIN
    start_test('categoria desconhecida invalida');
    assert_false(core_error_pkg.is_valid_category('UNKNOWN'), 'Categoria desconhecida deve ser invalida.'); pass;
  END test_15_unknown_category;

  PROCEDURE test_16_lowercase_category IS
  BEGIN
    start_test('categoria minuscula normalizada');
    assert_equals(core_error_pkg.normalize_category('technical_error'), 'TECHNICAL_ERROR', 'Categoria deve normalizar.'); pass;
  END test_16_lowercase_category;

  PROCEDURE test_17_spaced_category IS
  BEGIN
    start_test('categoria com espacos normalizada');
    assert_equals(core_error_pkg.normalize_category('  technical_error  '), 'TECHNICAL_ERROR', 'Categoria deve remover espacos.'); pass;
  END test_17_spaced_category;

  PROCEDURE test_18_info_severity IS
  BEGIN
    start_test('severidade INFO valida'); assert_true(core_error_pkg.is_valid_severity('INFO'), 'INFO deve ser valida.'); pass;
  END test_18_info_severity;

  PROCEDURE test_19_warn_severity IS
  BEGIN
    start_test('severidade WARN valida'); assert_true(core_error_pkg.is_valid_severity('WARN'), 'WARN deve ser valida.'); pass;
  END test_19_warn_severity;

  PROCEDURE test_20_error_severity IS
  BEGIN
    start_test('severidade ERROR valida'); assert_true(core_error_pkg.is_valid_severity('ERROR'), 'ERROR deve ser valida.'); pass;
  END test_20_error_severity;

  PROCEDURE test_21_fatal_severity IS
  BEGIN
    start_test('severidade FATAL valida'); assert_true(core_error_pkg.is_valid_severity('FATAL'), 'FATAL deve ser valida.'); pass;
  END test_21_fatal_severity;

  PROCEDURE test_22_null_severity IS
  BEGIN
    start_test('severidade NULL invalida'); assert_false(core_error_pkg.is_valid_severity(NULL), 'NULL deve ser invalida.'); pass;
  END test_22_null_severity;

  PROCEDURE test_23_unknown_severity IS
  BEGIN
    start_test('severidade desconhecida invalida'); assert_false(core_error_pkg.is_valid_severity('DEBUG'), 'DEBUG deve ser invalida.'); pass;
  END test_23_unknown_severity;

  PROCEDURE test_24_lowercase_severity IS
  BEGIN
    start_test('severidade minuscula normalizada');
    assert_equals(core_error_pkg.normalize_severity('error'), 'ERROR', 'Severidade deve normalizar.'); pass;
  END test_24_lowercase_severity;

  PROCEDURE test_25_spaced_severity IS
  BEGIN
    start_test('severidade com espacos normalizada');
    assert_equals(core_error_pkg.normalize_severity('  error  '), 'ERROR', 'Severidade deve remover espacos.'); pass;
  END test_25_spaced_severity;

  PROCEDURE test_26_builds_public_error IS
  BEGIN
    start_test('montar erro publico corretamente'); build_known;
    assert_equals(g_public_error.code, c_code, 'Codigo incorreto.');
    assert_equals(g_public_error.category, 'TECHNICAL_ERROR', 'Categoria incorreta.'); pass;
  END test_26_builds_public_error;

  PROCEDURE test_27_builds_policy IS
  BEGIN
    start_test('montar politica corretamente'); build_known;
    assert_equals(g_error_policy.severity, 'ERROR', 'Severidade incorreta.');
    assert_boolean_equals(g_error_policy.should_log, TRUE, 'should_log incorreto.'); pass;
  END test_27_builds_policy;

  PROCEDURE test_28_builder_normalizes_code IS
  BEGIN
    start_test('builder normaliza codigo'); build_known(p_code => ' bex-core-001 ');
    assert_equals(g_public_error.code, c_code, 'Codigo nao normalizado.'); pass;
  END test_28_builder_normalizes_code;

  PROCEDURE test_29_builder_normalizes_category IS
  BEGIN
    start_test('builder normaliza categoria'); build_known(p_category => ' technical_error ');
    assert_equals(g_public_error.category, 'TECHNICAL_ERROR', 'Categoria nao normalizada.'); pass;
  END test_29_builder_normalizes_category;

  PROCEDURE test_30_builder_normalizes_severity IS
  BEGIN
    start_test('builder normaliza severidade'); build_known(p_severity => ' error ');
    assert_equals(g_error_policy.severity, 'ERROR', 'Severidade nao normalizada.'); pass;
  END test_30_builder_normalizes_severity;

  PROCEDURE test_31_preserves_message IS
  BEGIN
    start_test('builder preserva mensagem externa'); build_known(p_message => 'Mensagem externa segura.');
    assert_equals(g_public_error.external_message, 'Mensagem externa segura.', 'Mensagem nao preservada.'); pass;
  END test_31_preserves_message;

  PROCEDURE test_32_retryable_true IS
  BEGIN
    start_test('builder preserva retryable TRUE'); build_known(p_retryable => TRUE);
    assert_boolean_equals(g_public_error.retryable, TRUE, 'retryable TRUE nao preservado.'); pass;
  END test_32_retryable_true;

  PROCEDURE test_33_retryable_false IS
  BEGIN
    start_test('builder preserva retryable FALSE'); build_known(p_retryable => FALSE);
    assert_boolean_equals(g_public_error.retryable, FALSE, 'retryable FALSE nao preservado.'); pass;
  END test_33_retryable_false;

  PROCEDURE test_34_should_log_true IS
  BEGIN
    start_test('builder preserva should_log TRUE'); build_known(p_should_log => TRUE);
    assert_boolean_equals(g_error_policy.should_log, TRUE, 'should_log TRUE nao preservado.'); pass;
  END test_34_should_log_true;

  PROCEDURE test_35_should_log_false IS
  BEGIN
    start_test('builder preserva should_log FALSE'); build_known(p_should_log => FALSE);
    assert_boolean_equals(g_error_policy.should_log, FALSE, 'should_log FALSE nao preservado.'); pass;
  END test_35_should_log_false;

  PROCEDURE test_36_known_error_with_trace IS
  BEGIN
    start_test('builder associa trace ativo'); core_trace_pkg.initialize(c_trace_id); build_known;
    assert_equals(g_public_error.trace_id, c_trace_id, 'Trace nao associado.'); pass;
  END test_36_known_error_with_trace;

  PROCEDURE test_37_known_error_without_trace IS
  BEGIN
    start_test('builder retorna trace NULL sem Trace ativo'); build_known;
    assert_null(g_public_error.trace_id, 'Trace deveria ser NULL.'); pass;
  END test_37_known_error_without_trace;

  PROCEDURE test_38_does_not_create_trace IS
  BEGIN
    start_test('builder nao cria Trace silenciosamente'); build_known;
    assert_false(core_trace_pkg.has_trace, 'Builder nao deve criar Trace.'); pass;
  END test_38_does_not_create_trace;

  PROCEDURE test_39_rejects_null_message IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('builder rejeita mensagem NULL');
    BEGIN build_known(p_message => NULL); EXCEPTION
      WHEN core_error_pkg.e_invalid_external_message THEN l_raised := TRUE;
    END;
    assert_raises(l_raised, 'Mensagem NULL deve falhar.'); pass;
  END test_39_rejects_null_message;

  PROCEDURE test_40_rejects_blank_message IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('builder rejeita mensagem vazia ou com espacos');
    BEGIN build_known(p_message => '   '); EXCEPTION
      WHEN core_error_pkg.e_invalid_external_message THEN l_raised := TRUE;
    END;
    assert_raises(l_raised, 'Mensagem em branco deve falhar.'); pass;
  END test_40_rejects_blank_message;

  PROCEDURE assert_outputs_are_null IS
  BEGIN
    assert_null(g_public_error.code, 'code deve estar limpo.');
    assert_null(g_public_error.category, 'category deve estar limpa.');
    assert_null(g_public_error.external_message, 'message deve estar limpa.');
    assert_boolean_null(g_public_error.retryable, 'retryable deve estar limpo.');
    assert_null(g_public_error.trace_id, 'trace deve estar limpo.');
    assert_null(g_error_policy.severity, 'severity deve estar limpa.');
    assert_boolean_null(g_error_policy.should_log, 'should_log deve estar limpo.');
  END assert_outputs_are_null;

  PROCEDURE test_41_clears_outputs_before_failure IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('builder limpa OUT antes de falha'); build_known;
    BEGIN build_known(p_code => 'INVALID'); EXCEPTION
      WHEN core_error_pkg.e_invalid_error_code THEN l_raised := TRUE;
    END;
    assert_raises(l_raised, 'Codigo invalido deve falhar.'); assert_outputs_are_null; pass;
  END test_41_clears_outputs_before_failure;

  PROCEDURE test_42_no_residual_outputs IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('builder nao mantem dados residuais'); build_known(p_retryable => TRUE);
    BEGIN build_known(p_category => 'INVALID'); EXCEPTION
      WHEN core_error_pkg.e_invalid_category THEN l_raised := TRUE;
    END;
    assert_raises(l_raised, 'Categoria invalida deve falhar.'); assert_outputs_are_null; pass;
  END test_42_no_residual_outputs;

  PROCEDURE test_43_technical_category IS
  BEGIN
    start_test('technical usa categoria TECHNICAL_ERROR'); build_technical;
    assert_equals(g_public_error.category, 'TECHNICAL_ERROR', 'Categoria tecnica incorreta.'); pass;
  END test_43_technical_category;

  PROCEDURE test_44_technical_severity IS
  BEGIN
    start_test('technical usa severidade ERROR'); build_technical;
    assert_equals(g_error_policy.severity, 'ERROR', 'Severidade tecnica incorreta.'); pass;
  END test_44_technical_severity;

  PROCEDURE test_45_technical_should_log IS
  BEGIN
    start_test('technical usa should_log TRUE'); build_technical;
    assert_boolean_equals(g_error_policy.should_log, TRUE, 'Technical deve solicitar log.'); pass;
  END test_45_technical_should_log;

  PROCEDURE test_46_technical_retryable IS
  BEGIN
    start_test('technical preserva retryable'); build_technical(p_retryable => TRUE);
    assert_boolean_equals(g_public_error.retryable, TRUE, 'retryable nao preservado.'); pass;
  END test_46_technical_retryable;

  PROCEDURE test_47_technical_code IS
  BEGIN
    start_test('technical preserva codigo normalizado'); build_technical(p_code => ' bex-core-002 ');
    assert_equals(g_public_error.code, 'BEX-CORE-002', 'Codigo tecnico incorreto.'); pass;
  END test_47_technical_code;

  PROCEDURE test_48_technical_message IS
  BEGIN
    start_test('technical preserva mensagem segura'); build_technical(p_message => 'Mensagem tecnica segura.');
    assert_equals(g_public_error.external_message, 'Mensagem tecnica segura.', 'Mensagem tecnica incorreta.'); pass;
  END test_48_technical_message;

  PROCEDURE test_49_technical_with_trace IS
  BEGIN
    start_test('technical associa trace existente'); core_trace_pkg.initialize(c_trace_id); build_technical;
    assert_equals(g_public_error.trace_id, c_trace_id, 'Trace tecnico nao associado.'); pass;
  END test_49_technical_with_trace;

  PROCEDURE test_50_technical_without_trace IS
  BEGIN
    start_test('technical funciona sem trace'); build_technical;
    assert_null(g_public_error.trace_id, 'Trace tecnico deveria ser NULL.');
    assert_false(core_trace_pkg.has_trace, 'Technical nao deve criar Trace.'); pass;
  END test_50_technical_without_trace;
BEGIN
  test_01_valid_minimum_code;
  test_02_valid_alphanumeric_context;
  test_03_lowercase_code_normalized;
  test_04_null_code;
  test_05_wrong_prefix;
  test_06_short_context;
  test_07_long_context;
  test_08_hyphenated_context;
  test_09_short_suffix;
  test_10_long_suffix;
  test_11_non_numeric_suffix;
  test_12_external_spaces;
  test_13_official_categories;
  test_14_null_category;
  test_15_unknown_category;
  test_16_lowercase_category;
  test_17_spaced_category;
  test_18_info_severity;
  test_19_warn_severity;
  test_20_error_severity;
  test_21_fatal_severity;
  test_22_null_severity;
  test_23_unknown_severity;
  test_24_lowercase_severity;
  test_25_spaced_severity;
  test_26_builds_public_error;
  test_27_builds_policy;
  test_28_builder_normalizes_code;
  test_29_builder_normalizes_category;
  test_30_builder_normalizes_severity;
  test_31_preserves_message;
  test_32_retryable_true;
  test_33_retryable_false;
  test_34_should_log_true;
  test_35_should_log_false;
  test_36_known_error_with_trace;
  test_37_known_error_without_trace;
  test_38_does_not_create_trace;
  test_39_rejects_null_message;
  test_40_rejects_blank_message;
  test_41_clears_outputs_before_failure;
  test_42_no_residual_outputs;
  test_43_technical_category;
  test_44_technical_severity;
  test_45_technical_should_log;
  test_46_technical_retryable;
  test_47_technical_code;
  test_48_technical_message;
  test_49_technical_with_trace;
  test_50_technical_without_trace;

  core_trace_pkg.clear;
  DBMS_OUTPUT.PUT_LINE('SUCCESS - CORE_ERROR_PKG (50 testes)');
EXCEPTION
  WHEN OTHERS THEN
    core_trace_pkg.clear;
    DBMS_OUTPUT.PUT_LINE('FAIL - ' || g_current_test);
    RAISE;
END;
/
