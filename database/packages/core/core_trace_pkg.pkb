CREATE OR REPLACE PACKAGE BODY core_trace_pkg AS
  g_trace_id t_trace_id;

  FUNCTION is_valid_trace_id(
    p_trace_id IN t_trace_id
  ) RETURN BOOLEAN IS
  BEGIN
    RETURN p_trace_id IS NOT NULL
       AND LENGTH(p_trace_id) = 32
       AND REGEXP_LIKE(p_trace_id, '^[0-9A-F]{32}$', 'i');
  END is_valid_trace_id;

  PROCEDURE clear IS
  BEGIN
    g_trace_id := NULL;
  END clear;

  PROCEDURE initialize IS
    l_trace_id t_trace_id;
  BEGIN
    clear;

    l_trace_id := RAWTOHEX(SYS_GUID());

    IF NOT is_valid_trace_id(l_trace_id) THEN
      RAISE e_invalid_trace_id;
    END IF;

    g_trace_id := UPPER(l_trace_id);
  END initialize;

  PROCEDURE initialize(
    p_trace_id IN t_trace_id
  ) IS
  BEGIN
    clear;

    IF NOT is_valid_trace_id(p_trace_id) THEN
      RAISE e_invalid_trace_id;
    END IF;

    g_trace_id := UPPER(p_trace_id);
  END initialize;

  FUNCTION current_trace_id
    RETURN t_trace_id IS
  BEGIN
    IF NOT has_trace THEN
      RAISE e_trace_not_initialized;
    END IF;

    RETURN g_trace_id;
  END current_trace_id;

  FUNCTION has_trace
    RETURN BOOLEAN IS
  BEGIN
    RETURN is_valid_trace_id(g_trace_id);
  END has_trace;
END core_trace_pkg;
/
