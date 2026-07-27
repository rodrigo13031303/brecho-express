CREATE OR REPLACE PACKAGE BODY ord_runtime_pkg AS
  c_bearer_pattern CONSTANT VARCHAR2(100) :=
    '^Bearer[[:space:]]+[0-9a-fA-F]{64}$';

  PROCEDURE clear_request_context IS
  BEGIN
    core_security_context_pkg.clear;
    core_context_pkg.clear;
    core_trace_pkg.clear;
  END clear_request_context;

  PROCEDURE begin_anonymous_request IS
  BEGIN
    clear_request_context;
    core_trace_pkg.initialize;
    core_context_pkg.initialize(
      p_execution_origin => core_context_pkg.c_origin_external,
      p_execution_mode   => core_context_pkg.c_mode_synchronous,
      p_actor_public_id  => NULL,
      p_authenticated    => FALSE
    );
    core_security_context_pkg.initialize(
      p_actor_type           =>
        core_security_context_pkg.c_actor_type_anonymous,
      p_authentication_method =>
        core_security_context_pkg.c_authentication_method_none
    );
  EXCEPTION
    WHEN OTHERS THEN
      clear_request_context;
      RAISE;
  END begin_anonymous_request;

  PROCEDURE begin_authenticated_request(
    p_authorization      IN VARCHAR2,
    o_authenticated      OUT BOOLEAN,
    o_account_id         OUT NUMBER,
    o_session_public_id  OUT VARCHAR2,
    o_status_code        OUT PLS_INTEGER,
    o_response_body      OUT NOCOPY CLOB
  ) IS
    l_authorization VARCHAR2(4000);
    l_token         VARCHAR2(64);
    l_session       BEX_SESSION%ROWTYPE;
    l_account       BEX_ACCOUNT%ROWTYPE;

    PROCEDURE initialize_anonymous_context IS
    BEGIN
      core_context_pkg.initialize(
        p_execution_origin => core_context_pkg.c_origin_external,
        p_execution_mode   => core_context_pkg.c_mode_synchronous,
        p_actor_public_id  => NULL,
        p_authenticated    => FALSE
      );
      core_security_context_pkg.initialize(
        p_actor_type =>
          core_security_context_pkg.c_actor_type_anonymous,
        p_authentication_method =>
          core_security_context_pkg.c_authentication_method_none
      );
    END initialize_anonymous_context;

    PROCEDURE reject_authentication IS
    BEGIN
      ROLLBACK;
      initialize_anonymous_context;
      o_status_code := 401;
      o_response_body := core_response_pkg.build_known_error(
        p_code             => 'BEX-AUTH-002',
        p_category         => core_error_pkg.c_category_authentication,
        p_external_message => 'A sessao informada nao e valida.'
      );
    END reject_authentication;
  BEGIN
    o_authenticated := FALSE;
    o_account_id := NULL;
    o_session_public_id := NULL;
    o_status_code := NULL;
    o_response_body := NULL;

    clear_request_context;
    core_trace_pkg.initialize;
    l_authorization := TRIM(p_authorization);

    IF l_authorization IS NULL
       OR NOT REGEXP_LIKE(l_authorization, c_bearer_pattern, 'i') THEN
      reject_authentication;
      RETURN;
    END IF;

    l_token := REGEXP_SUBSTR(
      l_authorization,
      '[0-9a-fA-F]{64}$'
    );
    l_session := acc_session_api_pkg.validate_session(l_token);
    l_account := acc_repository_pkg.get_by_id(l_session.ACC_ID);

    IF l_account.ACC_ID IS NULL
       OR NOT acc_rule_pkg.is_active(l_account.ACC_STATUS) THEN
      reject_authentication;
      RETURN;
    END IF;

    core_context_pkg.initialize(
      p_execution_origin => core_context_pkg.c_origin_external,
      p_execution_mode   => core_context_pkg.c_mode_synchronous,
      p_actor_public_id  => TRIM(l_account.ACC_PUBLIC_ID),
      p_authenticated    => TRUE
    );
    core_security_context_pkg.initialize(
      p_actor_type =>
        core_security_context_pkg.c_actor_type_user,
      p_authentication_method =>
        core_security_context_pkg.c_authentication_method_session
    );

    o_account_id := l_account.ACC_ID;
    o_session_public_id := TRIM(l_session.SESSION_PUBLIC_ID);
    o_authenticated := TRUE;
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE BETWEEN acc_session_pkg.c_err_session_expired
                         AND acc_session_pkg.c_err_invalid_token THEN
        reject_authentication;
      ELSE
        ROLLBACK;
        IF core_security_context_pkg.is_initialized THEN
          core_security_context_pkg.clear;
        END IF;
        IF core_context_pkg.is_initialized THEN
          core_context_pkg.clear;
        END IF;
        initialize_anonymous_context;
        o_status_code := 500;
        o_response_body := core_response_pkg.build_technical_error;
      END IF;
  END begin_authenticated_request;

  PROCEDURE write_json_response(
    p_body IN CLOB
  ) IS
    l_offset PLS_INTEGER := 1;
    l_length PLS_INTEGER;
  BEGIN
    IF p_body IS NULL THEN
      RETURN;
    END IF;

    l_length := DBMS_LOB.GETLENGTH(p_body);
    OWA_UTIL.MIME_HEADER('application/json', FALSE, 'UTF-8');
    OWA_UTIL.HTTP_HEADER_CLOSE;

    WHILE l_offset <= l_length LOOP
      HTP.PRN(DBMS_LOB.SUBSTR(p_body, 32767, l_offset));
      l_offset := l_offset + 32767;
    END LOOP;
  END write_json_response;
END ord_runtime_pkg;
/
