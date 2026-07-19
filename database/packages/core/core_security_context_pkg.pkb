CREATE OR REPLACE PACKAGE BODY core_security_context_pkg AS
  g_initialized           BOOLEAN := FALSE;
  g_actor_type            t_actor_type;
  g_authentication_method t_authentication_method;

  PROCEDURE ensure_initialized IS
  BEGIN
    IF NOT g_initialized THEN
      RAISE e_security_context_not_initialized;
    END IF;
  END ensure_initialized;

  PROCEDURE validate_security_state(
    p_actor_type            IN t_actor_type,
    p_authentication_method IN t_authentication_method,
    p_authenticated         IN BOOLEAN,
    p_actor_public_id       IN core_context_pkg.t_actor_public_id
  ) IS
  BEGIN
    IF p_actor_type = c_actor_type_anonymous THEN
      IF p_authentication_method <> c_authentication_method_none
         OR p_authenticated IS NULL
         OR p_authenticated = TRUE
         OR p_actor_public_id IS NOT NULL THEN
        RAISE e_invalid_security_state;
      END IF;
    ELSIF p_actor_type = c_actor_type_user THEN
      IF p_authentication_method NOT IN (
           c_authentication_method_session,
           c_authentication_method_token
         )
         OR p_authenticated IS NULL
         OR p_authenticated = FALSE
         OR p_actor_public_id IS NULL THEN
        RAISE e_invalid_security_state;
      END IF;
    ELSIF p_actor_type = c_actor_type_system THEN
      IF p_authentication_method <> c_authentication_method_internal
         OR p_authenticated IS NULL
         OR p_authenticated = TRUE
         OR p_actor_public_id IS NOT NULL THEN
        RAISE e_invalid_security_state;
      END IF;
    ELSE
      RAISE e_invalid_security_state;
    END IF;
  END validate_security_state;

  FUNCTION is_valid_actor_type(
    p_actor_type IN t_actor_type
  ) RETURN BOOLEAN IS
    l_actor_type t_actor_type;
  BEGIN
    IF p_actor_type IS NULL THEN
      RETURN FALSE;
    END IF;

    l_actor_type := UPPER(TRIM(p_actor_type));

    RETURN l_actor_type IN (
             c_actor_type_anonymous,
             c_actor_type_user,
             c_actor_type_system
           );
  END is_valid_actor_type;

  FUNCTION is_valid_authentication_method(
    p_authentication_method IN t_authentication_method
  ) RETURN BOOLEAN IS
    l_authentication_method t_authentication_method;
  BEGIN
    IF p_authentication_method IS NULL THEN
      RETURN FALSE;
    END IF;

    l_authentication_method := UPPER(TRIM(p_authentication_method));

    RETURN l_authentication_method IN (
             c_authentication_method_none,
             c_authentication_method_session,
             c_authentication_method_token,
             c_authentication_method_internal
           );
  END is_valid_authentication_method;

  PROCEDURE initialize(
    p_actor_type            IN t_actor_type,
    p_authentication_method IN t_authentication_method
  ) IS
    l_actor_type            t_actor_type;
    l_authentication_method t_authentication_method;
    l_authenticated         BOOLEAN;
    l_actor_public_id       core_context_pkg.t_actor_public_id;
  BEGIN
    IF g_initialized THEN
      RAISE e_security_context_already_initialized;
    END IF;

    IF NOT core_context_pkg.is_initialized THEN
      RAISE e_execution_context_not_initialized;
    END IF;

    l_authenticated := core_context_pkg.is_authenticated;
    l_actor_public_id := core_context_pkg.actor_public_id;

    l_actor_type := UPPER(TRIM(p_actor_type));
    l_authentication_method := UPPER(TRIM(p_authentication_method));

    IF NOT is_valid_actor_type(l_actor_type) THEN
      RAISE e_invalid_actor_type;
    END IF;

    IF NOT is_valid_authentication_method(l_authentication_method) THEN
      RAISE e_invalid_authentication_method;
    END IF;

    validate_security_state(
      p_actor_type            => l_actor_type,
      p_authentication_method => l_authentication_method,
      p_authenticated         => l_authenticated,
      p_actor_public_id       => l_actor_public_id
    );

    g_actor_type := l_actor_type;
    g_authentication_method := l_authentication_method;
    g_initialized := TRUE;
  END initialize;

  FUNCTION is_initialized
    RETURN BOOLEAN IS
  BEGIN
    RETURN g_initialized;
  END is_initialized;

  FUNCTION actor_type
    RETURN t_actor_type IS
  BEGIN
    ensure_initialized;

    RETURN g_actor_type;
  END actor_type;

  FUNCTION authentication_method
    RETURN t_authentication_method IS
  BEGIN
    ensure_initialized;

    RETURN g_authentication_method;
  END authentication_method;

  PROCEDURE clear IS
  BEGIN
    g_actor_type := NULL;
    g_authentication_method := NULL;
    g_initialized := FALSE;
  END clear;
END core_security_context_pkg;
/
