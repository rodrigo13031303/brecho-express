CREATE OR REPLACE PACKAGE BODY core_context_pkg AS
  g_initialized      BOOLEAN := FALSE;
  g_trace_id         core_trace_pkg.t_trace_id;
  g_started_at       t_started_at;
  g_execution_origin t_execution_origin;
  g_execution_mode   t_execution_mode;
  g_actor_public_id  t_actor_public_id;
  g_authenticated    BOOLEAN;

  FUNCTION is_valid_public_id(
    p_public_id IN VARCHAR2
  ) RETURN BOOLEAN IS
  BEGIN
    IF p_public_id IS NULL
       OR LENGTH(p_public_id) <> 32 THEN
      RETURN FALSE;
    END IF;

    FOR i IN 1..32 LOOP
      IF SUBSTR(p_public_id, i, 1) NOT IN (
           '0', '1', '2', '3', '4',
           '5', '6', '7', '8', '9',
           'A', 'B', 'C', 'D', 'E', 'F'
         ) THEN
        RETURN FALSE;
      END IF;
    END LOOP;

    RETURN TRUE;
  END is_valid_public_id;

  PROCEDURE assert_initialized IS
  BEGIN
    IF NOT g_initialized THEN
      RAISE e_context_not_initialized;
    END IF;
  END assert_initialized;

  PROCEDURE reset_state IS
  BEGIN
    g_trace_id := NULL;
    g_started_at := NULL;
    g_execution_origin := NULL;
    g_execution_mode := NULL;
    g_actor_public_id := NULL;
    g_authenticated := NULL;
    g_initialized := FALSE;
  END reset_state;

  FUNCTION is_valid_execution_origin(
    p_execution_origin IN t_execution_origin
  ) RETURN BOOLEAN IS
    l_execution_origin t_execution_origin;
  BEGIN
    IF p_execution_origin IS NULL THEN
      RETURN FALSE;
    END IF;

    l_execution_origin := UPPER(TRIM(p_execution_origin));

    RETURN l_execution_origin IN (
             c_origin_external,
             c_origin_internal,
             c_origin_job,
             c_origin_integration
           );
  END is_valid_execution_origin;

  FUNCTION is_valid_execution_mode(
    p_execution_mode IN t_execution_mode
  ) RETURN BOOLEAN IS
    l_execution_mode t_execution_mode;
  BEGIN
    IF p_execution_mode IS NULL THEN
      RETURN FALSE;
    END IF;

    l_execution_mode := UPPER(TRIM(p_execution_mode));

    RETURN l_execution_mode IN (
             c_mode_synchronous,
             c_mode_asynchronous,
             c_mode_batch
           );
  END is_valid_execution_mode;

  PROCEDURE clear IS
  BEGIN
    reset_state;
  END clear;

  PROCEDURE initialize(
    p_execution_origin IN t_execution_origin,
    p_execution_mode   IN t_execution_mode,
    p_actor_public_id  IN t_actor_public_id,
    p_authenticated    IN BOOLEAN
  ) IS
    l_trace_id         core_trace_pkg.t_trace_id;
    l_started_at       t_started_at;
    l_execution_origin t_execution_origin;
    l_execution_mode   t_execution_mode;
    l_actor_public_id  VARCHAR2(32);
  BEGIN
    IF g_initialized THEN
      RAISE e_context_already_initialized;
    END IF;

    reset_state;

    BEGIN
      IF NOT core_trace_pkg.has_trace THEN
        RAISE e_trace_not_initialized;
      END IF;

      l_execution_origin := UPPER(TRIM(p_execution_origin));
      l_execution_mode := UPPER(TRIM(p_execution_mode));
      l_actor_public_id := UPPER(TRIM(p_actor_public_id));

      IF NOT is_valid_execution_origin(l_execution_origin) THEN
        RAISE e_invalid_execution_origin;
      END IF;

      IF NOT is_valid_execution_mode(l_execution_mode) THEN
        RAISE e_invalid_execution_mode;
      END IF;

      IF p_authenticated = TRUE THEN
        IF NOT is_valid_public_id(l_actor_public_id) THEN
          RAISE e_invalid_authentication_state;
        END IF;
      ELSIF p_authenticated = FALSE THEN
        IF l_actor_public_id IS NOT NULL THEN
          RAISE e_invalid_authentication_state;
        END IF;
      ELSE
        RAISE e_invalid_authentication_state;
      END IF;

      l_trace_id := core_trace_pkg.current_trace_id;
      l_started_at := SYSTIMESTAMP;

      g_trace_id := l_trace_id;
      g_started_at := l_started_at;
      g_execution_origin := l_execution_origin;
      g_execution_mode := l_execution_mode;
      g_actor_public_id := l_actor_public_id;
      g_authenticated := p_authenticated;
      g_initialized := TRUE;
    EXCEPTION
      WHEN OTHERS THEN
        reset_state;
        RAISE;
    END;
  END initialize;

  FUNCTION is_initialized
    RETURN BOOLEAN IS
  BEGIN
    RETURN g_initialized;
  END is_initialized;

  FUNCTION trace_id
    RETURN core_trace_pkg.t_trace_id IS
  BEGIN
    assert_initialized;

    RETURN g_trace_id;
  END trace_id;

  FUNCTION started_at
    RETURN t_started_at IS
  BEGIN
    assert_initialized;

    RETURN g_started_at;
  END started_at;

  FUNCTION execution_origin
    RETURN t_execution_origin IS
  BEGIN
    assert_initialized;

    RETURN g_execution_origin;
  END execution_origin;

  FUNCTION execution_mode
    RETURN t_execution_mode IS
  BEGIN
    assert_initialized;

    RETURN g_execution_mode;
  END execution_mode;

  FUNCTION actor_public_id
    RETURN t_actor_public_id IS
  BEGIN
    assert_initialized;

    RETURN g_actor_public_id;
  END actor_public_id;

  FUNCTION is_authenticated
    RETURN BOOLEAN IS
  BEGIN
    assert_initialized;

    RETURN g_authenticated;
  END is_authenticated;
END core_context_pkg;
/
