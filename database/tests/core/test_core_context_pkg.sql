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

  PROCEDURE assert_null(
    p_actual  IN VARCHAR2,
    p_message IN VARCHAR2
  ) IS
  BEGIN
    IF p_actual IS NOT NULL THEN
      RAISE_APPLICATION_ERROR(-20999, p_message);
    END IF;
  END assert_null;

  PROCEDURE assert_not_null(
    p_actual  IN VARCHAR2,
    p_message IN VARCHAR2
  ) IS
  BEGIN
    IF p_actual IS NULL THEN
      RAISE_APPLICATION_ERROR(-20999, p_message);
    END IF;
  END assert_not_null;

  PROCEDURE assert_timestamp_equals(
    p_actual   IN TIMESTAMP WITH TIME ZONE,
    p_expected IN TIMESTAMP WITH TIME ZONE,
    p_message  IN VARCHAR2
  ) IS
  BEGIN
    IF p_actual IS NULL
       OR p_expected IS NULL
       OR p_actual <> p_expected THEN
      RAISE_APPLICATION_ERROR(-20999, p_message);
    END IF;
  END assert_timestamp_equals;

  PROCEDURE assert_raises(
    p_raised  IN BOOLEAN,
    p_message IN VARCHAR2
  ) IS
  BEGIN
    assert_true(p_raised, p_message);
  END assert_raises;

  PROCEDURE reset_environment IS
  BEGIN
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

  PROCEDURE initialize_anonymous(
    p_origin IN core_context_pkg.t_execution_origin :=
      core_context_pkg.c_origin_external,
    p_mode   IN core_context_pkg.t_execution_mode :=
      core_context_pkg.c_mode_synchronous
  ) IS
  BEGIN
    core_trace_pkg.initialize(c_trace_id);
    core_context_pkg.initialize(p_origin, p_mode, NULL, FALSE);
  END initialize_anonymous;

  PROCEDURE assert_getters_unavailable IS
    l_trace_raised         BOOLEAN := FALSE;
    l_started_at_raised    BOOLEAN := FALSE;
    l_origin_raised        BOOLEAN := FALSE;
    l_mode_raised          BOOLEAN := FALSE;
    l_actor_raised         BOOLEAN := FALSE;
    l_authenticated_raised BOOLEAN := FALSE;
    l_trace                core_trace_pkg.t_trace_id;
    l_started_at           core_context_pkg.t_started_at;
    l_origin               core_context_pkg.t_execution_origin;
    l_mode                 core_context_pkg.t_execution_mode;
    l_actor                core_context_pkg.t_actor_public_id;
    l_authenticated        BOOLEAN;
  BEGIN
    BEGIN
      l_trace := core_context_pkg.trace_id;
    EXCEPTION
      WHEN core_context_pkg.e_context_not_initialized THEN l_trace_raised := TRUE;
    END;
    BEGIN
      l_started_at := core_context_pkg.started_at;
    EXCEPTION
      WHEN core_context_pkg.e_context_not_initialized THEN l_started_at_raised := TRUE;
    END;
    BEGIN
      l_origin := core_context_pkg.execution_origin;
    EXCEPTION
      WHEN core_context_pkg.e_context_not_initialized THEN l_origin_raised := TRUE;
    END;
    BEGIN
      l_mode := core_context_pkg.execution_mode;
    EXCEPTION
      WHEN core_context_pkg.e_context_not_initialized THEN l_mode_raised := TRUE;
    END;
    BEGIN
      l_actor := core_context_pkg.actor_public_id;
    EXCEPTION
      WHEN core_context_pkg.e_context_not_initialized THEN l_actor_raised := TRUE;
    END;
    BEGIN
      l_authenticated := core_context_pkg.is_authenticated;
    EXCEPTION
      WHEN core_context_pkg.e_context_not_initialized THEN l_authenticated_raised := TRUE;
    END;

    assert_raises(l_trace_raised, 'trace_id deveria estar indisponivel.');
    assert_raises(l_started_at_raised, 'started_at deveria estar indisponivel.');
    assert_raises(l_origin_raised, 'execution_origin deveria estar indisponivel.');
    assert_raises(l_mode_raised, 'execution_mode deveria estar indisponivel.');
    assert_raises(l_actor_raised, 'actor_public_id deveria estar indisponivel.');
    assert_raises(l_authenticated_raised, 'is_authenticated deveria estar indisponivel.');
  END assert_getters_unavailable;

  PROCEDURE test_01_context_starts_uninitialized IS
  BEGIN
    start_test('contexto inicia nao inicializado');
    assert_false(core_context_pkg.is_initialized, 'Contexto deve iniciar inativo.');
    pass;
  END test_01_context_starts_uninitialized;

  PROCEDURE test_02_is_initialized_false_initially IS
  BEGIN
    start_test('is_initialized retorna FALSE inicialmente');
    assert_false(core_context_pkg.is_initialized, 'is_initialized deve retornar FALSE.');
    pass;
  END test_02_is_initialized_false_initially;

  PROCEDURE test_03_initialize_activates_context IS
  BEGIN
    start_test('initialize inicializa corretamente');
    initialize_anonymous;
    assert_true(core_context_pkg.is_initialized, 'initialize deve ativar o contexto.');
    pass;
  END test_03_initialize_activates_context;

  PROCEDURE test_04_initialize_clear_restores_state IS
  BEGIN
    start_test('initialize seguido de clear retorna ao estado inicial');
    initialize_anonymous;
    core_context_pkg.clear;
    assert_false(core_context_pkg.is_initialized, 'clear deve desativar o contexto.');
    pass;
  END test_04_initialize_clear_restores_state;

  PROCEDURE test_05_clear_is_idempotent IS
  BEGIN
    start_test('clear e idempotente');
    core_context_pkg.clear;
    core_context_pkg.clear;
    assert_false(core_context_pkg.is_initialized, 'clear repetido deve manter contexto inativo.');
    pass;
  END test_05_clear_is_idempotent;

  PROCEDURE test_06_second_initialize_fails IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('segundo initialize sem clear falha');
    initialize_anonymous;
    BEGIN
      core_context_pkg.initialize(
        core_context_pkg.c_origin_job,
        core_context_pkg.c_mode_batch,
        NULL,
        FALSE
      );
    EXCEPTION
      WHEN core_context_pkg.e_context_already_initialized THEN
        l_raised := TRUE;
    END;
    assert_raises(l_raised, 'Segundo initialize deve falhar.');
    assert_true(core_context_pkg.is_initialized, 'Contexto original deve permanecer ativo.');
    pass;
  END test_06_second_initialize_fails;

  PROCEDURE test_07_initialize_requires_trace IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('initialize falha sem Trace ativo');
    BEGIN
      core_context_pkg.initialize(
        core_context_pkg.c_origin_external,
        core_context_pkg.c_mode_synchronous,
        NULL,
        FALSE
      );
    EXCEPTION
      WHEN core_context_pkg.e_trace_not_initialized THEN
        l_raised := TRUE;
    END;
    assert_raises(l_raised, 'initialize deve exigir Trace ativo.');
    pass;
  END test_07_initialize_requires_trace;

  PROCEDURE test_08_existing_trace_is_reused IS
  BEGIN
    start_test('Trace existente e reutilizado');
    initialize_anonymous;
    assert_equals(core_trace_pkg.current_trace_id, c_trace_id, 'Trace nao deve ser substituido.');
    pass;
  END test_08_existing_trace_is_reused;

  PROCEDURE test_09_stored_trace_matches_current IS
  BEGIN
    start_test('TraceId armazenado corresponde ao Trace corrente');
    initialize_anonymous;
    assert_equals(
      core_context_pkg.trace_id,
      core_trace_pkg.current_trace_id,
      'Trace do contexto deve corresponder ao Trace corrente.'
    );
    pass;
  END test_09_stored_trace_matches_current;

  PROCEDURE test_10_context_clear_preserves_trace IS
  BEGIN
    start_test('clear do Context nao limpa o Trace');
    initialize_anonymous;
    core_context_pkg.clear;
    assert_true(core_trace_pkg.has_trace, 'clear do contexto deve preservar o Trace.');
    pass;
  END test_10_context_clear_preserves_trace;

  PROCEDURE test_11_trace_id_requires_context IS
    l_raised BOOLEAN := FALSE;
    l_value  core_trace_pkg.t_trace_id;
  BEGIN
    start_test('trace_id falha antes de initialize');
    BEGIN
      l_value := core_context_pkg.trace_id;
    EXCEPTION
      WHEN core_context_pkg.e_context_not_initialized THEN l_raised := TRUE;
    END;
    assert_raises(l_raised, 'trace_id deve exigir contexto ativo.');
    pass;
  END test_11_trace_id_requires_context;

  PROCEDURE test_12_started_at_requires_context IS
    l_raised BOOLEAN := FALSE;
    l_value  core_context_pkg.t_started_at;
  BEGIN
    start_test('started_at falha antes de initialize');
    BEGIN
      l_value := core_context_pkg.started_at;
    EXCEPTION
      WHEN core_context_pkg.e_context_not_initialized THEN l_raised := TRUE;
    END;
    assert_raises(l_raised, 'started_at deve exigir contexto ativo.');
    pass;
  END test_12_started_at_requires_context;

  PROCEDURE test_13_origin_requires_context IS
    l_raised BOOLEAN := FALSE;
    l_value  core_context_pkg.t_execution_origin;
  BEGIN
    start_test('execution_origin falha antes de initialize');
    BEGIN
      l_value := core_context_pkg.execution_origin;
    EXCEPTION
      WHEN core_context_pkg.e_context_not_initialized THEN l_raised := TRUE;
    END;
    assert_raises(l_raised, 'execution_origin deve exigir contexto ativo.');
    pass;
  END test_13_origin_requires_context;

  PROCEDURE test_14_mode_requires_context IS
    l_raised BOOLEAN := FALSE;
    l_value  core_context_pkg.t_execution_mode;
  BEGIN
    start_test('execution_mode falha antes de initialize');
    BEGIN
      l_value := core_context_pkg.execution_mode;
    EXCEPTION
      WHEN core_context_pkg.e_context_not_initialized THEN l_raised := TRUE;
    END;
    assert_raises(l_raised, 'execution_mode deve exigir contexto ativo.');
    pass;
  END test_14_mode_requires_context;

  PROCEDURE test_15_actor_requires_context IS
    l_raised BOOLEAN := FALSE;
    l_value  core_context_pkg.t_actor_public_id;
  BEGIN
    start_test('actor_public_id falha antes de initialize');
    BEGIN
      l_value := core_context_pkg.actor_public_id;
    EXCEPTION
      WHEN core_context_pkg.e_context_not_initialized THEN l_raised := TRUE;
    END;
    assert_raises(l_raised, 'actor_public_id deve exigir contexto ativo.');
    pass;
  END test_15_actor_requires_context;

  PROCEDURE test_16_authenticated_requires_context IS
    l_raised BOOLEAN := FALSE;
    l_value  BOOLEAN;
  BEGIN
    start_test('is_authenticated falha antes de initialize');
    BEGIN
      l_value := core_context_pkg.is_authenticated;
    EXCEPTION
      WHEN core_context_pkg.e_context_not_initialized THEN l_raised := TRUE;
    END;
    assert_raises(l_raised, 'is_authenticated deve exigir contexto ativo.');
    pass;
  END test_16_authenticated_requires_context;

  PROCEDURE test_17_started_at_is_filled IS
    l_started_at core_context_pkg.t_started_at;
  BEGIN
    start_test('StartedAt e preenchido');
    initialize_anonymous;
    l_started_at := core_context_pkg.started_at;
    assert_true(l_started_at <= SYSTIMESTAMP, 'StartedAt deve ser preenchido na inicializacao.');
    pass;
  END test_17_started_at_is_filled;

  PROCEDURE test_18_started_at_is_not_null IS
  BEGIN
    start_test('StartedAt nao e nulo');
    initialize_anonymous;
    assert_not_null(TO_CHAR(core_context_pkg.started_at), 'StartedAt nao pode ser NULL.');
    pass;
  END test_18_started_at_is_not_null;

  PROCEDURE test_19_started_at_is_stable IS
    l_first  core_context_pkg.t_started_at;
    l_second core_context_pkg.t_started_at;
  BEGIN
    start_test('StartedAt permanece constante durante a execucao');
    initialize_anonymous;
    l_first := core_context_pkg.started_at;
    l_second := core_context_pkg.started_at;
    assert_timestamp_equals(l_second, l_first, 'StartedAt deve permanecer constante.');
    pass;
  END test_19_started_at_is_stable;

  PROCEDURE assert_origin_is_accepted(
    p_origin IN core_context_pkg.t_execution_origin
  ) IS
  BEGIN
    initialize_anonymous(p_origin, core_context_pkg.c_mode_synchronous);
    assert_equals(core_context_pkg.execution_origin, p_origin, 'Origem valida nao foi preservada.');
  END assert_origin_is_accepted;

  PROCEDURE test_20_external_origin IS
  BEGIN
    start_test('EXTERNAL valido');
    assert_origin_is_accepted(core_context_pkg.c_origin_external);
    pass;
  END test_20_external_origin;

  PROCEDURE test_21_internal_origin IS
  BEGIN
    start_test('INTERNAL valido');
    assert_origin_is_accepted(core_context_pkg.c_origin_internal);
    pass;
  END test_21_internal_origin;

  PROCEDURE test_22_job_origin IS
  BEGIN
    start_test('JOB valido');
    assert_origin_is_accepted(core_context_pkg.c_origin_job);
    pass;
  END test_22_job_origin;

  PROCEDURE test_23_integration_origin IS
  BEGIN
    start_test('INTEGRATION valido');
    assert_origin_is_accepted(core_context_pkg.c_origin_integration);
    pass;
  END test_23_integration_origin;

  PROCEDURE test_24_invalid_origin IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('origem invalida');
    core_trace_pkg.initialize(c_trace_id);
    BEGIN
      core_context_pkg.initialize('INVALID', core_context_pkg.c_mode_synchronous, NULL, FALSE);
    EXCEPTION
      WHEN core_context_pkg.e_invalid_execution_origin THEN l_raised := TRUE;
    END;
    assert_raises(l_raised, 'Origem invalida deve ser rejeitada.');
    pass;
  END test_24_invalid_origin;

  PROCEDURE test_25_lowercase_origin IS
  BEGIN
    start_test('origem minuscula e normalizada');
    initialize_anonymous('external', core_context_pkg.c_mode_synchronous);
    assert_equals(core_context_pkg.execution_origin, 'EXTERNAL', 'Origem deve ser normalizada.');
    pass;
  END test_25_lowercase_origin;

  PROCEDURE test_26_spaced_origin IS
  BEGIN
    start_test('origem com espacos e normalizada');
    initialize_anonymous('  external  ', core_context_pkg.c_mode_synchronous);
    assert_equals(core_context_pkg.execution_origin, 'EXTERNAL', 'Espacos da origem devem ser removidos.');
    pass;
  END test_26_spaced_origin;

  PROCEDURE assert_mode_is_accepted(
    p_mode IN core_context_pkg.t_execution_mode
  ) IS
  BEGIN
    initialize_anonymous(core_context_pkg.c_origin_external, p_mode);
    assert_equals(core_context_pkg.execution_mode, p_mode, 'Modo valido nao foi preservado.');
  END assert_mode_is_accepted;

  PROCEDURE test_27_synchronous_mode IS
  BEGIN
    start_test('SYNCHRONOUS valido');
    assert_mode_is_accepted(core_context_pkg.c_mode_synchronous);
    pass;
  END test_27_synchronous_mode;

  PROCEDURE test_28_asynchronous_mode IS
  BEGIN
    start_test('ASYNCHRONOUS valido');
    assert_mode_is_accepted(core_context_pkg.c_mode_asynchronous);
    pass;
  END test_28_asynchronous_mode;

  PROCEDURE test_29_batch_mode IS
  BEGIN
    start_test('BATCH valido');
    assert_mode_is_accepted(core_context_pkg.c_mode_batch);
    pass;
  END test_29_batch_mode;

  PROCEDURE test_30_invalid_mode IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('modo invalido');
    core_trace_pkg.initialize(c_trace_id);
    BEGIN
      core_context_pkg.initialize(core_context_pkg.c_origin_external, 'INVALID', NULL, FALSE);
    EXCEPTION
      WHEN core_context_pkg.e_invalid_execution_mode THEN l_raised := TRUE;
    END;
    assert_raises(l_raised, 'Modo invalido deve ser rejeitado.');
    pass;
  END test_30_invalid_mode;

  PROCEDURE test_31_lowercase_mode IS
  BEGIN
    start_test('modo minusculo e normalizado');
    initialize_anonymous(core_context_pkg.c_origin_external, 'batch');
    assert_equals(core_context_pkg.execution_mode, 'BATCH', 'Modo deve ser normalizado.');
    pass;
  END test_31_lowercase_mode;

  PROCEDURE test_32_spaced_mode IS
  BEGIN
    start_test('modo com espacos e normalizado');
    initialize_anonymous(core_context_pkg.c_origin_external, '  batch  ');
    assert_equals(core_context_pkg.execution_mode, 'BATCH', 'Espacos do modo devem ser removidos.');
    pass;
  END test_32_spaced_mode;

  PROCEDURE test_33_authenticated_with_actor IS
  BEGIN
    start_test('TRUE com Actor valido');
    core_trace_pkg.initialize(c_trace_id);
    core_context_pkg.initialize(
      core_context_pkg.c_origin_external,
      core_context_pkg.c_mode_synchronous,
      c_actor_id,
      TRUE
    );
    assert_true(core_context_pkg.is_authenticated, 'Contexto deve estar autenticado.');
    assert_equals(core_context_pkg.actor_public_id, c_actor_id, 'Actor deve ser armazenado.');
    pass;
  END test_33_authenticated_with_actor;

  PROCEDURE test_34_anonymous_without_actor IS
  BEGIN
    start_test('FALSE com Actor NULL');
    initialize_anonymous;
    assert_false(core_context_pkg.is_authenticated, 'Contexto deve ser anonimo.');
    assert_null(core_context_pkg.actor_public_id, 'Actor anonimo deve ser NULL.');
    pass;
  END test_34_anonymous_without_actor;

  PROCEDURE test_35_authenticated_without_actor IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('TRUE com Actor NULL e invalido');
    core_trace_pkg.initialize(c_trace_id);
    BEGIN
      core_context_pkg.initialize(
        core_context_pkg.c_origin_external,
        core_context_pkg.c_mode_synchronous,
        NULL,
        TRUE
      );
    EXCEPTION
      WHEN core_context_pkg.e_invalid_authentication_state THEN l_raised := TRUE;
    END;
    assert_raises(l_raised, 'Autenticacao sem Actor deve falhar.');
    pass;
  END test_35_authenticated_without_actor;

  PROCEDURE test_36_anonymous_with_actor IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('FALSE com Actor e invalido');
    core_trace_pkg.initialize(c_trace_id);
    BEGIN
      core_context_pkg.initialize(
        core_context_pkg.c_origin_external,
        core_context_pkg.c_mode_synchronous,
        c_actor_id,
        FALSE
      );
    EXCEPTION
      WHEN core_context_pkg.e_invalid_authentication_state THEN l_raised := TRUE;
    END;
    assert_raises(l_raised, 'Contexto anonimo com Actor deve falhar.');
    pass;
  END test_36_anonymous_with_actor;

  PROCEDURE test_37_actor_invalid_length IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('TRUE com Actor de tamanho invalido');
    core_trace_pkg.initialize(c_trace_id);
    BEGIN
      core_context_pkg.initialize(
        core_context_pkg.c_origin_external,
        core_context_pkg.c_mode_synchronous,
        'ABCDEF',
        TRUE
      );
    EXCEPTION
      WHEN core_context_pkg.e_invalid_authentication_state THEN l_raised := TRUE;
    END;
    assert_raises(l_raised, 'Actor com tamanho invalido deve falhar.');
    pass;
  END test_37_actor_invalid_length;

  PROCEDURE test_38_actor_invalid_characters IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('TRUE com Actor nao hexadecimal');
    core_trace_pkg.initialize(c_trace_id);
    BEGIN
      core_context_pkg.initialize(
        core_context_pkg.c_origin_external,
        core_context_pkg.c_mode_synchronous,
        'ABCDEF0123456789ABCDEF012345678G',
        TRUE
      );
    EXCEPTION
      WHEN core_context_pkg.e_invalid_authentication_state THEN l_raised := TRUE;
    END;
    assert_raises(l_raised, 'Actor nao hexadecimal deve falhar.');
    pass;
  END test_38_actor_invalid_characters;

  PROCEDURE test_39_lowercase_actor IS
  BEGIN
    start_test('TRUE com Actor minusculo e normalizado');
    core_trace_pkg.initialize(c_trace_id);
    core_context_pkg.initialize(
      core_context_pkg.c_origin_external,
      core_context_pkg.c_mode_synchronous,
      'abcdef0123456789abcdef0123456789',
      TRUE
    );
    assert_equals(
      core_context_pkg.actor_public_id,
      c_actor_id,
      'Actor deve ser normalizado para maiusculas.'
    );
    pass;
  END test_39_lowercase_actor;

  PROCEDURE test_40_clear_removes_attributes IS
  BEGIN
    start_test('clear remove todos os atributos');
    initialize_anonymous;
    core_context_pkg.clear;
    assert_getters_unavailable;
    pass;
  END test_40_clear_removes_attributes;

  PROCEDURE test_41_clear_allows_reinitialize IS
  BEGIN
    start_test('clear permite nova inicializacao');
    initialize_anonymous;
    core_context_pkg.clear;
    core_context_pkg.initialize(
      core_context_pkg.c_origin_job,
      core_context_pkg.c_mode_batch,
      NULL,
      FALSE
    );
    assert_true(core_context_pkg.is_initialized, 'Nova inicializacao deve ser permitida.');
    assert_equals(core_context_pkg.execution_origin, 'JOB', 'Nova origem deve ser publicada.');
    pass;
  END test_41_clear_allows_reinitialize;

  PROCEDURE test_42_clear_multiple_times IS
  BEGIN
    start_test('clear permanece idempotente apos multiplas chamadas');
    initialize_anonymous;
    core_context_pkg.clear;
    core_context_pkg.clear;
    core_context_pkg.clear;
    assert_false(core_context_pkg.is_initialized, 'Multiplos clear devem manter contexto inativo.');
    pass;
  END test_42_clear_multiple_times;

  PROCEDURE test_43_failed_initialize_has_no_partial_state IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('initialize falhando nao deixa estado parcial');
    core_trace_pkg.initialize(c_trace_id);
    BEGIN
      core_context_pkg.initialize(
        'INVALID',
        core_context_pkg.c_mode_synchronous,
        NULL,
        FALSE
      );
    EXCEPTION
      WHEN core_context_pkg.e_invalid_execution_origin THEN l_raised := TRUE;
    END;
    assert_raises(l_raised, 'Falha esperada nao foi levantada.');
    assert_false(core_context_pkg.is_initialized, 'Falha nao pode deixar contexto parcial.');
    pass;
  END test_43_failed_initialize_has_no_partial_state;

  PROCEDURE test_44_failed_initialize_stays_inactive IS
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('apos falha is_initialized continua FALSE');
    core_trace_pkg.initialize(c_trace_id);
    BEGIN
      core_context_pkg.initialize(
        core_context_pkg.c_origin_external,
        'INVALID',
        NULL,
        FALSE
      );
    EXCEPTION
      WHEN core_context_pkg.e_invalid_execution_mode THEN l_raised := TRUE;
    END;
    assert_raises(l_raised, 'Modo invalido deve falhar.');
    assert_false(core_context_pkg.is_initialized, 'Contexto deve permanecer inativo.');
    pass;
  END test_44_failed_initialize_stays_inactive;

  PROCEDURE test_45_getters_fail_after_initialize_error IS
    l_initialization_raised BOOLEAN := FALSE;
  BEGIN
    start_test('apos falha getters continuam indisponiveis');
    core_trace_pkg.initialize(c_trace_id);
    BEGIN
      core_context_pkg.initialize(
        core_context_pkg.c_origin_external,
        core_context_pkg.c_mode_synchronous,
        NULL,
        TRUE
      );
    EXCEPTION
      WHEN core_context_pkg.e_invalid_authentication_state THEN
        l_initialization_raised := TRUE;
    END;
    assert_raises(l_initialization_raised, 'Inicializacao invalida deve falhar.');
    assert_getters_unavailable;
    pass;
  END test_45_getters_fail_after_initialize_error;
