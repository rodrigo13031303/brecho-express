CREATE OR REPLACE PACKAGE BODY pfl_api_pkg AS
  ------------------------------------------------------------------------------
  -- Excecoes privadas de contrato
  ------------------------------------------------------------------------------

  e_request_body_required EXCEPTION;
  e_public_id_required    EXCEPTION;
  e_actor_required        EXCEPTION;
  e_invalid_json          EXCEPTION;
  e_json_object_required  EXCEPTION;
  e_required_field        EXCEPTION;
  e_invalid_field_type    EXCEPTION;
  e_invalid_date_format   EXCEPTION;
  e_unknown_field         EXCEPTION;

  TYPE t_profile_patch IS RECORD (
    display_name_present  BOOLEAN,
    display_name          VARCHAR2(32767),
    full_name_present     BOOLEAN,
    full_name             VARCHAR2(32767),
    birth_date_present    BOOLEAN,
    birth_date            DATE,
    bio_present           BOOLEAN,
    bio                   VARCHAR2(32767),
    avatar_url_present    BOOLEAN,
    avatar_url            VARCHAR2(32767),
    locale_code_present   BOOLEAN,
    locale_code           VARCHAR2(32767),
    timezone_name_present BOOLEAN,
    timezone_name         VARCHAR2(32767)
  );

  ------------------------------------------------------------------------------
  -- Constantes privadas de resposta
  ------------------------------------------------------------------------------

  c_status_ok            CONSTANT PLS_INTEGER := 200;
  c_status_created       CONSTANT PLS_INTEGER := 201;
  c_status_bad_request   CONSTANT PLS_INTEGER := 400;
  c_status_not_found     CONSTANT PLS_INTEGER := 404;
  c_status_conflict      CONSTANT PLS_INTEGER := 409;
  c_status_unprocessable CONSTANT PLS_INTEGER := 422;
  c_status_internal_error CONSTANT PLS_INTEGER := 500;

  c_code_body_required CONSTANT core_error_pkg.t_error_code :=
    'BEX-REQ-001';
  c_code_invalid_json CONSTANT core_error_pkg.t_error_code :=
    'BEX-REQ-002';
  c_code_object_required CONSTANT core_error_pkg.t_error_code :=
    'BEX-REQ-003';
  c_code_required_value CONSTANT core_error_pkg.t_error_code :=
    'BEX-REQ-004';
  c_code_invalid_field_type CONSTANT core_error_pkg.t_error_code :=
    'BEX-REQ-005';
  c_code_unknown_field CONSTANT core_error_pkg.t_error_code :=
    'BEX-REQ-006';
  c_code_invalid_date_format CONSTANT core_error_pkg.t_error_code :=
    'BEX-REQ-007';

  c_code_account_not_found CONSTANT core_error_pkg.t_error_code :=
    'BEX-PRF-001';
  c_code_profile_not_found CONSTANT core_error_pkg.t_error_code :=
    'BEX-PRF-002';
  c_code_account_without_profile CONSTANT core_error_pkg.t_error_code :=
    'BEX-PRF-003';
  c_code_account_already_has_profile CONSTANT core_error_pkg.t_error_code :=
    'BEX-PRF-004';
  c_code_invalid_display_name CONSTANT core_error_pkg.t_error_code :=
    'BEX-PRF-005';
  c_code_invalid_full_name CONSTANT core_error_pkg.t_error_code :=
    'BEX-PRF-006';
  c_code_invalid_birth_date CONSTANT core_error_pkg.t_error_code :=
    'BEX-PRF-007';
  c_code_invalid_locale_code CONSTANT core_error_pkg.t_error_code :=
    'BEX-PRF-008';
  c_code_invalid_timezone_name CONSTANT core_error_pkg.t_error_code :=
    'BEX-PRF-009';
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

  PROCEDURE assert_public_id(
    p_public_id IN VARCHAR2
  ) IS
  BEGIN
    IF TRIM(p_public_id) IS NULL THEN
      RAISE e_public_id_required;
    END IF;
  END assert_public_id;

  PROCEDURE assert_actor(
    p_actor_id IN NUMBER
  ) IS
  BEGIN
    IF p_actor_id IS NULL OR p_actor_id <= 0 THEN
      RAISE e_actor_required;
    END IF;
  END assert_actor;

  PROCEDURE assert_known_fields(
    p_object IN JSON_OBJECT_T
  ) IS
    l_keys JSON_KEY_LIST;
  BEGIN
    l_keys := p_object.get_keys;

    FOR i IN 1..l_keys.COUNT LOOP
      IF l_keys(i) NOT IN (
           'displayName',
           'fullName',
           'birthDate',
           'bio',
           'avatarUrl',
           'localeCode',
           'timezoneName'
         ) THEN
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

  FUNCTION get_optional_string(
    p_object         IN JSON_OBJECT_T,
    p_attribute_name IN VARCHAR2
  ) RETURN VARCHAR2 IS
    l_element JSON_ELEMENT_T;
  BEGIN
    IF NOT p_object.has(p_attribute_name) THEN
      RETURN NULL;
    END IF;

    l_element := p_object.get(p_attribute_name);

    IF l_element IS NULL OR l_element.is_null THEN
      RETURN NULL;
    END IF;

    IF NOT l_element.is_string THEN
      RAISE e_invalid_field_type;
    END IF;

    RETURN p_object.get_string(p_attribute_name);
  END get_optional_string;

  FUNCTION get_optional_date(
    p_object         IN JSON_OBJECT_T,
    p_attribute_name IN VARCHAR2
  ) RETURN DATE IS
    l_value VARCHAR2(32767);
  BEGIN
    l_value := get_optional_string(p_object, p_attribute_name);

    IF l_value IS NULL THEN
      RETURN NULL;
    END IF;

    IF NOT REGEXP_LIKE(l_value, '^[0-9]{4}-[0-9]{2}-[0-9]{2}$')
       OR VALIDATE_CONVERSION(l_value AS DATE, 'FXYYYY-MM-DD') = 0 THEN
      RAISE e_invalid_date_format;
    END IF;

    RETURN TO_DATE(l_value, 'FXYYYY-MM-DD');
  END get_optional_date;

  PROCEDURE parse_create_request(
    p_request_body  IN  CLOB,
    o_display_name  OUT VARCHAR2,
    o_full_name     OUT VARCHAR2,
    o_birth_date    OUT DATE,
    o_bio           OUT VARCHAR2,
    o_avatar_url    OUT VARCHAR2,
    o_locale_code   OUT VARCHAR2,
    o_timezone_name OUT VARCHAR2
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

    o_display_name := get_required_string(l_object, 'displayName');
    o_full_name := get_optional_string(l_object, 'fullName');
    o_birth_date := get_optional_date(l_object, 'birthDate');
    o_bio := get_optional_string(l_object, 'bio');
    o_avatar_url := get_optional_string(l_object, 'avatarUrl');
    o_locale_code := get_required_string(l_object, 'localeCode');
    o_timezone_name := get_required_string(l_object, 'timezoneName');
  END parse_create_request;

  PROCEDURE parse_update_request(
    p_request_body IN  CLOB,
    o_patch        OUT t_profile_patch
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

    IF l_object.get_size = 0 THEN
      RAISE e_required_field;
    END IF;

    o_patch.display_name_present := l_object.has('displayName');
    o_patch.full_name_present := l_object.has('fullName');
    o_patch.birth_date_present := l_object.has('birthDate');
    o_patch.bio_present := l_object.has('bio');
    o_patch.avatar_url_present := l_object.has('avatarUrl');
    o_patch.locale_code_present := l_object.has('localeCode');
    o_patch.timezone_name_present := l_object.has('timezoneName');

    IF o_patch.display_name_present THEN
      o_patch.display_name := get_required_string(l_object, 'displayName');
    END IF;

    IF o_patch.full_name_present THEN
      o_patch.full_name := get_optional_string(l_object, 'fullName');
    END IF;

    IF o_patch.birth_date_present THEN
      o_patch.birth_date := get_optional_date(l_object, 'birthDate');
    END IF;

    IF o_patch.bio_present THEN
      o_patch.bio := get_optional_string(l_object, 'bio');
    END IF;

    IF o_patch.avatar_url_present THEN
      o_patch.avatar_url := get_optional_string(l_object, 'avatarUrl');
    END IF;

    IF o_patch.locale_code_present THEN
      o_patch.locale_code := get_required_string(l_object, 'localeCode');
    END IF;

    IF o_patch.timezone_name_present THEN
      o_patch.timezone_name := get_required_string(l_object, 'timezoneName');
    END IF;
  END parse_update_request;

  ------------------------------------------------------------------------------
  -- Helpers privados de payload
  ------------------------------------------------------------------------------

  FUNCTION profile_to_json(
    p_profile IN BEX_PROFILE%ROWTYPE
  ) RETURN JSON_OBJECT_T IS
    l_data JSON_OBJECT_T := JSON_OBJECT_T();
  BEGIN
    core_json_pkg.put_string(
      l_data,
      'profilePublicId',
      TRIM(p_profile.PFL_PUBLIC_ID)
    );
    core_json_pkg.put_string(
      l_data,
      'displayName',
      p_profile.PFL_DISPLAY_NAME
    );

    IF p_profile.PFL_FULL_NAME IS NULL THEN
      core_json_pkg.put_null(l_data, 'fullName');
    ELSE
      core_json_pkg.put_string(l_data, 'fullName', p_profile.PFL_FULL_NAME);
    END IF;

    IF p_profile.PFL_BIRTH_DATE IS NULL THEN
      core_json_pkg.put_null(l_data, 'birthDate');
    ELSE
      core_json_pkg.put_string(
        l_data,
        'birthDate',
        TO_CHAR(p_profile.PFL_BIRTH_DATE, 'YYYY-MM-DD')
      );
    END IF;

    IF p_profile.PFL_BIO IS NULL THEN
      core_json_pkg.put_null(l_data, 'bio');
    ELSE
      core_json_pkg.put_string(l_data, 'bio', p_profile.PFL_BIO);
    END IF;

    IF p_profile.PFL_AVATAR_URL IS NULL THEN
      core_json_pkg.put_null(l_data, 'avatarUrl');
    ELSE
      core_json_pkg.put_string(l_data, 'avatarUrl', p_profile.PFL_AVATAR_URL);
    END IF;

    core_json_pkg.put_string(
      l_data,
      'localeCode',
      p_profile.PFL_LOCALE_CODE
    );
    core_json_pkg.put_string(
      l_data,
      'timezoneName',
      p_profile.PFL_TIMEZONE_NAME
    );
    core_json_pkg.put_string(
      l_data,
      'createdAt',
      core_json_pkg.format_timestamp(p_profile.PFL_CREATED_AT)
    );
    core_json_pkg.put_string(
      l_data,
      'updatedAt',
      core_json_pkg.format_timestamp(p_profile.PFL_UPDATED_AT)
    );

    RETURN l_data;
  END profile_to_json;

  ------------------------------------------------------------------------------
  -- Helpers privados de erro
  ------------------------------------------------------------------------------

  PROCEDURE build_known_error_response(
    p_status_code      IN  PLS_INTEGER,
    p_code             IN  core_error_pkg.t_error_code,
    p_category         IN  core_error_pkg.t_category,
    p_external_message IN  core_error_pkg.t_external_message,
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
      p_severity         => core_error_pkg.c_severity_warn,
      p_retryable        => FALSE,
      p_should_log       => FALSE,
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

  PROCEDURE build_request_error(
    p_exception_code IN  PLS_INTEGER,
    o_status_code    OUT PLS_INTEGER,
    o_response_body  OUT NOCOPY CLOB
  ) IS
  BEGIN
    CASE p_exception_code
      WHEN 1 THEN
        build_known_error_response(c_status_bad_request, c_code_body_required,
          core_error_pkg.c_category_validation,
          'O corpo da requisicao e obrigatorio.', o_status_code, o_response_body);
      WHEN 2 THEN
        build_known_error_response(c_status_bad_request, c_code_required_value,
          core_error_pkg.c_category_validation,
          'Um identificador publico obrigatorio nao foi informado.', o_status_code, o_response_body);
      WHEN 3 THEN
        build_known_error_response(c_status_bad_request, c_code_required_value,
          core_error_pkg.c_category_validation,
          'O ator tecnico obrigatorio nao foi informado.', o_status_code, o_response_body);
      WHEN 4 THEN
        build_known_error_response(c_status_bad_request, c_code_invalid_json,
          core_error_pkg.c_category_validation,
          'O corpo da requisicao nao contem JSON valido.', o_status_code, o_response_body);
      WHEN 5 THEN
        build_known_error_response(c_status_bad_request, c_code_object_required,
          core_error_pkg.c_category_validation,
          'O corpo da requisicao deve ser um objeto JSON.', o_status_code, o_response_body);
      WHEN 6 THEN
        build_known_error_response(c_status_bad_request, c_code_required_value,
          core_error_pkg.c_category_validation,
          'Um campo obrigatorio nao foi informado.', o_status_code, o_response_body);
      WHEN 7 THEN
        build_known_error_response(c_status_bad_request, c_code_invalid_field_type,
          core_error_pkg.c_category_validation,
          'Um campo possui tipo invalido.', o_status_code, o_response_body);
      WHEN 8 THEN
        build_known_error_response(c_status_bad_request, c_code_invalid_date_format,
          core_error_pkg.c_category_validation,
          'A data informada possui formato invalido.', o_status_code, o_response_body);
      WHEN 9 THEN
        build_known_error_response(c_status_bad_request, c_code_unknown_field,
          core_error_pkg.c_category_validation,
          'A requisicao contem campo desconhecido.', o_status_code, o_response_body);
    END CASE;
  END build_request_error;

  PROCEDURE build_validation_error(
    p_exception_code IN  PLS_INTEGER,
    o_status_code    OUT PLS_INTEGER,
    o_response_body  OUT NOCOPY CLOB
  ) IS
  BEGIN
    CASE p_exception_code
      WHEN 1 THEN
        build_known_error_response(c_status_unprocessable, c_code_invalid_display_name,
          core_error_pkg.c_category_validation,
          'O nome de exibicao informado e invalido.', o_status_code, o_response_body);
      WHEN 2 THEN
        build_known_error_response(c_status_unprocessable, c_code_invalid_full_name,
          core_error_pkg.c_category_validation,
          'O nome completo informado e invalido.', o_status_code, o_response_body);
      WHEN 3 THEN
        build_known_error_response(c_status_unprocessable, c_code_invalid_birth_date,
          core_error_pkg.c_category_validation,
          'A data de nascimento informada e invalida.', o_status_code, o_response_body);
      WHEN 4 THEN
        build_known_error_response(c_status_unprocessable, c_code_invalid_locale_code,
          core_error_pkg.c_category_validation,
          'A localidade informada e invalida.', o_status_code, o_response_body);
      WHEN 5 THEN
        build_known_error_response(c_status_unprocessable, c_code_invalid_timezone_name,
          core_error_pkg.c_category_validation,
          'O fuso horario informado e invalido.', o_status_code, o_response_body);
    END CASE;
  END build_validation_error;

  ------------------------------------------------------------------------------
  -- Operacoes publicas
  ------------------------------------------------------------------------------

  PROCEDURE create_profile(
    p_account_public_id IN  VARCHAR2,
    p_request_body      IN  CLOB,
    p_actor_id          IN  NUMBER,
    o_status_code       OUT PLS_INTEGER,
    o_response_body     OUT NOCOPY CLOB
  ) IS
    l_display_name  VARCHAR2(32767);
    l_full_name     VARCHAR2(32767);
    l_birth_date    DATE;
    l_bio           VARCHAR2(32767);
    l_avatar_url    VARCHAR2(32767);
    l_locale_code   VARCHAR2(32767);
    l_timezone_name VARCHAR2(32767);
    l_profile       BEX_PROFILE%ROWTYPE;
    l_data          JSON_OBJECT_T;
    l_success_body  CLOB;
  BEGIN
    o_status_code := c_status_internal_error;
    o_response_body := NULL;

    assert_public_id(p_account_public_id);
    assert_actor(p_actor_id);
    parse_create_request(p_request_body, l_display_name, l_full_name,
      l_birth_date, l_bio, l_avatar_url, l_locale_code, l_timezone_name);

    l_profile := pfl_service_pkg.create_by_account_public_id(
      p_account_public_id => p_account_public_id,
      p_display_name      => l_display_name,
      p_full_name         => l_full_name,
      p_birth_date        => l_birth_date,
      p_bio               => l_bio,
      p_avatar_url        => l_avatar_url,
      p_locale_code       => l_locale_code,
      p_timezone_name     => l_timezone_name,
      p_audit_actor_id    => p_actor_id
    );

    l_data := profile_to_json(l_profile);
    l_success_body := core_response_pkg.build_success(l_data);
    COMMIT;
    o_response_body := l_success_body;
    o_status_code := c_status_created;
  EXCEPTION
    WHEN e_request_body_required THEN ROLLBACK; free_temporary_clob(l_success_body); build_request_error(1, o_status_code, o_response_body);
    WHEN e_public_id_required THEN ROLLBACK; free_temporary_clob(l_success_body); build_request_error(2, o_status_code, o_response_body);
    WHEN e_actor_required THEN ROLLBACK; free_temporary_clob(l_success_body); build_request_error(3, o_status_code, o_response_body);
    WHEN e_invalid_json THEN ROLLBACK; free_temporary_clob(l_success_body); build_request_error(4, o_status_code, o_response_body);
    WHEN e_json_object_required THEN ROLLBACK; free_temporary_clob(l_success_body); build_request_error(5, o_status_code, o_response_body);
    WHEN e_required_field THEN ROLLBACK; free_temporary_clob(l_success_body); build_request_error(6, o_status_code, o_response_body);
    WHEN e_invalid_field_type THEN ROLLBACK; free_temporary_clob(l_success_body); build_request_error(7, o_status_code, o_response_body);
    WHEN e_invalid_date_format THEN ROLLBACK; free_temporary_clob(l_success_body); build_request_error(8, o_status_code, o_response_body);
    WHEN e_unknown_field THEN ROLLBACK; free_temporary_clob(l_success_body); build_request_error(9, o_status_code, o_response_body);
    WHEN pfl_service_pkg.e_account_not_found THEN ROLLBACK; free_temporary_clob(l_success_body); build_known_error_response(c_status_not_found, c_code_account_not_found, core_error_pkg.c_category_not_found, 'A conta informada nao foi encontrada.', o_status_code, o_response_body);
    WHEN pfl_service_pkg.e_account_already_has_profile THEN ROLLBACK; free_temporary_clob(l_success_body); build_known_error_response(c_status_conflict, c_code_account_already_has_profile, core_error_pkg.c_category_conflict, 'A conta informada ja possui PROFILE.', o_status_code, o_response_body);
    WHEN pfl_service_pkg.e_invalid_display_name THEN ROLLBACK; free_temporary_clob(l_success_body); build_validation_error(1, o_status_code, o_response_body);
    WHEN pfl_service_pkg.e_invalid_full_name THEN ROLLBACK; free_temporary_clob(l_success_body); build_validation_error(2, o_status_code, o_response_body);
    WHEN pfl_service_pkg.e_invalid_birth_date THEN ROLLBACK; free_temporary_clob(l_success_body); build_validation_error(3, o_status_code, o_response_body);
    WHEN pfl_service_pkg.e_invalid_locale_code THEN ROLLBACK; free_temporary_clob(l_success_body); build_validation_error(4, o_status_code, o_response_body);
    WHEN pfl_service_pkg.e_invalid_timezone_name THEN ROLLBACK; free_temporary_clob(l_success_body); build_validation_error(5, o_status_code, o_response_body);
    WHEN OTHERS THEN
      ROLLBACK;
      free_temporary_clob(l_success_body);
      o_status_code := c_status_internal_error;
      o_response_body := NULL;
      BEGIN
        build_technical_error_response(o_status_code, o_response_body);
      EXCEPTION WHEN OTHERS THEN
        o_status_code := c_status_internal_error;
        o_response_body := NULL;
      END;
  END create_profile;

  PROCEDURE get_profile(
    p_profile_public_id IN  VARCHAR2,
    p_actor_id          IN  NUMBER,
    o_status_code       OUT PLS_INTEGER,
    o_response_body     OUT NOCOPY CLOB
  ) IS
    l_profile BEX_PROFILE%ROWTYPE;
    l_data    JSON_OBJECT_T;
  BEGIN
    o_status_code := c_status_internal_error;
    o_response_body := NULL;
    assert_public_id(p_profile_public_id);
    assert_actor(p_actor_id);
    l_profile := pfl_service_pkg.get_by_public_id(p_profile_public_id);
    l_data := profile_to_json(l_profile);
    o_response_body := core_response_pkg.build_success(l_data);
    o_status_code := c_status_ok;
  EXCEPTION
    WHEN e_public_id_required THEN build_request_error(2, o_status_code, o_response_body);
    WHEN e_actor_required THEN build_request_error(3, o_status_code, o_response_body);
    WHEN pfl_service_pkg.e_profile_not_found THEN build_known_error_response(c_status_not_found, c_code_profile_not_found, core_error_pkg.c_category_not_found, 'O PROFILE informado nao foi encontrado.', o_status_code, o_response_body);
    WHEN OTHERS THEN
      o_status_code := c_status_internal_error;
      o_response_body := NULL;
      BEGIN build_technical_error_response(o_status_code, o_response_body);
      EXCEPTION WHEN OTHERS THEN o_status_code := c_status_internal_error; o_response_body := NULL; END;
  END get_profile;

  PROCEDURE get_profile_by_account(
    p_account_public_id IN  VARCHAR2,
    p_actor_id          IN  NUMBER,
    o_status_code       OUT PLS_INTEGER,
    o_response_body     OUT NOCOPY CLOB
  ) IS
    l_profile BEX_PROFILE%ROWTYPE;
    l_data    JSON_OBJECT_T;
  BEGIN
    o_status_code := c_status_internal_error;
    o_response_body := NULL;
    assert_public_id(p_account_public_id);
    assert_actor(p_actor_id);
    l_profile := pfl_service_pkg.get_by_account_public_id(p_account_public_id);
    l_data := profile_to_json(l_profile);
    o_response_body := core_response_pkg.build_success(l_data);
    o_status_code := c_status_ok;
  EXCEPTION
    WHEN e_public_id_required THEN build_request_error(2, o_status_code, o_response_body);
    WHEN e_actor_required THEN build_request_error(3, o_status_code, o_response_body);
    WHEN pfl_service_pkg.e_account_not_found THEN build_known_error_response(c_status_not_found, c_code_account_not_found, core_error_pkg.c_category_not_found, 'A conta informada nao foi encontrada.', o_status_code, o_response_body);
    WHEN pfl_service_pkg.e_profile_not_found THEN build_known_error_response(c_status_not_found, c_code_account_without_profile, core_error_pkg.c_category_not_found, 'A conta informada ainda nao possui PROFILE.', o_status_code, o_response_body);
    WHEN OTHERS THEN
      o_status_code := c_status_internal_error;
      o_response_body := NULL;
      BEGIN build_technical_error_response(o_status_code, o_response_body);
      EXCEPTION WHEN OTHERS THEN o_status_code := c_status_internal_error; o_response_body := NULL; END;
  END get_profile_by_account;

  PROCEDURE update_profile(
    p_profile_public_id IN  VARCHAR2,
    p_request_body      IN  CLOB,
    p_actor_id          IN  NUMBER,
    o_status_code       OUT PLS_INTEGER,
    o_response_body     OUT NOCOPY CLOB
  ) IS
    l_profile      BEX_PROFILE%ROWTYPE;
    l_patch        t_profile_patch;
    l_data         JSON_OBJECT_T;
    l_success_body CLOB;
  BEGIN
    o_status_code := c_status_internal_error;
    o_response_body := NULL;
    assert_public_id(p_profile_public_id);
    assert_actor(p_actor_id);
    parse_update_request(p_request_body, l_patch);

    l_profile := pfl_service_pkg.get_by_public_id(p_profile_public_id);

    IF l_patch.display_name_present THEN
      l_profile.PFL_DISPLAY_NAME := l_patch.display_name;
    END IF;
    IF l_patch.full_name_present THEN
      l_profile.PFL_FULL_NAME := l_patch.full_name;
    END IF;
    IF l_patch.birth_date_present THEN
      l_profile.PFL_BIRTH_DATE := l_patch.birth_date;
    END IF;
    IF l_patch.bio_present THEN
      l_profile.PFL_BIO := l_patch.bio;
    END IF;
    IF l_patch.avatar_url_present THEN
      l_profile.PFL_AVATAR_URL := l_patch.avatar_url;
    END IF;
    IF l_patch.locale_code_present THEN
      l_profile.PFL_LOCALE_CODE := l_patch.locale_code;
    END IF;
    IF l_patch.timezone_name_present THEN
      l_profile.PFL_TIMEZONE_NAME := l_patch.timezone_name;
    END IF;

    l_profile := pfl_service_pkg.update_by_public_id(
      p_profile_public_id => p_profile_public_id,
      p_display_name      => l_profile.PFL_DISPLAY_NAME,
      p_full_name         => l_profile.PFL_FULL_NAME,
      p_birth_date        => l_profile.PFL_BIRTH_DATE,
      p_bio               => l_profile.PFL_BIO,
      p_avatar_url        => l_profile.PFL_AVATAR_URL,
      p_locale_code       => l_profile.PFL_LOCALE_CODE,
      p_timezone_name     => l_profile.PFL_TIMEZONE_NAME,
      p_audit_actor_id    => p_actor_id
    );

    l_data := profile_to_json(l_profile);
    l_success_body := core_response_pkg.build_success(l_data);
    COMMIT;
    o_response_body := l_success_body;
    o_status_code := c_status_ok;
  EXCEPTION
    WHEN e_request_body_required THEN ROLLBACK; free_temporary_clob(l_success_body); build_request_error(1, o_status_code, o_response_body);
    WHEN e_public_id_required THEN ROLLBACK; free_temporary_clob(l_success_body); build_request_error(2, o_status_code, o_response_body);
    WHEN e_actor_required THEN ROLLBACK; free_temporary_clob(l_success_body); build_request_error(3, o_status_code, o_response_body);
    WHEN e_invalid_json THEN ROLLBACK; free_temporary_clob(l_success_body); build_request_error(4, o_status_code, o_response_body);
    WHEN e_json_object_required THEN ROLLBACK; free_temporary_clob(l_success_body); build_request_error(5, o_status_code, o_response_body);
    WHEN e_required_field THEN ROLLBACK; free_temporary_clob(l_success_body); build_request_error(6, o_status_code, o_response_body);
    WHEN e_invalid_field_type THEN ROLLBACK; free_temporary_clob(l_success_body); build_request_error(7, o_status_code, o_response_body);
    WHEN e_invalid_date_format THEN ROLLBACK; free_temporary_clob(l_success_body); build_request_error(8, o_status_code, o_response_body);
    WHEN e_unknown_field THEN ROLLBACK; free_temporary_clob(l_success_body); build_request_error(9, o_status_code, o_response_body);
    WHEN pfl_service_pkg.e_profile_not_found THEN ROLLBACK; free_temporary_clob(l_success_body); build_known_error_response(c_status_not_found, c_code_profile_not_found, core_error_pkg.c_category_not_found, 'O PROFILE informado nao foi encontrado.', o_status_code, o_response_body);
    WHEN pfl_service_pkg.e_invalid_display_name THEN ROLLBACK; free_temporary_clob(l_success_body); build_validation_error(1, o_status_code, o_response_body);
    WHEN pfl_service_pkg.e_invalid_full_name THEN ROLLBACK; free_temporary_clob(l_success_body); build_validation_error(2, o_status_code, o_response_body);
    WHEN pfl_service_pkg.e_invalid_birth_date THEN ROLLBACK; free_temporary_clob(l_success_body); build_validation_error(3, o_status_code, o_response_body);
    WHEN pfl_service_pkg.e_invalid_locale_code THEN ROLLBACK; free_temporary_clob(l_success_body); build_validation_error(4, o_status_code, o_response_body);
    WHEN pfl_service_pkg.e_invalid_timezone_name THEN ROLLBACK; free_temporary_clob(l_success_body); build_validation_error(5, o_status_code, o_response_body);
    WHEN OTHERS THEN
      ROLLBACK;
      free_temporary_clob(l_success_body);
      o_status_code := c_status_internal_error;
      o_response_body := NULL;
      BEGIN
        build_technical_error_response(o_status_code, o_response_body);
      EXCEPTION WHEN OTHERS THEN
        o_status_code := c_status_internal_error;
        o_response_body := NULL;
      END;
  END update_profile;
END pfl_api_pkg;
/
