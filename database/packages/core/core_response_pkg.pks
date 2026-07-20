CREATE OR REPLACE PACKAGE core_response_pkg AS
  SUBTYPE t_response_body IS CLOB;

  e_execution_context_not_initialized EXCEPTION;
  e_response_data_required             EXCEPTION;
  e_invalid_public_error               EXCEPTION;
  e_error_trace_mismatch               EXCEPTION;

  FUNCTION build_success(
    p_data IN JSON_ELEMENT_T
  ) RETURN t_response_body;

  FUNCTION empty_success
    RETURN t_response_body;

  FUNCTION build_error(
    p_error IN core_error_pkg.t_public_error
  ) RETURN t_response_body;
END core_response_pkg;
/