BEGIN
  test_01_context_starts_uninitialized;
  test_02_is_initialized_false_initially;
  test_03_initialize_activates_context;
  test_04_initialize_clear_restores_state;
  test_05_clear_is_idempotent;
  test_06_second_initialize_fails;
  test_07_initialize_requires_trace;
  test_08_existing_trace_is_reused;
  test_09_stored_trace_matches_current;
  test_10_context_clear_preserves_trace;
  test_11_trace_id_requires_context;
  test_12_started_at_requires_context;
  test_13_origin_requires_context;
  test_14_mode_requires_context;
  test_15_actor_requires_context;
  test_16_authenticated_requires_context;
  test_17_started_at_is_filled;
  test_18_started_at_is_not_null;
  test_19_started_at_is_stable;
  test_20_external_origin;
  test_21_internal_origin;
  test_22_job_origin;
  test_23_integration_origin;
  test_24_invalid_origin;
  test_25_lowercase_origin;
  test_26_spaced_origin;
  test_27_synchronous_mode;
  test_28_asynchronous_mode;
  test_29_batch_mode;
  test_30_invalid_mode;
  test_31_lowercase_mode;
  test_32_spaced_mode;
  test_33_authenticated_with_actor;
  test_34_anonymous_without_actor;
  test_35_authenticated_without_actor;
  test_36_anonymous_with_actor;
  test_37_actor_invalid_length;
  test_38_actor_invalid_characters;
  test_39_lowercase_actor;
  test_40_clear_removes_attributes;
  test_41_clear_allows_reinitialize;
  test_42_clear_multiple_times;
  test_43_failed_initialize_has_no_partial_state;
  test_44_failed_initialize_stays_inactive;
  test_45_getters_fail_after_initialize_error;

  reset_environment;
  DBMS_OUTPUT.PUT_LINE('SUCCESS - CORE_CONTEXT_PKG (45 testes)');
EXCEPTION
  WHEN OTHERS THEN
    reset_environment;
    DBMS_OUTPUT.PUT_LINE('FAIL - ' || g_current_test);
    RAISE;
END;
/
