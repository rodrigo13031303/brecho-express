CREATE OR REPLACE PACKAGE BODY core_response_pkg AS
  PROCEDURE assert_execution_context_initialized IS
  BEGIN
    IF NOT core_context_pkg.is_initialized THEN
      RAISE e_execution_context_not_initialized;
    END IF;
  END assert_execution_context_initialized;

  PROCEDURE assert_valid_public_error(
    p_error IN core_error_pkg.t_public_error
  ) IS
    l_valid_code     BOOLEAN;
    l_valid_category BOOLEAN;
  BEGIN
    IF p_error.code IS NULL
       OR TRIM(p_error.code) IS NULL
       OR p_error.category IS NULL
       OR TRIM(p_error.category) IS NULL
       OR p_error.external_message IS NULL
       OR TRIM(p_error.external_message) IS NULL
       OR p_error.retryable IS NULL
       OR p_error.trace_id IS NULL THEN
      RAISE e_invalid_public_error;
    END IF;

    l_valid_code := core_error_pkg.is_valid_code(p_error.code);
    l_valid_category := core_error_pkg.is_valid_category(p_error.category);

    IF l_valid_code IS NULL
       OR NOT l_valid_code
       OR l_valid_category IS NULL
       OR NOT l_valid_category THEN
      RAISE e_invalid_public_error;
    END IF;
  END assert_valid_public_error;

  FUNCTION clone_json_element(
    p_element IN JSON_ELEMENT_T
  ) RETURN JSON_ELEMENT_T IS
    l_array JSON_ARRAY_T;
  BEGIN
    IF p_element.is_object THEN
      RETURN TREAT(p_element AS JSON_OBJECT_T).clone;
    ELSIF p_element.is_array THEN
      l_array := TREAT(p_element AS JSON_ARRAY_T);
      RETURN l_array.clone;
    END IF;

    RETURN p_element;
  END clone_json_element;

  FUNCTION build_base_envelope(
    p_success  IN BOOLEAN,
    p_trace_id IN VARCHAR2
  ) RETURN JSON_OBJECT_T IS
    l_envelope JSON_OBJECT_T := JSON_OBJECT_T();
  BEGIN
    core_json_pkg.put_boolean(l_envelope, 'success', p_success);
    core_json_pkg.put_string(l_envelope, 'traceId', p_trace_id);

    RETURN l_envelope;
  END build_base_envelope;

  FUNCTION build_success(
    p_data IN JSON_ELEMENT_T
  ) RETURN t_response_body IS
    l_trace_id VARCHAR2(32);
    l_data     JSON_ELEMENT_T;
    l_envelope JSON_OBJECT_T;
  BEGIN
    assert_execution_context_initialized;

    IF p_data IS NULL THEN
      RAISE e_response_data_required;
    END IF;

    l_trace_id := core_context_pkg.trace_id();
    l_data := clone_json_element(p_data);
    l_envelope := build_base_envelope(TRUE, l_trace_id);

    core_json_pkg.put_element(l_envelope, 'data', l_data);

    RETURN core_json_pkg.serialize(l_envelope);
  END build_success;

  FUNCTION empty_success
    RETURN t_response_body IS
    l_trace_id VARCHAR2(32);
    l_envelope JSON_OBJECT_T;
  BEGIN
    assert_execution_context_initialized;

    l_trace_id := core_context_pkg.trace_id();
    l_envelope := build_base_envelope(TRUE, l_trace_id);

    RETURN core_json_pkg.serialize(l_envelope);
  END empty_success;

  FUNCTION build_error(
    p_error IN core_error_pkg.t_public_error
  ) RETURN t_response_body IS
    l_trace_id VARCHAR2(32);
    l_error    JSON_OBJECT_T;
    l_envelope JSON_OBJECT_T;
  BEGIN
    assert_execution_context_initialized;

    assert_valid_public_error(p_error);
    l_trace_id := core_context_pkg.trace_id();

    IF p_error.trace_id <> l_trace_id THEN
      RAISE e_error_trace_mismatch;
    END IF;

    l_error := JSON_OBJECT_T();
    core_json_pkg.put_string(l_error, 'code', p_error.code);
    core_json_pkg.put_string(l_error, 'category', p_error.category);
    core_json_pkg.put_string(
      l_error,
      'message',
      p_error.external_message
    );
    core_json_pkg.put_boolean(l_error, 'retryable', p_error.retryable);

    l_envelope := build_base_envelope(FALSE, l_trace_id);
    core_json_pkg.put_element(l_envelope, 'error', l_error);

    RETURN core_json_pkg.serialize(l_envelope);
  END build_error;
END core_response_pkg;
/
