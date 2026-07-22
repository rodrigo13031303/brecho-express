CREATE OR REPLACE PACKAGE BODY str_api_pkg AS
  e_request_body_required EXCEPTION;
  e_public_value_required EXCEPTION;
  e_actor_required        EXCEPTION;
  e_invalid_json          EXCEPTION;
  e_json_object_required  EXCEPTION;
  e_required_field        EXCEPTION;
  e_invalid_field_type    EXCEPTION;
  e_unknown_field         EXCEPTION;

  c_status_ok             CONSTANT PLS_INTEGER := 200;
  c_status_created        CONSTANT PLS_INTEGER := 201;
  c_status_bad_request    CONSTANT PLS_INTEGER := 400;
  c_status_not_found      CONSTANT PLS_INTEGER := 404;
  c_status_conflict       CONSTANT PLS_INTEGER := 409;
  c_status_unprocessable  CONSTANT PLS_INTEGER := 422;
  c_status_internal_error CONSTANT PLS_INTEGER := 500;

  c_code_body_required     CONSTANT core_error_pkg.t_error_code := 'BEX-REQ-001';
  c_code_invalid_json      CONSTANT core_error_pkg.t_error_code := 'BEX-REQ-002';
  c_code_object_required   CONSTANT core_error_pkg.t_error_code := 'BEX-REQ-003';
  c_code_required_value    CONSTANT core_error_pkg.t_error_code := 'BEX-REQ-004';
  c_code_invalid_type      CONSTANT core_error_pkg.t_error_code := 'BEX-REQ-005';
  c_code_unknown_field     CONSTANT core_error_pkg.t_error_code := 'BEX-REQ-006';
  c_code_internal_error    CONSTANT core_error_pkg.t_error_code := 'BEX-SYS-001';
  c_code_store_not_found   CONSTANT core_error_pkg.t_error_code := 'BEX-STORE-017';
  c_code_account_not_found CONSTANT core_error_pkg.t_error_code := 'BEX-STORE-018';

  PROCEDURE free_temporary_clob(io_value IN OUT NOCOPY CLOB) IS
  BEGIN
    IF io_value IS NOT NULL AND DBMS_LOB.ISTEMPORARY(io_value) = 1 THEN
      DBMS_LOB.FREETEMPORARY(io_value);
    END IF;
    io_value := NULL;
  END free_temporary_clob;

  FUNCTION is_blank_body(p_request_body IN CLOB) RETURN BOOLEAN IS
    l_length PLS_INTEGER;
    l_offset PLS_INTEGER := 1;
    l_chunk  VARCHAR2(32767);
  BEGIN
    IF p_request_body IS NULL THEN RETURN TRUE; END IF;
    l_length := DBMS_LOB.GETLENGTH(p_request_body);
    IF l_length = 0 THEN RETURN TRUE; END IF;
    WHILE l_offset <= l_length LOOP
      l_chunk := DBMS_LOB.SUBSTR(p_request_body, 32767, l_offset);
      IF REGEXP_REPLACE(l_chunk, '[[:space:]]', '') IS NOT NULL THEN
        RETURN FALSE;
      END IF;
      l_offset := l_offset + 32767;
    END LOOP;
    RETURN TRUE;
  END is_blank_body;

  PROCEDURE assert_public_value(p_value IN VARCHAR2) IS
  BEGIN
    IF TRIM(p_value) IS NULL THEN RAISE e_public_value_required; END IF;
  END assert_public_value;

  PROCEDURE assert_actor(p_actor_id IN NUMBER) IS
  BEGIN
    IF p_actor_id IS NULL OR p_actor_id <= 0 THEN RAISE e_actor_required; END IF;
  END assert_actor;

  FUNCTION parse_object(p_request_body IN CLOB) RETURN JSON_OBJECT_T IS
    l_element JSON_ELEMENT_T;
  BEGIN
    IF is_blank_body(p_request_body) THEN RAISE e_request_body_required; END IF;
    BEGIN
      l_element := JSON_ELEMENT_T.parse(p_request_body);
    EXCEPTION WHEN OTHERS THEN
      RAISE e_invalid_json;
    END;
    IF l_element IS NULL OR NOT l_element.is_object THEN
      RAISE e_json_object_required;
    END IF;
    RETURN TREAT(l_element AS JSON_OBJECT_T);
  END parse_object;

  FUNCTION get_required_string(
    p_object IN JSON_OBJECT_T, p_name IN VARCHAR2
  ) RETURN VARCHAR2 IS
    l_element JSON_ELEMENT_T;
  BEGIN
    IF NOT p_object.has(p_name) THEN RAISE e_required_field; END IF;
    l_element := p_object.get(p_name);
    IF l_element IS NULL OR l_element.is_null THEN RAISE e_required_field; END IF;
    IF NOT l_element.is_string THEN RAISE e_invalid_field_type; END IF;
    RETURN p_object.get_string(p_name);
  END get_required_string;

  FUNCTION get_nullable_string(
    p_object IN JSON_OBJECT_T, p_name IN VARCHAR2
  ) RETURN VARCHAR2 IS
    l_element JSON_ELEMENT_T;
  BEGIN
    IF NOT p_object.has(p_name) THEN RETURN NULL; END IF;
    l_element := p_object.get(p_name);
    IF l_element IS NULL OR l_element.is_null THEN RETURN NULL; END IF;
    IF NOT l_element.is_string THEN RAISE e_invalid_field_type; END IF;
    RETURN p_object.get_string(p_name);
  END get_nullable_string;

  PROCEDURE assert_create_fields(p_object IN JSON_OBJECT_T) IS
    l_keys JSON_KEY_LIST;
  BEGIN
    l_keys := p_object.get_keys;
    FOR i IN 1..l_keys.COUNT LOOP
      IF l_keys(i) NOT IN (
        'storeName', 'storeSlug', 'description', 'logoUrl', 'coverUrl',
        'localeCode', 'timezoneName'
      ) THEN RAISE e_unknown_field; END IF;
    END LOOP;
  END assert_create_fields;

  PROCEDURE parse_create_request(
    p_request_body IN CLOB,
    o_name OUT VARCHAR2, o_slug OUT VARCHAR2,
    o_description OUT VARCHAR2, o_logo_url OUT VARCHAR2,
    o_cover_url OUT VARCHAR2, o_locale_code OUT VARCHAR2,
    o_timezone_name OUT VARCHAR2
  ) IS
    l_object JSON_OBJECT_T := parse_object(p_request_body);
  BEGIN
    assert_create_fields(l_object);
    o_name := get_required_string(l_object, 'storeName');
    o_slug := get_required_string(l_object, 'storeSlug');
    o_description := get_nullable_string(l_object, 'description');
    o_logo_url := get_nullable_string(l_object, 'logoUrl');
    o_cover_url := get_nullable_string(l_object, 'coverUrl');
    IF l_object.has('localeCode') THEN
      o_locale_code := get_required_string(l_object, 'localeCode');
    ELSE o_locale_code := NULL; END IF;
    IF l_object.has('timezoneName') THEN
      o_timezone_name := get_required_string(l_object, 'timezoneName');
    ELSE o_timezone_name := NULL; END IF;
  END parse_create_request;

  PROCEDURE parse_patch_request(
    p_request_body IN CLOB,
    o_patch OUT NOCOPY str_service_pkg.t_store_patch
  ) IS
    l_object JSON_OBJECT_T := parse_object(p_request_body);
  BEGIN
    assert_create_fields(l_object);
    o_patch.set_name := l_object.has('storeName');
    o_patch.set_slug := l_object.has('storeSlug');
    o_patch.set_description := l_object.has('description');
    o_patch.set_logo_url := l_object.has('logoUrl');
    o_patch.set_cover_url := l_object.has('coverUrl');
    o_patch.set_locale_code := l_object.has('localeCode');
    o_patch.set_timezone_name := l_object.has('timezoneName');
    IF o_patch.set_name THEN o_patch.name_value := get_required_string(l_object, 'storeName'); END IF;
    IF o_patch.set_slug THEN o_patch.slug_value := get_required_string(l_object, 'storeSlug'); END IF;
    IF o_patch.set_description THEN o_patch.description_value := get_nullable_string(l_object, 'description'); END IF;
    IF o_patch.set_logo_url THEN o_patch.logo_url_value := get_nullable_string(l_object, 'logoUrl'); END IF;
    IF o_patch.set_cover_url THEN o_patch.cover_url_value := get_nullable_string(l_object, 'coverUrl'); END IF;
    IF o_patch.set_locale_code THEN o_patch.locale_code_value := get_required_string(l_object, 'localeCode'); END IF;
    IF o_patch.set_timezone_name THEN o_patch.timezone_value := get_required_string(l_object, 'timezoneName'); END IF;
  END parse_patch_request;

  FUNCTION store_to_json(
    p_store IN str_service_pkg.t_store_record
  ) RETURN JSON_OBJECT_T IS
    l_data JSON_OBJECT_T := JSON_OBJECT_T();
  BEGIN
    core_json_pkg.put_string(l_data, 'storePublicId', TRIM(p_store.store_public_id));
    core_json_pkg.put_string(l_data, 'storeName', p_store.store_name);
    core_json_pkg.put_string(l_data, 'storeSlug', p_store.store_slug);
    IF p_store.description IS NULL THEN core_json_pkg.put_null(l_data, 'description');
    ELSE core_json_pkg.put_string(l_data, 'description', p_store.description); END IF;
    core_json_pkg.put_string(l_data, 'status', p_store.status);
    IF p_store.logo_url IS NULL THEN core_json_pkg.put_null(l_data, 'logoUrl');
    ELSE core_json_pkg.put_string(l_data, 'logoUrl', p_store.logo_url); END IF;
    IF p_store.cover_url IS NULL THEN core_json_pkg.put_null(l_data, 'coverUrl');
    ELSE core_json_pkg.put_string(l_data, 'coverUrl', p_store.cover_url); END IF;
    core_json_pkg.put_string(l_data, 'localeCode', p_store.locale_code);
    core_json_pkg.put_string(l_data, 'timezoneName', p_store.timezone_name);
    core_json_pkg.put_string(l_data, 'createdAt', core_json_pkg.format_timestamp(p_store.created_at));
    core_json_pkg.put_string(l_data, 'updatedAt', core_json_pkg.format_timestamp(p_store.updated_at));
    RETURN l_data;
  END store_to_json;

  FUNCTION stores_to_json(
    p_stores IN str_service_pkg.t_store_table
  ) RETURN JSON_ARRAY_T IS
    l_data  JSON_ARRAY_T := JSON_ARRAY_T();
    l_index PLS_INTEGER := p_stores.FIRST;
  BEGIN
    WHILE l_index IS NOT NULL LOOP
      core_json_pkg.append_element(l_data, store_to_json(p_stores(l_index)));
      l_index := p_stores.NEXT(l_index);
    END LOOP;
    RETURN l_data;
  END stores_to_json;

  PROCEDURE build_known_error_response(
    p_status IN PLS_INTEGER, p_code IN core_error_pkg.t_error_code,
    p_category IN core_error_pkg.t_category,
    p_message IN core_error_pkg.t_external_message,
    o_status_code OUT PLS_INTEGER, o_response_body OUT NOCOPY CLOB
  ) IS
    l_error core_error_pkg.t_public_error;
    l_policy core_error_pkg.t_error_policy;
  BEGIN
    core_error_pkg.build_known_error(
      p_code, p_category, p_message, core_error_pkg.c_severity_warn,
      FALSE, FALSE, l_error, l_policy
    );
    o_response_body := core_response_pkg.build_error(l_error);
    o_status_code := p_status;
  EXCEPTION WHEN OTHERS THEN
    o_status_code := c_status_internal_error;
    o_response_body := NULL;
  END build_known_error_response;

  PROCEDURE build_technical_error_response(
    o_status_code OUT PLS_INTEGER, o_response_body OUT NOCOPY CLOB
  ) IS
    l_error core_error_pkg.t_public_error;
    l_policy core_error_pkg.t_error_policy;
  BEGIN
    core_error_pkg.build_technical_error(
      c_code_internal_error, 'Nao foi possivel concluir a requisicao.',
      FALSE, l_error, l_policy
    );
    o_response_body := core_response_pkg.build_error(l_error);
    o_status_code := c_status_internal_error;
  END build_technical_error_response;

  PROCEDURE build_request_error(
    p_kind IN PLS_INTEGER,
    o_status_code OUT PLS_INTEGER, o_response_body OUT NOCOPY CLOB
  ) IS
  BEGIN
    CASE p_kind
      WHEN 1 THEN build_known_error_response(400, c_code_body_required, core_error_pkg.c_category_validation, 'O corpo da requisicao e obrigatorio.', o_status_code, o_response_body);
      WHEN 2 THEN build_known_error_response(400, c_code_required_value, core_error_pkg.c_category_validation, 'Um identificador publico obrigatorio nao foi informado.', o_status_code, o_response_body);
      WHEN 3 THEN build_known_error_response(400, c_code_required_value, core_error_pkg.c_category_validation, 'O ator tecnico obrigatorio nao foi informado.', o_status_code, o_response_body);
      WHEN 4 THEN build_known_error_response(400, c_code_invalid_json, core_error_pkg.c_category_validation, 'O corpo da requisicao nao contem JSON valido.', o_status_code, o_response_body);
      WHEN 5 THEN build_known_error_response(400, c_code_object_required, core_error_pkg.c_category_validation, 'O corpo da requisicao deve ser um objeto JSON.', o_status_code, o_response_body);
      WHEN 6 THEN build_known_error_response(400, c_code_required_value, core_error_pkg.c_category_validation, 'Um campo obrigatorio nao foi informado.', o_status_code, o_response_body);
      WHEN 7 THEN build_known_error_response(400, c_code_invalid_type, core_error_pkg.c_category_validation, 'Um campo possui tipo invalido.', o_status_code, o_response_body);
      WHEN 8 THEN build_known_error_response(400, c_code_unknown_field, core_error_pkg.c_category_validation, 'A requisicao contem campo desconhecido.', o_status_code, o_response_body);
    END CASE;
  END build_request_error;

  PROCEDURE build_service_error(
    p_kind IN PLS_INTEGER,
    o_status_code OUT PLS_INTEGER, o_response_body OUT NOCOPY CLOB
  ) IS
    l_status   PLS_INTEGER := c_status_unprocessable;
    l_code     core_error_pkg.t_error_code;
    l_category core_error_pkg.t_category := core_error_pkg.c_category_validation;
    l_message  core_error_pkg.t_external_message;
  BEGIN
    CASE p_kind
      WHEN 1 THEN l_status := 404; l_code := c_code_store_not_found; l_category := core_error_pkg.c_category_not_found; l_message := 'A STORE informada nao foi encontrada.';
      WHEN 2 THEN l_status := 404; l_code := c_code_account_not_found; l_category := core_error_pkg.c_category_not_found; l_message := 'A ACCOUNT informada nao foi encontrada.';
      WHEN 3 THEN l_code := 'BEX-STORE-001'; l_message := 'O nome da STORE e obrigatorio.';
      WHEN 4 THEN l_code := 'BEX-STORE-002'; l_message := 'O nome da STORE e invalido.';
      WHEN 5 THEN l_code := 'BEX-STORE-003'; l_message := 'O slug da STORE e obrigatorio.';
      WHEN 6 THEN l_code := 'BEX-STORE-004'; l_message := 'O slug da STORE e invalido.';
      WHEN 7 THEN l_code := 'BEX-STORE-005'; l_message := 'A descricao da STORE e invalida.';
      WHEN 8 THEN l_code := 'BEX-STORE-006'; l_message := 'A URL do logo da STORE e invalida.';
      WHEN 9 THEN l_code := 'BEX-STORE-007'; l_message := 'A URL da capa da STORE e invalida.';
      WHEN 10 THEN l_code := 'BEX-STORE-008'; l_message := 'O locale da STORE e invalido.';
      WHEN 11 THEN l_code := 'BEX-STORE-009'; l_message := 'O timezone da STORE e invalido.';
      WHEN 12 THEN l_code := 'BEX-STORE-010'; l_message := 'O status da STORE e invalido.';
      WHEN 13 THEN l_status := 409; l_code := 'BEX-STORE-011'; l_category := core_error_pkg.c_category_conflict; l_message := 'A transicao de status da STORE e invalida.';
      WHEN 14 THEN l_code := 'BEX-STORE-012'; l_message := 'A atualizacao da STORE nao possui campos.';
      WHEN 15 THEN l_status := 409; l_code := 'BEX-STORE-013'; l_category := core_error_pkg.c_category_conflict; l_message := 'O slug da STORE nao pode ser alterado neste estado.';
      WHEN 16 THEN l_status := 409; l_code := 'BEX-STORE-014'; l_category := core_error_pkg.c_category_conflict; l_message := 'A STORE encerrada nao pode ser alterada.';
      WHEN 17 THEN l_code := 'BEX-STORE-015'; l_category := core_error_pkg.c_category_business; l_message := 'A ACCOUNT nao esta elegivel para possuir STORE.';
      WHEN 18 THEN l_status := 409; l_code := 'BEX-STORE-016'; l_category := core_error_pkg.c_category_conflict; l_message := 'O slug da STORE ja esta em uso.';
    END CASE;
    build_known_error_response(l_status, l_code, l_category, l_message, o_status_code, o_response_body);
  END build_service_error;

  PROCEDURE handle_technical_error(
    p_write IN BOOLEAN, io_success_body IN OUT NOCOPY CLOB,
    o_status_code OUT PLS_INTEGER, o_response_body OUT NOCOPY CLOB
  ) IS
  BEGIN
    IF p_write THEN ROLLBACK; END IF;
    free_temporary_clob(io_success_body);
    o_status_code := 500; o_response_body := NULL;
    BEGIN build_technical_error_response(o_status_code, o_response_body);
    EXCEPTION WHEN OTHERS THEN o_status_code := 500; o_response_body := NULL; END;
  END handle_technical_error;

  PROCEDURE create_store(
    p_account_public_id IN VARCHAR2, p_request_body IN CLOB, p_actor_id IN NUMBER,
    o_status_code OUT PLS_INTEGER, o_response_body OUT NOCOPY CLOB
  ) IS
    l_name VARCHAR2(32767); l_slug VARCHAR2(32767); l_description VARCHAR2(32767);
    l_logo VARCHAR2(32767); l_cover VARCHAR2(32767); l_locale VARCHAR2(32767);
    l_timezone VARCHAR2(32767); l_store str_service_pkg.t_store_record;
    l_data JSON_OBJECT_T; l_success CLOB;
  BEGIN
    o_status_code := 500; o_response_body := NULL;
    assert_public_value(p_account_public_id); assert_actor(p_actor_id);
    parse_create_request(p_request_body, l_name, l_slug, l_description, l_logo, l_cover, l_locale, l_timezone);
    l_store := str_service_pkg.create_by_account_public_id(
      p_account_public_id, l_name, l_slug, l_description, l_logo, l_cover,
      l_locale, l_timezone, p_actor_id
    );
    l_data := store_to_json(l_store); l_success := core_response_pkg.build_success(l_data);
    COMMIT; o_response_body := l_success; o_status_code := 201;
  EXCEPTION
    WHEN e_request_body_required THEN ROLLBACK; free_temporary_clob(l_success); build_request_error(1,o_status_code,o_response_body);
    WHEN e_public_value_required THEN ROLLBACK; free_temporary_clob(l_success); build_request_error(2,o_status_code,o_response_body);
    WHEN e_actor_required THEN ROLLBACK; free_temporary_clob(l_success); build_request_error(3,o_status_code,o_response_body);
    WHEN e_invalid_json THEN ROLLBACK; free_temporary_clob(l_success); build_request_error(4,o_status_code,o_response_body);
    WHEN e_json_object_required THEN ROLLBACK; free_temporary_clob(l_success); build_request_error(5,o_status_code,o_response_body);
    WHEN e_required_field THEN ROLLBACK; free_temporary_clob(l_success); build_request_error(6,o_status_code,o_response_body);
    WHEN e_invalid_field_type THEN ROLLBACK; free_temporary_clob(l_success); build_request_error(7,o_status_code,o_response_body);
    WHEN e_unknown_field THEN ROLLBACK; free_temporary_clob(l_success); build_request_error(8,o_status_code,o_response_body);
    WHEN str_service_pkg.e_account_not_found THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(2,o_status_code,o_response_body);
    WHEN str_service_pkg.e_name_required THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(3,o_status_code,o_response_body);
    WHEN str_service_pkg.e_invalid_name THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(4,o_status_code,o_response_body);
    WHEN str_service_pkg.e_slug_required THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(5,o_status_code,o_response_body);
    WHEN str_service_pkg.e_invalid_slug THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(6,o_status_code,o_response_body);
    WHEN str_service_pkg.e_invalid_description THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(7,o_status_code,o_response_body);
    WHEN str_service_pkg.e_invalid_logo_url THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(8,o_status_code,o_response_body);
    WHEN str_service_pkg.e_invalid_cover_url THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(9,o_status_code,o_response_body);
    WHEN str_service_pkg.e_invalid_locale THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(10,o_status_code,o_response_body);
    WHEN str_service_pkg.e_invalid_timezone THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(11,o_status_code,o_response_body);
    WHEN str_service_pkg.e_invalid_status THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(12,o_status_code,o_response_body);
    WHEN str_service_pkg.e_account_ineligible THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(17,o_status_code,o_response_body);
    WHEN str_service_pkg.e_slug_already_used THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(18,o_status_code,o_response_body);
    WHEN OTHERS THEN handle_technical_error(TRUE,l_success,o_status_code,o_response_body);
  END create_store;

  PROCEDURE get_store(
    p_store_public_id IN VARCHAR2, p_actor_id IN NUMBER,
    o_status_code OUT PLS_INTEGER, o_response_body OUT NOCOPY CLOB
  ) IS l_store str_service_pkg.t_store_record; l_data JSON_OBJECT_T; l_unused CLOB;
  BEGIN
    o_status_code := 500; o_response_body := NULL;
    assert_public_value(p_store_public_id); assert_actor(p_actor_id);
    l_store := str_service_pkg.require_by_public_id(p_store_public_id);
    l_data := store_to_json(l_store); o_response_body := core_response_pkg.build_success(l_data); o_status_code := 200;
  EXCEPTION
    WHEN e_public_value_required THEN build_request_error(2,o_status_code,o_response_body);
    WHEN e_actor_required THEN build_request_error(3,o_status_code,o_response_body);
    WHEN str_service_pkg.e_store_not_found THEN build_service_error(1,o_status_code,o_response_body);
    WHEN OTHERS THEN handle_technical_error(FALSE,l_unused,o_status_code,o_response_body);
  END get_store;

  PROCEDURE get_store_by_slug(
    p_slug IN VARCHAR2, p_actor_id IN NUMBER,
    o_status_code OUT PLS_INTEGER, o_response_body OUT NOCOPY CLOB
  ) IS l_store str_service_pkg.t_store_record; l_data JSON_OBJECT_T; l_unused CLOB;
  BEGIN
    o_status_code := 500; o_response_body := NULL;
    assert_public_value(p_slug); assert_actor(p_actor_id);
    l_store := str_service_pkg.require_by_slug(p_slug);
    l_data := store_to_json(l_store); o_response_body := core_response_pkg.build_success(l_data); o_status_code := 200;
  EXCEPTION
    WHEN e_public_value_required THEN build_request_error(2,o_status_code,o_response_body);
    WHEN e_actor_required THEN build_request_error(3,o_status_code,o_response_body);
    WHEN str_service_pkg.e_store_not_found THEN build_service_error(1,o_status_code,o_response_body);
    WHEN str_service_pkg.e_slug_required THEN build_service_error(5,o_status_code,o_response_body);
    WHEN str_service_pkg.e_invalid_slug THEN build_service_error(6,o_status_code,o_response_body);
    WHEN OTHERS THEN handle_technical_error(FALSE,l_unused,o_status_code,o_response_body);
  END get_store_by_slug;

  PROCEDURE list_stores_by_account(
    p_account_public_id IN VARCHAR2, p_actor_id IN NUMBER,
    o_status_code OUT PLS_INTEGER, o_response_body OUT NOCOPY CLOB
  ) IS l_stores str_service_pkg.t_store_table; l_data JSON_ARRAY_T; l_unused CLOB;
  BEGIN
    o_status_code := 500; o_response_body := NULL;
    assert_public_value(p_account_public_id); assert_actor(p_actor_id);
    l_stores := str_service_pkg.list_by_account_public_id(p_account_public_id);
    l_data := stores_to_json(l_stores); o_response_body := core_response_pkg.build_success(l_data); o_status_code := 200;
  EXCEPTION
    WHEN e_public_value_required THEN build_request_error(2,o_status_code,o_response_body);
    WHEN e_actor_required THEN build_request_error(3,o_status_code,o_response_body);
    WHEN str_service_pkg.e_account_not_found THEN build_service_error(2,o_status_code,o_response_body);
    WHEN OTHERS THEN handle_technical_error(FALSE,l_unused,o_status_code,o_response_body);
  END list_stores_by_account;

  PROCEDURE update_store(
    p_store_public_id IN VARCHAR2, p_request_body IN CLOB, p_actor_id IN NUMBER,
    o_status_code OUT PLS_INTEGER, o_response_body OUT NOCOPY CLOB
  ) IS l_patch str_service_pkg.t_store_patch; l_store str_service_pkg.t_store_record;
    l_data JSON_OBJECT_T; l_success CLOB;
  BEGIN
    o_status_code := 500; o_response_body := NULL;
    assert_public_value(p_store_public_id); assert_actor(p_actor_id);
    parse_patch_request(p_request_body,l_patch);
    l_store := str_service_pkg.update_by_public_id(p_store_public_id,l_patch,p_actor_id);
    l_data := store_to_json(l_store); l_success := core_response_pkg.build_success(l_data);
    COMMIT; o_response_body := l_success; o_status_code := 200;
  EXCEPTION
    WHEN e_request_body_required THEN ROLLBACK; free_temporary_clob(l_success); build_request_error(1,o_status_code,o_response_body);
    WHEN e_public_value_required THEN ROLLBACK; free_temporary_clob(l_success); build_request_error(2,o_status_code,o_response_body);
    WHEN e_actor_required THEN ROLLBACK; free_temporary_clob(l_success); build_request_error(3,o_status_code,o_response_body);
    WHEN e_invalid_json THEN ROLLBACK; free_temporary_clob(l_success); build_request_error(4,o_status_code,o_response_body);
    WHEN e_json_object_required THEN ROLLBACK; free_temporary_clob(l_success); build_request_error(5,o_status_code,o_response_body);
    WHEN e_required_field THEN ROLLBACK; free_temporary_clob(l_success); build_request_error(6,o_status_code,o_response_body);
    WHEN e_invalid_field_type THEN ROLLBACK; free_temporary_clob(l_success); build_request_error(7,o_status_code,o_response_body);
    WHEN e_unknown_field THEN ROLLBACK; free_temporary_clob(l_success); build_request_error(8,o_status_code,o_response_body);
    WHEN str_service_pkg.e_store_not_found THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(1,o_status_code,o_response_body);
    WHEN str_service_pkg.e_name_required THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(3,o_status_code,o_response_body);
    WHEN str_service_pkg.e_invalid_name THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(4,o_status_code,o_response_body);
    WHEN str_service_pkg.e_slug_required THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(5,o_status_code,o_response_body);
    WHEN str_service_pkg.e_invalid_slug THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(6,o_status_code,o_response_body);
    WHEN str_service_pkg.e_invalid_description THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(7,o_status_code,o_response_body);
    WHEN str_service_pkg.e_invalid_logo_url THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(8,o_status_code,o_response_body);
    WHEN str_service_pkg.e_invalid_cover_url THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(9,o_status_code,o_response_body);
    WHEN str_service_pkg.e_invalid_locale THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(10,o_status_code,o_response_body);
    WHEN str_service_pkg.e_invalid_timezone THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(11,o_status_code,o_response_body);
    WHEN str_service_pkg.e_invalid_status THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(12,o_status_code,o_response_body);
    WHEN str_service_pkg.e_empty_patch THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(14,o_status_code,o_response_body);
    WHEN str_service_pkg.e_slug_not_editable THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(15,o_status_code,o_response_body);
    WHEN str_service_pkg.e_store_closed THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(16,o_status_code,o_response_body);
    WHEN str_service_pkg.e_slug_already_used THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(18,o_status_code,o_response_body);
    WHEN OTHERS THEN handle_technical_error(TRUE,l_success,o_status_code,o_response_body);
  END update_store;

  PROCEDURE activate_store(
    p_store_public_id IN VARCHAR2, p_actor_id IN NUMBER,
    o_status_code OUT PLS_INTEGER, o_response_body OUT NOCOPY CLOB
  ) IS l_store str_service_pkg.t_store_record; l_data JSON_OBJECT_T; l_success CLOB;
  BEGIN
    o_status_code := 500; o_response_body := NULL;
    assert_public_value(p_store_public_id); assert_actor(p_actor_id);
    l_store := str_service_pkg.activate_by_public_id(p_store_public_id,p_actor_id);
    l_data := store_to_json(l_store); l_success := core_response_pkg.build_success(l_data);
    COMMIT; o_response_body := l_success; o_status_code := 200;
  EXCEPTION
    WHEN e_public_value_required THEN ROLLBACK; free_temporary_clob(l_success); build_request_error(2,o_status_code,o_response_body);
    WHEN e_actor_required THEN ROLLBACK; free_temporary_clob(l_success); build_request_error(3,o_status_code,o_response_body);
    WHEN str_service_pkg.e_store_not_found THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(1,o_status_code,o_response_body);
    WHEN str_service_pkg.e_invalid_status THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(12,o_status_code,o_response_body);
    WHEN str_service_pkg.e_invalid_transition THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(13,o_status_code,o_response_body);
    WHEN OTHERS THEN handle_technical_error(TRUE,l_success,o_status_code,o_response_body);
  END activate_store;

  PROCEDURE close_store(
    p_store_public_id IN VARCHAR2, p_actor_id IN NUMBER,
    o_status_code OUT PLS_INTEGER, o_response_body OUT NOCOPY CLOB
  ) IS l_store str_service_pkg.t_store_record; l_data JSON_OBJECT_T; l_success CLOB;
  BEGIN
    o_status_code := 500; o_response_body := NULL;
    assert_public_value(p_store_public_id); assert_actor(p_actor_id);
    l_store := str_service_pkg.close_by_public_id(p_store_public_id,p_actor_id);
    l_data := store_to_json(l_store); l_success := core_response_pkg.build_success(l_data);
    COMMIT; o_response_body := l_success; o_status_code := 200;
  EXCEPTION
    WHEN e_public_value_required THEN ROLLBACK; free_temporary_clob(l_success); build_request_error(2,o_status_code,o_response_body);
    WHEN e_actor_required THEN ROLLBACK; free_temporary_clob(l_success); build_request_error(3,o_status_code,o_response_body);
    WHEN str_service_pkg.e_store_not_found THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(1,o_status_code,o_response_body);
    WHEN str_service_pkg.e_invalid_status THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(12,o_status_code,o_response_body);
    WHEN str_service_pkg.e_invalid_transition THEN ROLLBACK; free_temporary_clob(l_success); build_service_error(13,o_status_code,o_response_body);
    WHEN OTHERS THEN handle_technical_error(TRUE,l_success,o_status_code,o_response_body);
  END close_store;

  PROCEDURE check_slug_availability(
    p_slug IN VARCHAR2, p_actor_id IN NUMBER,
    o_status_code OUT PLS_INTEGER, o_response_body OUT NOCOPY CLOB
  ) IS l_available BOOLEAN; l_data JSON_OBJECT_T := JSON_OBJECT_T(); l_unused CLOB;
  BEGIN
    o_status_code := 500; o_response_body := NULL;
    assert_public_value(p_slug); assert_actor(p_actor_id);
    l_available := str_service_pkg.slug_available(p_slug);
    core_json_pkg.put_boolean(l_data,'available',l_available);
    o_response_body := core_response_pkg.build_success(l_data); o_status_code := 200;
  EXCEPTION
    WHEN e_public_value_required THEN build_request_error(2,o_status_code,o_response_body);
    WHEN e_actor_required THEN build_request_error(3,o_status_code,o_response_body);
    WHEN str_service_pkg.e_slug_required THEN build_service_error(5,o_status_code,o_response_body);
    WHEN str_service_pkg.e_invalid_slug THEN build_service_error(6,o_status_code,o_response_body);
    WHEN OTHERS THEN handle_technical_error(FALSE,l_unused,o_status_code,o_response_body);
  END check_slug_availability;
END str_api_pkg;
/
