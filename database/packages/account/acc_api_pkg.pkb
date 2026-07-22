CREATE OR REPLACE PACKAGE BODY acc_api_pkg AS
  ------------------------------------------------------------------------------
  -- Excecoes privadas de contrato
  ------------------------------------------------------------------------------

  e_request_body_required EXCEPTION;
  e_invalid_json          EXCEPTION;
  e_json_object_required  EXCEPTION;
  e_required_field        EXCEPTION;
  e_invalid_field_type    EXCEPTION;
  e_unknown_field         EXCEPTION;

  ------------------------------------------------------------------------------
  -- Constantes privadas de resposta
  ------------------------------------------------------------------------------

  c_status_bad_request CONSTANT PLS_INTEGER := 400;
  c_status_created     CONSTANT PLS_INTEGER := 201;
  c_status_conflict    CONSTANT PLS_INTEGER := 409;
  c_status_unprocessable CONSTANT PLS_INTEGER := 422;
  c_status_internal_error CONSTANT PLS_INTEGER := 500;

  c_code_body_required CONSTANT core_error_pkg.t_error_code :=
    'BEX-REQ-001';
  c_code_invalid_json CONSTANT core_error_pkg.t_error_code :=
    'BEX-REQ-002';
  c_code_object_required CONSTANT core_error_pkg.t_error_code :=
    'BEX-REQ-003';
  c_code_required_field CONSTANT core_error_pkg.t_error_code :=
    'BEX-REQ-004';
  c_code_invalid_field_type CONSTANT core_error_pkg.t_error_code :=
    'BEX-REQ-005';
  c_code_unknown_field CONSTANT core_error_pkg.t_error_code :=
    'BEX-REQ-006';
  c_code_invalid_email CONSTANT core_error_pkg.t_error_code :=
    'BEX-ACC-003';
  c_code_email_already_used CONSTANT core_error_pkg.t_error_code :=
    'BEX-ACC-004';
  c_code_invalid_password CONSTANT core_error_pkg.t_error_code :=
    'BEX-ACC-005';
  c_code_internal_error CONSTANT core_error_pkg.t_error_code :=
    'BEX-SYS-001';

  ------------------------------------------------------------------------------
  -- Helpers privados de CLOB
  ------------------------------------------------------------------------------

  PROCEDURE free_temporary_clob(
    io_value IN OUT NOCOPY CLOB
  ) IS
  BEGIN
    IF io_value IS NOT NULL
       AND DBMS_LOB.ISTEMPORARY(io_value) = 1 THEN
      DBMS_LOB.FREETEMPORARY(io_value);
    END IF;

    io_value := NULL;
  END free_temporary_clob;

  FUNCTION is_blank_body(
    p_request_body IN CLOB
  ) RETURN BOOLEAN IS
    l_length PLS_INTEGER;
    l_offset PLS_INTEGER := 1;
    l_chunk  VARCHAR2(32767);
  BEGIN
    IF p_request_body IS NULL THEN
      RETURN TRUE;
    END IF;

    l_length := DBMS_LOB.GETLENGTH(p_request_body);

    IF l_length = 0 THEN
      RETURN TRUE;
    END IF;

    WHILE l_offset <= l_length LOOP
      l_chunk := DBMS_LOB.SUBSTR(p_request_body, 32767, l_offset);

      IF REGEXP_REPLACE(l_chunk, '[[:space:]]', '') IS NOT NULL THEN
        RETURN FALSE;
      END IF;

      l_offset := l_offset + 32767;
    END LOOP;

    RETURN TRUE;
  END is_blank_body;

  ------------------------------------------------------------------------------
  -- Helpers privados de parsing
  ------------------------------------------------------------------------------

  PROCEDURE assert_known_fields(
    p_object IN JSON_OBJECT_T
  ) IS
    l_keys JSON_KEY_LIST;
  BEGIN
    l_keys := p_object.get_keys;

    FOR i IN 1..l_keys.COUNT LOOP
      IF l_keys(i) NOT IN ('email', 'password') THEN
        RAISE e_unknown_field;
      END IF;
    END LOOP;
  END assert_known_fields;

  FUNCTION get_required_string(
    p_object         IN JSON_OBJECT_T,
    p_attribute_name IN VARCHAR2
  ) RETURN VARCHAR2 IS
    l_element JSON_ELEMENT_T;
  BEGIN
    IF NOT p_object.has(p_attribute_name) THEN
      RAISE e_required_field;
    END IF;

    l_element := p_object.get(p_attribute_name);

    IF l_element IS NULL OR l_element.is_null THEN
      RAISE e_required_field;
    END IF;

    IF NOT l_element.is_string THEN
      RAISE e_invalid_field_type;
    END IF;

    RETURN p_object.get_string(p_attribute_name);
  END get_required_string;

  PROCEDURE parse_create_request(
    p_request_body IN  CLOB,
    o_email        OUT VARCHAR2,
    o_password     OUT VARCHAR2
  ) IS
    l_element JSON_ELEMENT_T;
    l_object  JSON_OBJECT_T;
  BEGIN
    IF is_blank_body(p_request_body) THEN
      RAISE e_request_body_required;
    END IF;

    BEGIN
      l_element := JSON_ELEMENT_T.parse(p_request_body);
    EXCEPTION
      WHEN OTHERS THEN
        RAISE e_invalid_json;
    END;

    IF l_element IS NULL OR NOT l_element.is_object THEN
      RAISE e_json_object_required;
    END IF;

    l_object := TREAT(l_element AS JSON_OBJECT_T);
    assert_known_fields(l_object);

    o_email := get_required_string(l_object, 'email');
    o_password := get_required_string(l_object, 'password');
  END parse_create_request;

  ------------------------------------------------------------------------------
  -- Helpers privados de payload
  ------------------------------------------------------------------------------

  FUNCTION account_to_json(
    p_account IN BEX_ACCOUNT%ROWTYPE
  ) RETURN JSON_OBJECT_T IS
    l_data JSON_OBJECT_T := JSON_OBJECT_T();
  BEGIN
    core_json_pkg.put_string(
      l_data,
      'publicId',
      TRIM(p_account.ACC_PUBLIC_ID)
    );
    core_json_pkg.put_string(l_data, 'email', p_account.ACC_EMAIL);

    IF p_account.ACC_EMAIL_VERIFIED_AT IS NULL THEN
      core_json_pkg.put_null(l_data, 'emailVerifiedAt');
    ELSE
      core_json_pkg.put_string(
        l_data,
        'emailVerifiedAt',
        core_json_pkg.format_timestamp(p_account.ACC_EMAIL_VERIFIED_AT)
      );
    END IF;

    core_json_pkg.put_string(l_data, 'status', p_account.ACC_STATUS);
    core_json_pkg.put_string(
      l_data,
      'createdAt',
      core_json_pkg.format_timestamp(p_account.ACC_CREATED_AT)
    );
    core_json_pkg.put_string(
      l_data,
      'updatedAt',
      core_json_pkg.format_timestamp(p_account.ACC_UPDATED_AT)
    );

    RETURN l_data;
  END account_to_json;

  ------------------------------------------------------------------------------
  -- Helpers privados de erro
  ------------------------------------------------------------------------------

  PROCEDURE build_known_error_response(
    p_status_code      IN  PLS_INTEGER,
    p_code             IN  core_error_pkg.t_error_code,
    p_category         IN  core_error_pkg.t_category,
    p_external_message IN  core_error_pkg.t_external_message,
    p_severity         IN  core_error_pkg.t_severity,
    p_should_log       IN  BOOLEAN,
    o_status_code      OUT PLS_INTEGER,
    o_response_body    OUT NOCOPY CLOB
  ) IS
    l_public_error core_error_pkg.t_public_error;
    l_error_policy core_error_pkg.t_error_policy;
  BEGIN
    core_error_pkg.build_known_error(
      p_code             => p_code,
      p_category         => p_category,
      p_external_message => p_external_message,
      p_severity         => p_severity,
      p_retryable        => FALSE,
      p_should_log       => p_should_log,
      o_public_error     => l_public_error,
      o_error_policy     => l_error_policy
    );

    o_response_body := core_response_pkg.build_error(l_public_error);
    o_status_code := p_status_code;
  EXCEPTION
    WHEN OTHERS THEN
      o_status_code := c_status_internal_error;
      o_response_body := NULL;
  END build_known_error_response;

  PROCEDURE build_technical_error_response(
    o_status_code   OUT PLS_INTEGER,
    o_response_body OUT NOCOPY CLOB
  ) IS
    l_public_error core_error_pkg.t_public_error;
    l_error_policy core_error_pkg.t_error_policy;
  BEGIN
    core_error_pkg.build_technical_error(
      p_code             => c_code_internal_error,
      p_external_message => 'Nao foi possivel concluir a requisicao.',
      p_retryable        => FALSE,
      o_public_error     => l_public_error,
      o_error_policy     => l_error_policy
    );

    o_response_body := core_response_pkg.build_error(l_public_error);
    o_status_code := c_status_internal_error;
  END build_technical_error_response;

  ------------------------------------------------------------------------------
  -- Operacoes publicas
  ------------------------------------------------------------------------------

  PROCEDURE create_account(
    p_request_body  IN  CLOB,
    o_status_code   OUT PLS_INTEGER,
    o_response_body OUT NOCOPY CLOB
  ) IS
    l_email         VARCHAR2(32767);
    l_password      VARCHAR2(32767);
    l_account       BEX_ACCOUNT%ROWTYPE;
    l_data          JSON_OBJECT_T;
    l_success_body  CLOB;
  BEGIN
    o_status_code := c_status_internal_error;
    o_response_body := NULL;

    parse_create_request(
      p_request_body => p_request_body,
      o_email        => l_email,
      o_password     => l_password
    );

    l_account := acc_service_pkg.create_account(
      p_email      => l_email,
      p_password   => l_password,
      p_created_by => NULL
    );

    l_data := account_to_json(l_account);
    l_success_body := core_response_pkg.build_success(l_data);

    COMMIT;

    o_response_body := l_success_body;
    o_status_code := c_status_created;
  EXCEPTION
    WHEN e_request_body_required THEN
      ROLLBACK;
      free_temporary_clob(l_success_body);
      build_known_error_response(
        c_status_bad_request,
        c_code_body_required,
        core_error_pkg.c_category_validation,
        'O corpo da requisicao e obrigatorio.',
        core_error_pkg.c_severity_warn,
        FALSE,
        o_status_code,
        o_response_body
      );
    WHEN e_invalid_json THEN
      ROLLBACK;
      free_temporary_clob(l_success_body);
      build_known_error_response(
        c_status_bad_request,
        c_code_invalid_json,
        core_error_pkg.c_category_validation,
        'O corpo da requisicao nao contem JSON valido.',
        core_error_pkg.c_severity_warn,
        FALSE,
        o_status_code,
        o_response_body
      );
    WHEN e_json_object_required THEN
      ROLLBACK;
      free_temporary_clob(l_success_body);
      build_known_error_response(
        c_status_bad_request,
        c_code_object_required,
        core_error_pkg.c_category_validation,
        'O corpo da requisicao deve ser um objeto JSON.',
        core_error_pkg.c_severity_warn,
        FALSE,
        o_status_code,
        o_response_body
      );
    WHEN e_required_field THEN
      ROLLBACK;
      free_temporary_clob(l_success_body);
      build_known_error_response(
        c_status_bad_request,
        c_code_required_field,
        core_error_pkg.c_category_validation,
        'Um campo obrigatorio nao foi informado.',
        core_error_pkg.c_severity_warn,
        FALSE,
        o_status_code,
        o_response_body
      );
    WHEN e_invalid_field_type THEN
      ROLLBACK;
      free_temporary_clob(l_success_body);
      build_known_error_response(
        c_status_bad_request,
        c_code_invalid_field_type,
        core_error_pkg.c_category_validation,
        'Um campo possui tipo invalido.',
        core_error_pkg.c_severity_warn,
        FALSE,
        o_status_code,
        o_response_body
      );
    WHEN e_unknown_field THEN
      ROLLBACK;
      free_temporary_clob(l_success_body);
      build_known_error_response(
        c_status_bad_request,
        c_code_unknown_field,
        core_error_pkg.c_category_validation,
        'A requisicao contem campo desconhecido.',
        core_error_pkg.c_severity_warn,
        FALSE,
        o_status_code,
        o_response_body
      );
    WHEN acc_rule_pkg.e_invalid_email THEN
      ROLLBACK;
      free_temporary_clob(l_success_body);
      build_known_error_response(
        c_status_unprocessable,
        c_code_invalid_email,
        core_error_pkg.c_category_validation,
        'O email informado e invalido.',
        core_error_pkg.c_severity_warn,
        FALSE,
        o_status_code,
        o_response_body
      );
    WHEN acc_rule_pkg.e_invalid_password THEN
      ROLLBACK;
      free_temporary_clob(l_success_body);
      build_known_error_response(
        c_status_unprocessable,
        c_code_invalid_password,
        core_error_pkg.c_category_validation,
        'A senha informada e invalida.',
        core_error_pkg.c_severity_warn,
        FALSE,
        o_status_code,
        o_response_body
      );
    WHEN acc_rule_pkg.e_email_already_used THEN
      ROLLBACK;
      free_temporary_clob(l_success_body);
      build_known_error_response(
        c_status_conflict,
        c_code_email_already_used,
        core_error_pkg.c_category_conflict,
        'O email informado ja esta em uso.',
        core_error_pkg.c_severity_warn,
        FALSE,
        o_status_code,
        o_response_body
      );
    WHEN OTHERS THEN
      ROLLBACK;
      free_temporary_clob(l_success_body);
      o_status_code := c_status_internal_error;
      o_response_body := NULL;

      BEGIN
        build_technical_error_response(
          o_status_code,
          o_response_body
        );
      EXCEPTION
        WHEN OTHERS THEN
          o_status_code := c_status_internal_error;
          o_response_body := NULL;
      END;
  END create_account;
END acc_api_pkg;
/
