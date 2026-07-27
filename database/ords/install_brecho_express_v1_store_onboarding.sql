SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

BEGIN
  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'accounts/:accountPublicId/stores/onboarding',
    p_etag_type => 'NONE',
    p_comments => 'Atomic store onboarding'
  );

  ORDS.DEFINE_HANDLER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'accounts/:accountPublicId/stores/onboarding',
    p_method => 'POST',
    p_source_type => ORDS.SOURCE_TYPE_PLSQL,
    p_mimes_allowed => 'application/json',
    p_comments => 'Create, locate and activate a store in one transaction',
    p_source => q'~
DECLARE
  l_authenticated BOOLEAN;
  l_account_id NUMBER;
  l_session_public_id VARCHAR2(32);
  l_status PLS_INTEGER;
  l_body CLOB;
  l_request CLOB := :body_text;
BEGIN
  ord_runtime_pkg.begin_authenticated_request(
    :authorization, l_authenticated, l_account_id, l_session_public_id,
    l_status, l_body
  );
  :trace_id := core_context_pkg.trace_id();
  IF l_authenticated THEN
    IF UPPER(TRIM(:accountPublicId))
       <> TRIM(core_context_pkg.actor_public_id) THEN
      l_status := 403;
      l_body := '{"success":false,"error":{"code":"BEX-AUTH-004","message":"A conta autenticada nao pode criar este brecho."}}';
    ELSE
      store_onboarding_api_pkg.create_complete_store(
        :accountPublicId, l_request, l_account_id, l_status, l_body
      );
    END IF;
  END IF;
  :status_code := l_status;
  ord_runtime_pkg.write_json_response(l_body);
  ord_runtime_pkg.clear_request_context;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    ord_runtime_pkg.clear_request_context;
    RAISE;
END;
~'
  );

  ORDS.DEFINE_PARAMETER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'accounts/:accountPublicId/stores/onboarding',
    p_method => 'POST',
    p_name => 'Authorization',
    p_bind_variable_name => 'authorization',
    p_source_type => 'HEADER',
    p_param_type => 'STRING',
    p_access_method => 'IN'
  );
  ORDS.DEFINE_PARAMETER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'accounts/:accountPublicId/stores/onboarding',
    p_method => 'POST',
    p_name => 'X-Trace-Id',
    p_bind_variable_name => 'trace_id',
    p_source_type => 'RESPONSE',
    p_param_type => 'STRING',
    p_access_method => 'OUT'
  );
  ORDS.DEFINE_PARAMETER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'accounts/:accountPublicId/stores/onboarding',
    p_method => 'POST',
    p_name => 'X-ORDS-STATUS-CODE',
    p_bind_variable_name => 'status_code',
    p_source_type => 'HEADER',
    p_param_type => 'INT',
    p_access_method => 'OUT'
  );
  COMMIT;
END;
/