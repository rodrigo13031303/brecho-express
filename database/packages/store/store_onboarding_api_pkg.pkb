CREATE OR REPLACE PACKAGE BODY store_onboarding_api_pkg AS
  PROCEDURE create_complete_store(
    p_account_public_id IN VARCHAR2,
    p_request_body IN CLOB,
    p_actor_id IN NUMBER,
    o_status_code OUT PLS_INTEGER,
    o_response_body OUT NOCOPY CLOB
  ) IS
    l_json JSON_OBJECT_T;
    l_location JSON_OBJECT_T;
    l_store str_service_pkg.t_store_record;
    l_store_id NUMBER;
    l_name VARCHAR2(200);
    l_slug VARCHAR2(100);
    l_description VARCHAR2(1000);
    l_postal VARCHAR2(8);
    l_street VARCHAR2(300);
    l_number VARCHAR2(30);
    l_complement VARCHAR2(200);
    l_district VARCHAR2(200);
    l_city VARCHAR2(200);
    l_state VARCHAR2(2);
    l_latitude NUMBER;
    l_longitude NUMBER;
    l_data JSON_OBJECT_T := JSON_OBJECT_T();

    PROCEDURE log_failure(
      p_code IN NUMBER,
      p_message IN VARCHAR2,
      p_backtrace IN VARCHAR2
    ) IS
    BEGIN
      api_error_log_pkg.capture(
        p_trace_id => core_context_pkg.trace_id(),
        p_component => 'STORE_ONBOARDING_API_PKG',
        p_operation => 'CREATE_COMPLETE_STORE',
        p_actor_id => p_actor_id,
        p_sql_code => p_code,
        p_sql_message => p_message,
        p_backtrace => p_backtrace
      );
    EXCEPTION
      WHEN OTHERS THEN NULL;
    END log_failure;

    FUNCTION error_body(p_code IN VARCHAR2, p_message IN VARCHAR2)
      RETURN CLOB IS
    BEGIN
      RETURN '{"success":false,"traceId":"'
        || core_context_pkg.trace_id()
        || '","error":{"code":"' || p_code
        || '","message":"' || p_message || '"}}';
    END error_body;
  BEGIN
    o_status_code := 500;
    o_response_body := NULL;

    l_json := JSON_OBJECT_T.parse(p_request_body);
    IF NOT l_json.has('location') THEN
      RAISE VALUE_ERROR;
    END IF;
    l_location := l_json.get_object('location');
    l_name := TRIM(l_json.get_string('storeName'));
    l_slug := LOWER(TRIM(l_json.get_string('storeSlug')));
    IF l_json.has('description') THEN
      l_description := TRIM(l_json.get_string('description'));
    END IF;
    l_postal := REGEXP_REPLACE(l_location.get_string('postalCode'), '[^0-9]', '');
    l_street := TRIM(l_location.get_string('street'));
    l_number := TRIM(l_location.get_string('number'));
    IF l_location.has('complement') THEN
      l_complement := TRIM(l_location.get_string('complement'));
    END IF;
    l_district := TRIM(l_location.get_string('district'));
    l_city := TRIM(l_location.get_string('city'));
    l_state := UPPER(TRIM(l_location.get_string('state')));
    l_latitude := l_location.get_number('latitude');
    l_longitude := l_location.get_number('longitude');

    IF p_actor_id IS NULL
       OR TRIM(p_account_public_id) IS NULL
       OR LENGTH(l_postal) <> 8
       OR l_street IS NULL OR LENGTH(l_street) > 300
       OR l_number IS NULL OR LENGTH(l_number) > 30
       OR LENGTH(l_complement) > 200
       OR l_district IS NULL OR LENGTH(l_district) > 200
       OR l_city IS NULL OR LENGTH(l_city) > 200
       OR NOT REGEXP_LIKE(l_state, '^[A-Z]{2}$')
       OR l_latitude NOT BETWEEN -90 AND 90
       OR l_longitude NOT BETWEEN -180 AND 180 THEN
      RAISE VALUE_ERROR;
    END IF;

    l_store := str_service_pkg.create_by_account_public_id(
      p_account_public_id => p_account_public_id,
      p_name => l_name,
      p_slug => l_slug,
      p_description => l_description,
      p_locale_code => 'pt-BR',
      p_timezone_name => 'America/Sao_Paulo',
      p_audit_actor_id => p_actor_id
    );
    l_store_id := str_service_pkg.resolve_store_id(l_store.store_public_id);

    INSERT INTO BEX_STORE_LOCATION (
      STR_ID, STL_POSTAL_CODE, STL_STREET, STL_NUMBER, STL_COMPLEMENT,
      STL_DISTRICT, STL_CITY, STL_STATE, STL_LATITUDE, STL_LONGITUDE,
      STL_UPDATED_BY
    ) VALUES (
      l_store_id, l_postal, l_street, l_number, l_complement,
      l_district, l_city, l_state, l_latitude, l_longitude, p_actor_id
    );

    l_store := str_service_pkg.activate_by_public_id(
      l_store.store_public_id, p_actor_id
    );

    core_json_pkg.put_string(l_data, 'storePublicId', TRIM(l_store.store_public_id));
    core_json_pkg.put_string(l_data, 'storeName', l_store.store_name);
    core_json_pkg.put_string(l_data, 'storeSlug', l_store.store_slug);
    core_json_pkg.put_string(l_data, 'status', l_store.status);
    IF l_store.logo_url IS NULL THEN
      core_json_pkg.put_null(l_data, 'logoUrl');
    ELSE
      core_json_pkg.put_string(l_data, 'logoUrl', l_store.logo_url);
    END IF;

    o_response_body := core_response_pkg.build_success(l_data);
    o_status_code := 201;
    COMMIT;
  EXCEPTION
    WHEN str_service_pkg.e_slug_already_used THEN
      log_failure(SQLCODE, SQLERRM, DBMS_UTILITY.format_error_backtrace);
      ROLLBACK;
      o_status_code := 409;
      o_response_body := error_body('BEX-STORE-018', 'O link deste brecho ja esta em uso.');
    WHEN str_service_pkg.e_account_not_found
       OR str_service_pkg.e_account_ineligible THEN
      log_failure(SQLCODE, SQLERRM, DBMS_UTILITY.format_error_backtrace);
      ROLLBACK;
      o_status_code := 403;
      o_response_body := error_body('BEX-AUTH-004', 'A conta nao pode criar este brecho.');
    WHEN str_service_pkg.e_name_required
       OR str_service_pkg.e_invalid_name
       OR str_service_pkg.e_slug_required
       OR str_service_pkg.e_invalid_slug
       OR str_service_pkg.e_invalid_description
       OR VALUE_ERROR THEN
      log_failure(SQLCODE, SQLERRM, DBMS_UTILITY.format_error_backtrace);
      ROLLBACK;
      o_status_code := 422;
      o_response_body := error_body('BEX-ONBOARDING-001', 'Confira os dados e o endereco do brecho.');
    WHEN OTHERS THEN
      log_failure(SQLCODE, SQLERRM, DBMS_UTILITY.format_error_backtrace);
      ROLLBACK;
      o_status_code := 500;
      o_response_body := error_body('BEX-TECHNICAL-001', 'Nao foi possivel criar o brecho agora.');
  END create_complete_store;
END store_onboarding_api_pkg;
/