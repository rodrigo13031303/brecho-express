SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

PROMPT ============================================================
PROMPT BRECHO EXPRESS - PRIVATE STORE LOCATION
PROMPT ============================================================

DECLARE
  l_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*) INTO l_count
    FROM USER_TABLES
   WHERE TABLE_NAME = 'BEX_STORE_LOCATION';

  IF l_count = 0 THEN
    EXECUTE IMMEDIATE q'~
      CREATE TABLE BEX_STORE_LOCATION (
        STR_ID           NUMBER NOT NULL,
        STL_POSTAL_CODE  VARCHAR2(8 CHAR) NOT NULL,
        STL_DISTRICT     VARCHAR2(200 CHAR) NOT NULL,
        STL_CITY         VARCHAR2(200 CHAR) NOT NULL,
        STL_STATE        CHAR(2 CHAR) NOT NULL,
        STL_LATITUDE     NUMBER(10,7) NOT NULL,
        STL_LONGITUDE    NUMBER(10,7) NOT NULL,
        STL_UPDATED_AT   TIMESTAMP(6) DEFAULT SYSTIMESTAMP NOT NULL,
        STL_UPDATED_BY   NUMBER NOT NULL,
        CONSTRAINT PK_STORE_LOCATION PRIMARY KEY (STR_ID),
        CONSTRAINT FK_STL_STORE FOREIGN KEY (STR_ID)
          REFERENCES BEX_STORE (STR_ID) ON DELETE CASCADE,
        CONSTRAINT CK_STL_LATITUDE CHECK (
          STL_LATITUDE BETWEEN -90 AND 90
        ),
        CONSTRAINT CK_STL_LONGITUDE CHECK (
          STL_LONGITUDE BETWEEN -180 AND 180
        )
      )
    ~';
    EXECUTE IMMEDIATE q'~
      COMMENT ON TABLE BEX_STORE_LOCATION IS
        'Private store coordinates; public API exposes only district, city, state and approximate distance'
    ~';
    EXECUTE IMMEDIATE q'~
      CREATE INDEX IDX_STL_PUBLIC_AREA
        ON BEX_STORE_LOCATION (STL_STATE, STL_CITY, STL_DISTRICT)
    ~';
  END IF;
END;
/

