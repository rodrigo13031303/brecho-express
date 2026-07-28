WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT Installing Brecho Express ORDS v1 authenticated seller endpoints...

DECLARE
  PROCEDURE define_auth_parameter(p_pattern VARCHAR2, p_method VARCHAR2) IS
  BEGIN
    ORDS.DEFINE_PARAMETER(
      p_module_name => 'brecho-express-v1', p_pattern => p_pattern,
      p_method => p_method, p_name => 'Authorization',
      p_bind_variable_name => 'authorization', p_source_type => 'HEADER',
      p_param_type => 'STRING', p_access_method => 'IN'
    );
    ORDS.DEFINE_PARAMETER(
      p_module_name => 'brecho-express-v1', p_pattern => p_pattern,
      p_method => p_method, p_name => 'X-Trace-Id',
      p_bind_variable_name => 'trace_id', p_source_type => 'HEADER',
      p_param_type => 'STRING', p_access_method => 'OUT'
    );
  END;
BEGIN
  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'accounts/:accountPublicId/stores',
    p_etag_type => 'NONE'
  );

  ORDS.DEFINE_HANDLER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'accounts/:accountPublicId/stores',
    p_method => 'GET', p_source_type => ORDS.SOURCE_TYPE_PLSQL,
    p_mimes_allowed => 'application/json',
    p_source => q'~
DECLARE
  l_authenticated BOOLEAN; l_account_id NUMBER;
  l_session_public_id VARCHAR2(32); l_status PLS_INTEGER; l_body CLOB;
BEGIN
  ord_runtime_pkg.begin_authenticated_request(
    :authorization, l_authenticated, l_account_id, l_session_public_id,
    l_status, l_body
  );
  :trace_id := core_context_pkg.trace_id();
  IF l_authenticated THEN
    IF UPPER(TRIM(:accountPublicId)) <> TRIM(core_context_pkg.actor_public_id) THEN
      l_status := 403;
      l_body := '{"success":false,"error":{"code":"BEX-AUTH-004","message":"A conta autenticada nao pode acessar este recurso."}}';
    ELSE
      str_api_pkg.list_stores_by_account(
        :accountPublicId, l_account_id, l_status, l_body
      );
    END IF;
  END IF;
  :status_code := l_status;
  ord_runtime_pkg.write_json_response(l_body);
  ord_runtime_pkg.clear_request_context;
EXCEPTION WHEN OTHERS THEN
  ROLLBACK; ord_runtime_pkg.clear_request_context; RAISE;
END;
~'
  );
  define_auth_parameter('accounts/:accountPublicId/stores', 'GET');

  ORDS.DEFINE_HANDLER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'accounts/:accountPublicId/stores',
    p_method => 'POST', p_source_type => ORDS.SOURCE_TYPE_PLSQL,
    p_mimes_allowed => 'application/json',
    p_source => q'~
DECLARE
  l_authenticated BOOLEAN; l_account_id NUMBER;
  l_session_public_id VARCHAR2(32); l_status PLS_INTEGER; l_body CLOB;
  l_request_body CLOB := :body_text;
BEGIN
  ord_runtime_pkg.begin_authenticated_request(
    :authorization, l_authenticated, l_account_id, l_session_public_id,
    l_status, l_body
  );
  :trace_id := core_context_pkg.trace_id();
  IF l_authenticated THEN
    IF UPPER(TRIM(:accountPublicId)) <> TRIM(core_context_pkg.actor_public_id) THEN
      l_status := 403;
      l_body := '{"success":false,"error":{"code":"BEX-AUTH-004","message":"A conta autenticada nao pode acessar este recurso."}}';
    ELSE
      str_api_pkg.create_store(
        :accountPublicId, l_request_body, l_account_id, l_status, l_body
      );
    END IF;
  END IF;
  :status_code := l_status;
  ord_runtime_pkg.write_json_response(l_body);
  ord_runtime_pkg.clear_request_context;
EXCEPTION WHEN OTHERS THEN
  ROLLBACK; ord_runtime_pkg.clear_request_context; RAISE;
END;
~'
  );
  define_auth_parameter('accounts/:accountPublicId/stores', 'POST');

  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'stores/:storePublicId/actions/activate',
    p_etag_type => 'NONE'
  );
  ORDS.DEFINE_HANDLER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'stores/:storePublicId/actions/activate',
    p_method => 'POST', p_source_type => ORDS.SOURCE_TYPE_PLSQL,
    p_mimes_allowed => 'application/json',
    p_source => q'~
DECLARE
  l_authenticated BOOLEAN; l_account_id NUMBER;
  l_session_public_id VARCHAR2(32); l_status PLS_INTEGER; l_body CLOB;
  l_owned_store_count PLS_INTEGER;
BEGIN
  ord_runtime_pkg.begin_authenticated_request(
    :authorization, l_authenticated, l_account_id, l_session_public_id,
    l_status, l_body
  );
  :trace_id := core_context_pkg.trace_id();
  IF l_authenticated THEN
    SELECT COUNT(*) INTO l_owned_store_count FROM BEX_STORE
     WHERE STR_PUBLIC_ID = LOWER(TRIM(:storePublicId))
       AND ACC_ID = l_account_id;
    IF l_owned_store_count = 0 THEN
      l_status := 403;
      l_body := '{"success":false,"error":{"code":"BEX-AUTH-004","message":"A conta autenticada nao pode acessar este recurso."}}';
    ELSE
      str_api_pkg.activate_store(:storePublicId,l_account_id,l_status,l_body);
    END IF;
  END IF;
  :status_code := l_status;
  ord_runtime_pkg.write_json_response(l_body);
  ord_runtime_pkg.clear_request_context;
