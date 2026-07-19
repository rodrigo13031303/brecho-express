CREATE OR REPLACE PACKAGE core_security_context_pkg AS
  SUBTYPE t_actor_type            IS VARCHAR2(20);
  SUBTYPE t_authentication_method IS VARCHAR2(20);

  c_actor_type_anonymous CONSTANT t_actor_type := 'ANONYMOUS';
  c_actor_type_user      CONSTANT t_actor_type := 'USER';
  c_actor_type_system    CONSTANT t_actor_type := 'SYSTEM';

  c_authentication_method_none
    CONSTANT t_authentication_method := 'NONE';

  c_authentication_method_session
    CONSTANT t_authentication_method := 'SESSION';

  c_authentication_method_token
    CONSTANT t_authentication_method := 'TOKEN';

  c_authentication_method_internal
    CONSTANT t_authentication_method := 'INTERNAL';

  e_security_context_already_initialized EXCEPTION;
  e_security_context_not_initialized     EXCEPTION;
  e_execution_context_not_initialized    EXCEPTION;
  e_invalid_actor_type                   EXCEPTION;
  e_invalid_authentication_method        EXCEPTION;
  e_invalid_security_state               EXCEPTION;

  PROCEDURE initialize(
    p_actor_type            IN t_actor_type,
    p_authentication_method IN t_authentication_method
  );

  FUNCTION is_initialized
    RETURN BOOLEAN;

  FUNCTION is_valid_actor_type(
    p_actor_type IN t_actor_type
  ) RETURN BOOLEAN;

  FUNCTION is_valid_authentication_method(
    p_authentication_method IN t_authentication_method
  ) RETURN BOOLEAN;

  FUNCTION actor_type
    RETURN t_actor_type;

  FUNCTION authentication_method
    RETURN t_authentication_method;

  PROCEDURE clear;
END core_security_context_pkg;
/