BEGIN
  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'brecho-express-v1',
    p_pattern     => 'stores/:storePublicId/location',
    p_etag_type   => 'NONE',
    p_comments    => 'Private store location and public approximation'
  );

  ORDS.DEFINE_HANDLER(
    p_module_name   => 'brecho-express-v1',
    p_pattern       => 'stores/:storePublicId/location',
    p_method        => 'PUT',
    p_source_type   => ORDS.SOURCE_TYPE_PLSQL,
    p_mimes_allowed => 'application/json',
    p_comments      => 'Create or replace location owned by authenticated store',
    p_source        => q'~
DECLARE
  l_authenticated BOOLEAN;
  l_account_id NUMBER;
  l_session_public_id VARCHAR2(32);
  l_status PLS_INTEGER;
  l_body CLOB;
  l_store_id NUMBER;
  l_request CLOB := :body_text;
  l_json JSON_OBJECT_T;
  l_postal VARCHAR2(8);
  l_district VARCHAR2(200);
  l_city VARCHAR2(200);
  l_state VARCHAR2(2);
  l_latitude NUMBER;
  l_longitude NUMBER;
  l_data JSON_OBJECT_T := JSON_OBJECT_T();
BEGIN
  ord_runtime_pkg.begin_authenticated_request(
    :authorization, l_authenticated, l_account_id, l_session_public_id,
    l_status, l_body
  );
  :trace_id := core_context_pkg.trace_id();

  IF l_authenticated THEN
    BEGIN
      l_json := JSON_OBJECT_T.parse(l_request);
      l_postal := REGEXP_REPLACE(l_json.get_string('postalCode'), '[^0-9]', '');
      l_district := TRIM(l_json.get_string('district'));
      l_city := TRIM(l_json.get_string('city'));
      l_state := UPPER(TRIM(l_json.get_string('state')));
      l_latitude := l_json.get_number('latitude');
      l_longitude := l_json.get_number('longitude');

      IF LENGTH(l_postal) <> 8
         OR l_district IS NULL OR LENGTH(l_district) > 200
         OR l_city IS NULL OR LENGTH(l_city) > 200
         OR NOT REGEXP_LIKE(l_state, '^[A-Z]{2}$')
         OR l_latitude NOT BETWEEN -90 AND 90
         OR l_longitude NOT BETWEEN -180 AND 180 THEN
        RAISE VALUE_ERROR;
      END IF;

      SELECT STR_ID INTO l_store_id
        FROM BEX_STORE
       WHERE STR_PUBLIC_ID = LOWER(TRIM(:storePublicId))
         AND ACC_ID = l_account_id
         AND STR_STATUS IN ('DRAFT', 'ACTIVE')
       FOR UPDATE;

      UPDATE BEX_STORE_LOCATION
         SET STL_POSTAL_CODE = l_postal,
             STL_DISTRICT = l_district,
             STL_CITY = l_city,
             STL_STATE = l_state,
             STL_LATITUDE = l_latitude,
             STL_LONGITUDE = l_longitude,
             STL_UPDATED_AT = SYSTIMESTAMP,
             STL_UPDATED_BY = l_account_id
       WHERE STR_ID = l_store_id;

      IF SQL%ROWCOUNT = 0 THEN
        INSERT INTO BEX_STORE_LOCATION (
          STR_ID, STL_POSTAL_CODE, STL_DISTRICT, STL_CITY, STL_STATE,
          STL_LATITUDE, STL_LONGITUDE, STL_UPDATED_BY
        ) VALUES (
          l_store_id, l_postal, l_district, l_city, l_state,
          l_latitude, l_longitude, l_account_id
        );
      END IF;

      core_json_pkg.put_string(l_data, 'district', l_district);
      core_json_pkg.put_string(l_data, 'city', l_city);
      core_json_pkg.put_string(l_data, 'state', l_state);
      l_body := core_response_pkg.build_success(l_data);
      l_status := 200;
      COMMIT;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        l_status := 403;
        l_body := '{"success":false,"error":{"code":"BEX-AUTH-004","message":"A conta autenticada nao pode alterar este brecho."}}';
      WHEN OTHERS THEN
        ROLLBACK;
        l_status := 422;
        l_body := '{"success":false,"error":{"code":"BEX-LOCATION-001","message":"Informe um CEP e uma localizacao validos."}}';
    END;
  END IF;

  :status_code := l_status;
  ord_runtime_pkg.write_json_response(l_body);
  ord_runtime_pkg.clear_request_context;
EXCEPTION WHEN OTHERS THEN
  ROLLBACK; ord_runtime_pkg.clear_request_context; RAISE;
END;
~'
  );

  ORDS.DEFINE_PARAMETER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'stores/:storePublicId/location',
    p_method => 'PUT',
    p_name => 'Authorization',
    p_bind_variable_name => 'authorization',
    p_source_type => 'HEADER',
    p_param_type => 'STRING',
    p_access_method => 'IN'
  );
  ORDS.DEFINE_PARAMETER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'stores/:storePublicId/location',
    p_method => 'PUT',
    p_name => 'X-Trace-Id',
    p_bind_variable_name => 'trace_id',
    p_source_type => 'HEADER',
    p_param_type => 'STRING',
    p_access_method => 'OUT'
  );

  ORDS.DEFINE_HANDLER(
    p_module_name   => 'brecho-express-v1',
    p_pattern       => 'stores/:storePublicId/location',
    p_method        => 'GET',
    p_source_type   => ORDS.SOURCE_TYPE_PLSQL,
    p_mimes_allowed => 'application/json',
    p_comments      => 'Return public approximate location and optional distance',
    p_source        => q'~
DECLARE
  l_status PLS_INTEGER := 200;
  l_body CLOB;
  l_district VARCHAR2(200);
  l_city VARCHAR2(200);
  l_state VARCHAR2(2);
  l_store_lat NUMBER;
  l_store_lon NUMBER;
  l_requester_lat NUMBER := :requester_latitude;
  l_requester_lon NUMBER := :requester_longitude;
  l_distance NUMBER;
  l_data JSON_OBJECT_T := JSON_OBJECT_T();
BEGIN
  ord_runtime_pkg.begin_anonymous_request;
  :trace_id := core_context_pkg.trace_id();

  SELECT location_data.STL_DISTRICT,
         location_data.STL_CITY,
         location_data.STL_STATE,
         location_data.STL_LATITUDE,
         location_data.STL_LONGITUDE
    INTO l_district, l_city, l_state, l_store_lat, l_store_lon
    FROM BEX_STORE_LOCATION location_data
    JOIN BEX_STORE store_data ON store_data.STR_ID = location_data.STR_ID
   WHERE store_data.STR_PUBLIC_ID = LOWER(TRIM(:storePublicId))
     AND store_data.STR_STATUS = 'ACTIVE';

  core_json_pkg.put_string(l_data, 'district', l_district);
  core_json_pkg.put_string(l_data, 'city', l_city);
  core_json_pkg.put_string(l_data, 'state', l_state);

  IF l_requester_lat BETWEEN -90 AND 90
     AND l_requester_lon BETWEEN -180 AND 180 THEN
    l_distance := ROUND(
      6371 * ACOS(
        LEAST(1, GREATEST(-1,
          COS(l_requester_lat * ACOS(-1) / 180)
          * COS(l_store_lat * ACOS(-1) / 180)
          * COS((l_store_lon - l_requester_lon) * ACOS(-1) / 180)
          + SIN(l_requester_lat * ACOS(-1) / 180)
          * SIN(l_store_lat * ACOS(-1) / 180)
        ))
      ),
      1
    );
    core_json_pkg.put_number(l_data, 'distanceKm', l_distance);
  ELSE
    core_json_pkg.put_null(l_data, 'distanceKm');
  END IF;

  l_body := core_response_pkg.build_success(l_data);
  :status_code := l_status;
  ord_runtime_pkg.write_json_response(l_body);
  ord_runtime_pkg.clear_request_context;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    l_status := 404;
    l_body := '{"success":false,"error":{"code":"BEX-LOCATION-404","message":"Localizacao publica indisponivel."}}';
    :status_code := l_status;
    ord_runtime_pkg.write_json_response(l_body);
    ord_runtime_pkg.clear_request_context;
  WHEN OTHERS THEN
    ord_runtime_pkg.clear_request_context;
    RAISE;
END;
~'
  );

  ORDS.DEFINE_PARAMETER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'stores/:storePublicId/location',
    p_method => 'GET',
    p_name => 'requesterLatitude',
    p_bind_variable_name => 'requester_latitude',
    p_source_type => 'URI',
    p_param_type => 'DOUBLE',
    p_access_method => 'IN'
  );
  ORDS.DEFINE_PARAMETER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'stores/:storePublicId/location',
    p_method => 'GET',
    p_name => 'requesterLongitude',
    p_bind_variable_name => 'requester_longitude',
    p_source_type => 'URI',
    p_param_type => 'DOUBLE',
    p_access_method => 'IN'
  );
  ORDS.DEFINE_PARAMETER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'stores/:storePublicId/location',
    p_method => 'GET',
    p_name => 'X-Trace-Id',
    p_bind_variable_name => 'trace_id',
    p_source_type => 'HEADER',
    p_param_type => 'STRING',
    p_access_method => 'OUT'
  );
  COMMIT;
END;
/

PROMPT SUCCESS - PRIVATE STORE LOCATION INSTALLED
