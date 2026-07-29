WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
SET DEFINE OFF

PROMPT Installing authenticated product management endpoints...

DECLARE
  PROCEDURE define_auth_parameter(p_pattern VARCHAR2, p_method VARCHAR2) IS
  BEGIN
    ORDS.DEFINE_PARAMETER(
      p_module_name => 'brecho-express-v1',
      p_pattern => p_pattern,
      p_method => p_method,
      p_name => 'Authorization',
      p_bind_variable_name => 'authorization',
      p_source_type => 'HEADER',
      p_param_type => 'STRING',
      p_access_method => 'IN'
    );
    ORDS.DEFINE_PARAMETER(
      p_module_name => 'brecho-express-v1',
      p_pattern => p_pattern,
      p_method => p_method,
      p_name => 'X-Trace-Id',
      p_bind_variable_name => 'trace_id',
      p_source_type => 'HEADER',
      p_param_type => 'STRING',
      p_access_method => 'OUT'
    );
  END;
BEGIN
  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'stores/:storePublicId/products/:productPublicId',
    p_etag_type => 'NONE'
  );
  ORDS.DEFINE_HANDLER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'stores/:storePublicId/products/:productPublicId',
    p_method => 'PUT',
    p_source_type => ORDS.SOURCE_TYPE_PLSQL,
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
    prd_api_pkg.patch_product(
      :productPublicId,:storePublicId,l_request_body,
      l_account_id,l_status,l_body
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
  define_auth_parameter(
    'stores/:storePublicId/products/:productPublicId','PUT'
  );

  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'stores/:storePublicId/products/:productPublicId/status',
    p_etag_type => 'NONE'
  );
  ORDS.DEFINE_HANDLER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'stores/:storePublicId/products/:productPublicId/status',
    p_method => 'PUT',
    p_source_type => ORDS.SOURCE_TYPE_PLSQL,
    p_mimes_allowed => 'application/json',
    p_source => q'~
DECLARE
  l_authenticated BOOLEAN; l_account_id NUMBER;
  l_session_public_id VARCHAR2(32); l_status PLS_INTEGER; l_body CLOB;
  l_request JSON_OBJECT_T;
BEGIN
  ord_runtime_pkg.begin_authenticated_request(
    :authorization, l_authenticated, l_account_id, l_session_public_id,
    l_status, l_body
  );
  :trace_id := core_context_pkg.trace_id();
  IF l_authenticated THEN
    l_request := JSON_OBJECT_T.parse(:body_text);
    prd_api_pkg.change_status(
      :productPublicId,:storePublicId,l_request.get_string('status'),
      l_account_id,l_status,l_body
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
  define_auth_parameter(
    'stores/:storePublicId/products/:productPublicId/status','PUT'
  );
  COMMIT;
END;
/

PROMPT Authenticated product management endpoints installed.
