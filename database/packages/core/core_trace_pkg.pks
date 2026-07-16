CREATE OR REPLACE PACKAGE core_trace_pkg AS
  SUBTYPE t_trace_id IS VARCHAR2(32);

  e_invalid_trace_id      EXCEPTION;
  e_trace_not_initialized EXCEPTION;

  PROCEDURE initialize;

  PROCEDURE initialize(
    p_trace_id IN t_trace_id
  );

  FUNCTION current_trace_id
    RETURN t_trace_id;

  FUNCTION has_trace
    RETURN BOOLEAN;

  PROCEDURE clear;
END core_trace_pkg;
/
