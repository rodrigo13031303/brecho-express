SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  g_test_count   PLS_INTEGER := 0;
  g_current_test VARCHAR2(200);

  c_trace_id CONSTANT core_trace_pkg.t_trace_id :=
    '0123456789ABCDEF0123456789ABCDEF';
  c_actor_id CONSTANT core_context_pkg.t_actor_public_id :=
    'ABCDEF0123456789ABCDEF0123456789';

  PROCEDURE assert_true(
    p_condition IN BOOLEAN,
    p_message   IN VARCHAR2
  ) IS
  BEGIN
    IF p_condition IS NULL OR NOT p_condition THEN
      RAISE_APPLICATION_ERROR(-20999, p_message);
    END IF;
  END assert_true;

  PROCEDURE assert_false(
    p_condition IN BOOLEAN,
    p_message   IN VARCHAR2
  ) IS
  BEGIN
    IF p_condition IS NULL OR p_condition THEN
      RAISE_APPLICATION_ERROR(-20999, p_message);
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
      RAISE_APPLICATION_ERROR(-20999, p_message);
    END IF;
  END assert_equals;

  PROCEDURE assert_raises(
    p_raised  IN BOOLEAN,
    p_message IN VARCHAR2
  ) IS
  BEGIN
    assert_true(p_raised, p_message);
  END assert_raises;

  PROCEDURE reset_environment IS
  BEGIN
    core_security_context_pkg.clear;
    core_context_pkg.clear;
    core_trace_pkg.clear;
  END reset_environment;

  PROCEDURE start_test(
    p_test_name IN VARCHAR2
  ) IS
  BEGIN
    g_current_test := p_test_name;
    reset_environment;
  END start_test;

  PROCEDURE pass IS
  BEGIN
    reset_environment;
    g_test_count := g_test_count + 1;
    DBMS_OUTPUT.PUT_LINE(
      'PASS ' || LPAD(g_test_count, 2, '0') || ' - ' || g_current_test
    );
  END pass;

  PROCEDURE initialize_execution_anonymous IS
  BEGIN
    core_trace_pkg.initialize(c_trace_id);
    core_context_pkg.initialize(
      core_context_pkg.c_origin_external,
      core_context_pkg.c_mode_synchronous,
      NULL,
      FALSE
    );
  END initialize_execution_anonymous;

  PROCEDURE initialize_execution_authenticated IS
  BEGIN
    core_trace_pkg.initialize(c_trace_id);
    core_context_pkg.initialize(
      core_context_pkg.c_origin_external,
      core_context_pkg.c_mode_synchronous,
      c_actor_id,
      TRUE
    );
  END initialize_execution_authenticated;

  PROCEDURE initialize_security(
    p_actor_type            IN core_security_context_pkg.t_actor_type,
    p_authentication_method IN core_security_context_pkg.t_authentication_method
  ) IS
  BEGIN
    core_security_context_pkg.initialize(
      p_actor_type,
      p_authentication_method
    );
  END initialize_security;

  PROCEDURE assert_getters_unavailable IS
    l_actor_raised  BOOLEAN := FALSE;
    l_method_raised BOOLEAN := FALSE;
    l_actor_type    core_security_context_pkg.t_actor_type;
    l_method        core_security_context_pkg.t_authentication_method;
  BEGIN
    BEGIN
      l_actor_type := core_security_context_pkg.actor_type;
    EXCEPTION
      WHEN core_security_context_pkg.e_security_context_not_initialized THEN
        l_actor_raised := TRUE;
    END;

    BEGIN
      l_method := core_security_context_pkg.authentication_method;
    EXCEPTION
      WHEN core_security_context_pkg.e_security_context_not_initialized THEN
        l_method_raised := TRUE;
    END;

    assert_raises(l_actor_raised, 'actor_type deveria estar indisponivel.');
    assert_raises(l_method_raised, 'authentication_method deveria estar indisponivel.');
  END assert_getters_unavailable;

  PROCEDURE assert_invalid_state(
    p_actor_type            IN core_security_context_pkg.t_actor_type,
    p_authentication_method IN core_security_context_pkg.t_authentication_method
  ) IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    BEGIN
      initialize_security(p_actor_type, p_authentication_method);
    EXCEPTION
      WHEN core_security_context_pkg.e_invalid_security_state THEN
        l_raised := TRUE;
    END;

    assert_raises(l_raised, 'Combinacao invalida deve levantar e_invalid_security_state.');
    assert_false(
      core_security_context_pkg.is_initialized,
      'Combinacao invalida nao pode inicializar o contexto de seguranca.'
    );
  END assert_invalid_state;

  PROCEDURE test_01_starts_uninitialized IS
  BEGIN
    start_test('contexto de seguranca inicia nao inicializado');
    assert_false(core_security_context_pkg.is_initialized, 'Contexto deve iniciar inativo.');
    pass;
  END test_01_starts_uninitialized;

  PROCEDURE test_02_clear_before_initialize IS
  BEGIN
    start_test('clear antes de initialize e seguro');
    core_security_context_pkg.clear;
    assert_false(core_security_context_pkg.is_initialized, 'clear deve manter contexto inativo.');
    pass;
  END test_02_clear_before_initialize;

  PROCEDURE test_03_initialize_activates IS
  BEGIN
    start_test('initialize ativa contexto de seguranca');
    initialize_execution_anonymous;
    initialize_security('ANONYMOUS', 'NONE');
    assert_true(core_security_context_pkg.is_initialized, 'initialize deve ativar o contexto.');
    pass;
  END test_03_initialize_activates;

  PROCEDURE test_04_actor_getter_requires_context IS
  BEGIN
    start_test('actor_type exige contexto inicializado');
    assert_getters_unavailable;
    pass;
  END test_04_actor_getter_requires_context;

  PROCEDURE test_05_method_getter_requires_context IS
    l_raised BOOLEAN := FALSE;
    l_value  core_security_context_pkg.t_authentication_method;
  BEGIN
    start_test('authentication_method exige contexto inicializado');
    BEGIN
      l_value := core_security_context_pkg.authentication_method;
    EXCEPTION
      WHEN core_security_context_pkg.e_security_context_not_initialized THEN
        l_raised := TRUE;
    END;
    assert_raises(l_raised, 'authentication_method deve falhar sem initialize.');
    pass;
  END test_05_method_getter_requires_context;

  PROCEDURE test_06_getters_return_values IS
  BEGIN
    start_test('getters retornam atributos publicados');
    initialize_execution_anonymous;
    initialize_security('ANONYMOUS', 'NONE');
    assert_equals(core_security_context_pkg.actor_type, 'ANONYMOUS', 'ActorType incorreto.');
    assert_equals(core_security_context_pkg.authentication_method, 'NONE', 'Metodo incorreto.');
    pass;
  END test_06_getters_return_values;

  PROCEDURE test_07_second_initialize_fails IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('segundo initialize falha e preserva estado');
    initialize_execution_anonymous;
    initialize_security('ANONYMOUS', 'NONE');
    BEGIN
      initialize_security('SYSTEM', 'INTERNAL');
    EXCEPTION
      WHEN core_security_context_pkg.e_security_context_already_initialized THEN
        l_raised := TRUE;
    END;
    assert_raises(l_raised, 'Segundo initialize deve falhar.');
    assert_equals(core_security_context_pkg.actor_type, 'ANONYMOUS', 'Estado original mudou.');
    assert_equals(core_security_context_pkg.authentication_method, 'NONE', 'Metodo original mudou.');
    pass;
  END test_07_second_initialize_fails;

  PROCEDURE test_08_requires_execution_context IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('initialize exige Execution Context');
    BEGIN
      initialize_security('ANONYMOUS', 'NONE');
    EXCEPTION
      WHEN core_security_context_pkg.e_execution_context_not_initialized THEN
        l_raised := TRUE;
    END;
    assert_raises(l_raised, 'Execution Context deve ser obrigatorio.');
    assert_false(core_security_context_pkg.is_initialized, 'Falha deve manter contexto inativo.');
    pass;
  END test_08_requires_execution_context;

  PROCEDURE test_09_actor_null_invalid IS
  BEGIN
    start_test('ActorType NULL e invalido');
    assert_false(core_security_context_pkg.is_valid_actor_type(NULL), 'NULL deve ser invalido.');
    pass;
  END test_09_actor_null_invalid;

  PROCEDURE test_10_actor_anonymous_valid IS
  BEGIN
    start_test('ActorType ANONYMOUS e valido');
    assert_true(core_security_context_pkg.is_valid_actor_type('ANONYMOUS'), 'ANONYMOUS deve ser valido.');
    pass;
  END test_10_actor_anonymous_valid;

  PROCEDURE test_11_actor_user_valid IS
  BEGIN
    start_test('ActorType USER e valido');
    assert_true(core_security_context_pkg.is_valid_actor_type('USER'), 'USER deve ser valido.');
    pass;
  END test_11_actor_user_valid;

  PROCEDURE test_12_actor_system_valid IS
  BEGIN
    start_test('ActorType SYSTEM e valido');
    assert_true(core_security_context_pkg.is_valid_actor_type('SYSTEM'), 'SYSTEM deve ser valido.');
    pass;
  END test_12_actor_system_valid;

  PROCEDURE test_13_actor_service_invalid IS
  BEGIN
    start_test('ActorType SERVICE permanece fora da primeira versao');
    assert_false(core_security_context_pkg.is_valid_actor_type('SERVICE'), 'SERVICE deve ser invalido.');
    pass;
  END test_13_actor_service_invalid;

  PROCEDURE test_14_actor_lowercase_valid IS
  BEGIN
    start_test('validador aceita ActorType minusculo');
    assert_true(core_security_context_pkg.is_valid_actor_type('user'), 'user deve ser normalizado.');
    pass;
  END test_14_actor_lowercase_valid;

  PROCEDURE test_15_actor_spaces_valid IS
  BEGIN
    start_test('validador remove espacos do ActorType');
    assert_true(core_security_context_pkg.is_valid_actor_type('  system  '), 'Espacos devem ser removidos.');
    pass;
  END test_15_actor_spaces_valid;

  PROCEDURE test_16_method_null_invalid IS
  BEGIN
    start_test('AuthenticationMethod NULL e invalido');
    assert_false(core_security_context_pkg.is_valid_authentication_method(NULL), 'NULL deve ser invalido.');
    pass;
  END test_16_method_null_invalid;

  PROCEDURE test_17_method_none_valid IS
  BEGIN
    start_test('AuthenticationMethod NONE e valido');
    assert_true(core_security_context_pkg.is_valid_authentication_method('NONE'), 'NONE deve ser valido.');
    pass;
  END test_17_method_none_valid;

  PROCEDURE test_18_method_session_valid IS
  BEGIN
    start_test('AuthenticationMethod SESSION e valido');
    assert_true(core_security_context_pkg.is_valid_authentication_method('SESSION'), 'SESSION deve ser valido.');
    pass;
  END test_18_method_session_valid;

  PROCEDURE test_19_method_token_valid IS
  BEGIN
    start_test('AuthenticationMethod TOKEN e valido');
    assert_true(core_security_context_pkg.is_valid_authentication_method('TOKEN'), 'TOKEN deve ser valido.');
    pass;
  END test_19_method_token_valid;

  PROCEDURE test_20_method_internal_valid IS
  BEGIN
    start_test('AuthenticationMethod INTERNAL e valido');
    assert_true(core_security_context_pkg.is_valid_authentication_method('INTERNAL'), 'INTERNAL deve ser valido.');
    pass;
  END test_20_method_internal_valid;

  PROCEDURE test_21_method_unknown_invalid IS
  BEGIN
    start_test('AuthenticationMethod desconhecido e invalido');
    assert_false(core_security_context_pkg.is_valid_authentication_method('PASSWORD'), 'PASSWORD deve ser invalido.');
    pass;
  END test_21_method_unknown_invalid;

  PROCEDURE test_22_method_lowercase_valid IS
  BEGIN
    start_test('validador aceita AuthenticationMethod minusculo');
    assert_true(core_security_context_pkg.is_valid_authentication_method('token'), 'token deve ser normalizado.');
    pass;
  END test_22_method_lowercase_valid;

  PROCEDURE test_23_method_spaces_valid IS
  BEGIN
    start_test('validador remove espacos do AuthenticationMethod');
    assert_true(core_security_context_pkg.is_valid_authentication_method('  session  '), 'Espacos devem ser removidos.');
    pass;
  END test_23_method_spaces_valid;

  PROCEDURE test_24_initialize_normalizes_actor_case IS
  BEGIN
    start_test('initialize normaliza letras do ActorType');
    initialize_execution_anonymous;
    initialize_security('anonymous', 'NONE');
    assert_equals(core_security_context_pkg.actor_type, 'ANONYMOUS', 'ActorType deve ser maiusculo.');
    pass;
  END test_24_initialize_normalizes_actor_case;

  PROCEDURE test_25_initialize_trims_actor IS
  BEGIN
    start_test('initialize remove espacos do ActorType');
    initialize_execution_anonymous;
    initialize_security('  anonymous  ', 'NONE');
    assert_equals(core_security_context_pkg.actor_type, 'ANONYMOUS', 'ActorType deve ser aparado.');
    pass;
  END test_25_initialize_trims_actor;

  PROCEDURE test_26_initialize_normalizes_method_case IS
  BEGIN
    start_test('initialize normaliza letras do AuthenticationMethod');
    initialize_execution_anonymous;
    initialize_security('ANONYMOUS', 'none');
    assert_equals(core_security_context_pkg.authentication_method, 'NONE', 'Metodo deve ser maiusculo.');
    pass;
  END test_26_initialize_normalizes_method_case;

  PROCEDURE test_27_initialize_trims_method IS
  BEGIN
    start_test('initialize remove espacos do AuthenticationMethod');
    initialize_execution_anonymous;
    initialize_security('ANONYMOUS', '  none  ');
    assert_equals(core_security_context_pkg.authentication_method, 'NONE', 'Metodo deve ser aparado.');
    pass;
  END test_27_initialize_trims_method;

  PROCEDURE test_28_anonymous_none_valid IS
  BEGIN
    start_test('ANONYMOUS com NONE e valido');
    initialize_execution_anonymous;
    initialize_security('ANONYMOUS', 'NONE');
    assert_true(core_security_context_pkg.is_initialized, 'Combinacao deve ser valida.');
    pass;
  END test_28_anonymous_none_valid;

  PROCEDURE test_29_user_session_valid IS
  BEGIN
    start_test('USER com SESSION e valido');
    initialize_execution_authenticated;
    initialize_security('USER', 'SESSION');
    assert_equals(core_security_context_pkg.authentication_method, 'SESSION', 'SESSION deve ser publicado.');
    pass;
  END test_29_user_session_valid;

  PROCEDURE test_30_user_token_valid IS
  BEGIN
    start_test('USER com TOKEN e valido');
    initialize_execution_authenticated;
    initialize_security('USER', 'TOKEN');
    assert_equals(core_security_context_pkg.authentication_method, 'TOKEN', 'TOKEN deve ser publicado.');
    pass;
  END test_30_user_token_valid;

  PROCEDURE test_31_system_internal_valid IS
  BEGIN
    start_test('SYSTEM com INTERNAL e valido');
    initialize_execution_anonymous;
    initialize_security('SYSTEM', 'INTERNAL');
    assert_equals(core_security_context_pkg.actor_type, 'SYSTEM', 'SYSTEM deve ser publicado.');
    pass;
  END test_31_system_internal_valid;

  PROCEDURE test_32_anonymous_session_invalid IS
  BEGIN
    start_test('ANONYMOUS com SESSION e invalido');
    initialize_execution_anonymous;
    assert_invalid_state('ANONYMOUS', 'SESSION');
    pass;
  END test_32_anonymous_session_invalid;

  PROCEDURE test_33_anonymous_token_invalid IS
  BEGIN
    start_test('ANONYMOUS com TOKEN e invalido');
    initialize_execution_anonymous;
    assert_invalid_state('ANONYMOUS', 'TOKEN');
    pass;
  END test_33_anonymous_token_invalid;

  PROCEDURE test_34_anonymous_internal_invalid IS
  BEGIN
    start_test('ANONYMOUS com INTERNAL e invalido');
    initialize_execution_anonymous;
    assert_invalid_state('ANONYMOUS', 'INTERNAL');
    pass;
  END test_34_anonymous_internal_invalid;

  PROCEDURE test_35_user_none_invalid IS
  BEGIN
    start_test('USER com NONE e invalido');
    initialize_execution_authenticated;
    assert_invalid_state('USER', 'NONE');
    pass;
  END test_35_user_none_invalid;

  PROCEDURE test_36_user_internal_invalid IS
  BEGIN
    start_test('USER com INTERNAL e invalido');
    initialize_execution_authenticated;
    assert_invalid_state('USER', 'INTERNAL');
    pass;
  END test_36_user_internal_invalid;

  PROCEDURE test_37_system_none_invalid IS
  BEGIN
    start_test('SYSTEM com NONE e invalido');
    initialize_execution_anonymous;
    assert_invalid_state('SYSTEM', 'NONE');
    pass;
  END test_37_system_none_invalid;

  PROCEDURE test_38_system_session_invalid IS
  BEGIN
    start_test('SYSTEM com SESSION e invalido');
    initialize_execution_anonymous;
    assert_invalid_state('SYSTEM', 'SESSION');
    pass;
  END test_38_system_session_invalid;

  PROCEDURE test_39_system_token_invalid IS
  BEGIN
    start_test('SYSTEM com TOKEN e invalido');
    initialize_execution_anonymous;
    assert_invalid_state('SYSTEM', 'TOKEN');
    pass;
  END test_39_system_token_invalid;

  PROCEDURE test_40_anonymous_rejects_authenticated IS
  BEGIN
    start_test('ANONYMOUS rejeita Execution Context autenticado');
    initialize_execution_authenticated;
    assert_invalid_state('ANONYMOUS', 'NONE');
    pass;
  END test_40_anonymous_rejects_authenticated;

  PROCEDURE test_41_user_requires_authenticated IS
  BEGIN
    start_test('USER exige Execution Context autenticado');
    initialize_execution_anonymous;
    assert_invalid_state('USER', 'SESSION');
    pass;
  END test_41_user_requires_authenticated;

  PROCEDURE test_42_system_rejects_authenticated IS
  BEGIN
    start_test('SYSTEM rejeita Execution Context autenticado');
    initialize_execution_authenticated;
    assert_invalid_state('SYSTEM', 'INTERNAL');
    pass;
  END test_42_system_rejects_authenticated;

  PROCEDURE test_43_invalid_actor_is_atomic IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('ActorType invalido nao deixa estado parcial');
    initialize_execution_anonymous;
    BEGIN
      initialize_security('INVALID', 'NONE');
    EXCEPTION
      WHEN core_security_context_pkg.e_invalid_actor_type THEN
        l_raised := TRUE;
    END;
    assert_raises(l_raised, 'ActorType invalido deve levantar excecao nominal.');
    assert_false(core_security_context_pkg.is_initialized, 'Falha deve manter estado inativo.');
    assert_getters_unavailable;
    pass;
  END test_43_invalid_actor_is_atomic;

  PROCEDURE test_44_invalid_method_is_atomic IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('AuthenticationMethod invalido nao deixa estado parcial');
    initialize_execution_anonymous;
    BEGIN
      initialize_security('ANONYMOUS', 'INVALID');
    EXCEPTION
      WHEN core_security_context_pkg.e_invalid_authentication_method THEN
        l_raised := TRUE;
    END;
    assert_raises(l_raised, 'Metodo invalido deve levantar excecao nominal.');
    assert_false(core_security_context_pkg.is_initialized, 'Falha deve manter estado inativo.');
    assert_getters_unavailable;
    pass;
  END test_44_invalid_method_is_atomic;

  PROCEDURE test_45_clear_allows_clean_reinitialize IS
  BEGIN
    start_test('clear permite reinicializacao sem estado residual');
    initialize_execution_authenticated;
    initialize_security('USER', 'TOKEN');
    core_security_context_pkg.clear;
    assert_false(core_security_context_pkg.is_initialized, 'clear deve desativar o contexto.');
    assert_getters_unavailable;
    core_context_pkg.clear;
    core_context_pkg.initialize(
      core_context_pkg.c_origin_internal,
      core_context_pkg.c_mode_synchronous,
      NULL,
      FALSE
    );
    initialize_security('SYSTEM', 'INTERNAL');
    assert_equals(core_security_context_pkg.actor_type, 'SYSTEM', 'Actor anterior nao pode permanecer.');
    assert_equals(core_security_context_pkg.authentication_method, 'INTERNAL', 'Metodo anterior nao pode permanecer.');
    pass;
  END test_45_clear_allows_clean_reinitialize;

  PROCEDURE test_46_clear_is_idempotent_and_local IS
  BEGIN
    start_test('clear e idempotente e preserva Execution Context');
    initialize_execution_anonymous;
    initialize_security('ANONYMOUS', 'NONE');
    core_security_context_pkg.clear;
    core_security_context_pkg.clear;
    core_security_context_pkg.clear;
    assert_false(core_security_context_pkg.is_initialized, 'Multiplos clear devem manter estado inativo.');
    assert_true(core_context_pkg.is_initialized, 'clear nao pode limpar Execution Context.');
    assert_false(core_context_pkg.is_authenticated, 'Execution Context deve permanecer anonimo.');
    pass;
  END test_46_clear_is_idempotent_and_local;