EXCEPTION WHEN OTHERS THEN
  ROLLBACK; ord_runtime_pkg.clear_request_context; RAISE;
END;
~'
  );
  define_auth_parameter('stores/:storePublicId/actions/activate', 'POST');

  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'stores/:storePublicId/products',
    p_etag_type => 'NONE'
  );
  ORDS.DEFINE_HANDLER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'stores/:storePublicId/products',
    p_method => 'GET', p_source_type => ORDS.SOURCE_TYPE_PLSQL,
    p_mimes_allowed => 'application/json',
    p_source => q'~
DECLARE
  l_authenticated BOOLEAN; l_account_id NUMBER;
  l_session_public_id VARCHAR2(32); l_status PLS_INTEGER; l_body CLOB;
BEGIN
  ord_runtime_pkg.begin_authenticated_request(
    :authorization, l_authenticated, l_account_id, l_session_public_id,
    l_status, l_body
  );
  :trace_id := core_context_pkg.trace_id();
  IF l_authenticated THEN
    prd_api_pkg.list_store_products(
      :storePublicId,NULL,l_account_id,l_status,l_body
    );
  END IF;
  :status_code := l_status;
  ord_runtime_pkg.write_json_response(l_body);
  ord_runtime_pkg.clear_request_context;
EXCEPTION WHEN OTHERS THEN
  ROLLBACK; ord_runtime_pkg.clear_request_context; RAISE;
END;
~'
  );
  define_auth_parameter('stores/:storePublicId/products', 'GET');

  ORDS.DEFINE_HANDLER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'stores/:storePublicId/products',
    p_method => 'POST', p_source_type => ORDS.SOURCE_TYPE_PLSQL,
    p_mimes_allowed => 'application/json',
    p_source => q'~
DECLARE
  l_authenticated BOOLEAN; l_account_id NUMBER;
  l_session_public_id VARCHAR2(32); l_status PLS_INTEGER; l_body CLOB;
  l_request_body CLOB := :body_text;
BEGIN
  ord_runtime_pkg.begin_authenticated_request(
    :authorization, l_authenticated, l_account_id, l_session_public_id,
    l_status, l_body
  );
  :trace_id := core_context_pkg.trace_id();
  IF l_authenticated THEN
    prd_api_pkg.create_product(
      :storePublicId,l_request_body,l_account_id,l_status,l_body
    );
  END IF;
  :status_code := l_status;
  ord_runtime_pkg.write_json_response(l_body);
  ord_runtime_pkg.clear_request_context;
EXCEPTION WHEN OTHERS THEN
  ROLLBACK; ord_runtime_pkg.clear_request_context; RAISE;
END;
~'
  );
  define_auth_parameter('stores/:storePublicId/products', 'POST');

  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'stores/:storePublicId/products/:productPublicId/actions/activate',
    p_etag_type => 'NONE'
  );
  ORDS.DEFINE_HANDLER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'stores/:storePublicId/products/:productPublicId/actions/activate',
    p_method => 'POST', p_source_type => ORDS.SOURCE_TYPE_PLSQL,
    p_mimes_allowed => 'application/json',
    p_source => q'~
DECLARE
  l_authenticated BOOLEAN; l_account_id NUMBER;
  l_session_public_id VARCHAR2(32); l_status PLS_INTEGER; l_body CLOB;
  l_image_count PLS_INTEGER;
BEGIN
  ord_runtime_pkg.begin_authenticated_request(
    :authorization, l_authenticated, l_account_id, l_session_public_id,
    l_status, l_body
  );
  :trace_id := core_context_pkg.trace_id();
  IF l_authenticated THEN
    SELECT COUNT(*) INTO l_image_count
      FROM BEX_PRODUCT_IMAGE image_data
      JOIN BEX_PRODUCT product_data ON product_data.PRD_ID = image_data.PRD_ID
      JOIN BEX_STORE store_data ON store_data.STR_ID = product_data.STR_ID
     WHERE product_data.PRD_PUBLIC_ID = LOWER(TRIM(:productPublicId))
       AND store_data.STR_PUBLIC_ID = LOWER(TRIM(:storePublicId))
       AND store_data.ACC_ID = l_account_id
       AND image_data.PIM_STATUS = 'ACTIVE';

    IF l_image_count = 0 THEN
      l_status := 422;
      l_body := '{"success":false,"error":{"code":"BEX-PIM-003","message":"Adicione pelo menos uma foto antes de publicar o produto."}}';
    ELSE
      prd_api_pkg.change_status(
        :productPublicId,:storePublicId,'ACTIVE',
        l_account_id,l_status,l_body
      );
    END IF;
  END IF;
  :status_code := l_status;
  ord_runtime_pkg.write_json_response(l_body);
  ord_runtime_pkg.clear_request_context;
EXCEPTION WHEN OTHERS THEN
  ROLLBACK; ord_runtime_pkg.clear_request_context; RAISE;
END;
~'
  );
  define_auth_parameter(
    'stores/:storePublicId/products/:productPublicId/actions/activate','POST'
  );

  COMMIT;
END;
/

PROMPT Authenticated seller endpoints installed.
