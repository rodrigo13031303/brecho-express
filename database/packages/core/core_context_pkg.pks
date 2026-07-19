CREATE OR REPLACE PACKAGE core_context_pkg AS
  SUBTYPE t_started_at       IS TIMESTAMP WITH TIME ZONE;
  SUBTYPE t_execution_origin IS VARCHAR2(20);
  SUBTYPE t_execution_mode   IS VARCHAR2(20);
  SUBTYPE t_actor_public_id  IS CHAR(32);

  c_origin_external    CONSTANT t_execution_origin := 'EXTERNAL';
  c_origin_internal    CONSTANT t_execution_origin := 'INTERNAL';
  c_origin_job         CONSTANT t_execution_origin := 'JOB';
  c_origin_integration CONSTANT t_execution_origin := 'INTEGRATION';

  c_mode_synchronous  CONSTANT t_execution_mode := 'SYNCHRONOUS';
  c_mode_asynchronous CONSTANT t_execution_mode := 'ASYNCHRONOUS';
  c_mode_batch        CONSTANT t_execution_mode := 'BATCH';

  e_context_already_initialized EXCEPTION;
  e_context_not_initialized     EXCEPTION;
  e_trace_not_initialized       EXCEPTION;
  e_invalid_execution_origin    EXCEPTION;
  e_invalid_execution_mode      EXCEPTION;
  e_invalid_authentication_state EXCEPTION;

  FUNCTION is_valid_execution_origin(
    p_execution_origin IN t_execution_origin
  ) RETURN BOOLEAN;

  FUNCTION is_valid_execution_mode(
    p_execution_mode IN t_execution_mode
  ) RETURN BOOLEAN;

  PROCEDURE initialize(
    p_execution_origin IN t_execution_origin,
    p_execution_mode   IN t_execution_mode,
    p_actor_public_id  IN t_actor_public_id,
    p_authenticated    IN BOOLEAN
  );

  FUNCTION is_initialized
    RETURN BOOLEAN;

  FUNCTION trace_id
    RETURN core_trace_pkg.t_trace_id;

  FUNCTION started_at
    RETURN t_started_at;

  FUNCTION execution_origin
    RETURN t_execution_origin;

  FUNCTION execution_mode
    RETURN t_execution_mode;

  FUNCTION actor_public_id
    RETURN t_actor_public_id;

  FUNCTION is_authenticated
    RETURN BOOLEAN;

  PROCEDURE clear;
END core_context_pkg;
/