BEGIN
  test_01_starts_uninitialized;
  test_02_clear_before_initialize;
  test_03_initialize_activates;
  test_04_actor_getter_requires_context;
  test_05_method_getter_requires_context;
  test_06_getters_return_values;
  test_07_second_initialize_fails;
  test_08_requires_execution_context;
  test_09_actor_null_invalid;
  test_10_actor_anonymous_valid;
  test_11_actor_user_valid;
  test_12_actor_system_valid;
  test_13_actor_service_invalid;
  test_14_actor_lowercase_valid;
  test_15_actor_spaces_valid;
  test_16_method_null_invalid;
  test_17_method_none_valid;
  test_18_method_session_valid;
  test_19_method_token_valid;
  test_20_method_internal_valid;
  test_21_method_unknown_invalid;
  test_22_method_lowercase_valid;
  test_23_method_spaces_valid;
  test_24_initialize_normalizes_actor_case;
  test_25_initialize_trims_actor;
  test_26_initialize_normalizes_method_case;
  test_27_initialize_trims_method;
  test_28_anonymous_none_valid;
  test_29_user_session_valid;
  test_30_user_token_valid;
  test_31_system_internal_valid;
  test_32_anonymous_session_invalid;
  test_33_anonymous_token_invalid;
  test_34_anonymous_internal_invalid;
  test_35_user_none_invalid;
  test_36_user_internal_invalid;
  test_37_system_none_invalid;
  test_38_system_session_invalid;
  test_39_system_token_invalid;
  test_40_anonymous_rejects_authenticated;
  test_41_user_requires_authenticated;
  test_42_system_rejects_authenticated;
  test_43_invalid_actor_is_atomic;
  test_44_invalid_method_is_atomic;
  test_45_clear_allows_clean_reinitialize;
  test_46_clear_is_idempotent_and_local;

  reset_environment;
  DBMS_OUTPUT.PUT_LINE('SUCCESS - CORE_SECURITY_CONTEXT_PKG (46 testes)');
EXCEPTION
  WHEN OTHERS THEN
    reset_environment;
    DBMS_OUTPUT.PUT_LINE('FAIL - ' || g_current_test);
    RAISE;
END;
/
