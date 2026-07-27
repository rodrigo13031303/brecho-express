WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT Installing Brecho Express ORDS v1 public foundation...

@@install_ord_runtime_pkg.sql

BEGIN
  ORDS.ENABLE_SCHEMA(
    p_enabled             => TRUE,
    p_schema              => SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA'),
    p_url_mapping_type    => 'BASE_PATH',
    p_url_mapping_pattern => 'brechoexpress',
    p_auto_rest_auth      => FALSE
  );

  ORDS.DEFINE_MODULE(
    p_module_name    => 'brecho-express-v1',
    p_base_path      => '/api/v1/',
    p_items_per_page => 25,
    p_status         => 'PUBLISHED',
    p_comments       => 'Brecho Express public API v1'
  );

  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'brecho-express-v1',
    p_pattern     => 'accounts',
    p_etag_type   => 'NONE',
    p_comments    => 'Account collection'
  );

  ORDS.DEFINE_HANDLER(
    p_module_name   => 'brecho-express-v1',
    p_pattern       => 'accounts',
    p_method        => 'POST',
    p_source_type   => ORDS.SOURCE_TYPE_PLSQL,
    p_mimes_allowed => 'application/json',
    p_comments      => 'Create account',
    p_source        => q'~
DECLARE
  l_request_body CLOB := :body_text;
  l_status       PLS_INTEGER;
  l_body         CLOB;
BEGIN
  ord_runtime_pkg.begin_anonymous_request;
  :trace_id := core_context_pkg.trace_id();
  acc_api_pkg.create_account(l_request_body, l_status, l_body);
  :status_code := l_status;
  ord_runtime_pkg.write_json_response(l_body);
  ord_runtime_pkg.clear_request_context;
EXCEPTION
  WHEN OTHERS THEN
    ord_runtime_pkg.clear_request_context;
    RAISE;
END;
~'
  );

  ORDS.DEFINE_PARAMETER(
    p_module_name        => 'brecho-express-v1',
    p_pattern            => 'accounts',
    p_method             => 'POST',
    p_name               => 'X-Trace-Id',
    p_bind_variable_name => 'trace_id',
    p_source_type        => 'HEADER',
    p_param_type         => 'STRING',
    p_access_method      => 'OUT',
    p_comments           => 'Core trace identifier'
  );

  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'brecho-express-v1',
    p_pattern     => 'auth/login',
    p_etag_type   => 'NONE',
    p_comments    => 'Authentication login'
  );

  ORDS.DEFINE_HANDLER(
    p_module_name   => 'brecho-express-v1',
    p_pattern       => 'auth/login',
    p_method        => 'POST',
    p_source_type   => ORDS.SOURCE_TYPE_PLSQL,
    p_mimes_allowed => 'application/json',
    p_comments      => 'Create authenticated session',
    p_source        => q'~
DECLARE
  l_request_body CLOB := :body_text;
  l_status       PLS_INTEGER;
  l_body         CLOB;
BEGIN
  ord_runtime_pkg.begin_anonymous_request;
  :trace_id := core_context_pkg.trace_id();
  acc_auth_api_pkg.login(
    l_request_body,
    :remote_addr,
    :user_agent,
    l_status,
    l_body
  );
  :status_code := l_status;
  ord_runtime_pkg.write_json_response(l_body);
  ord_runtime_pkg.clear_request_context;
EXCEPTION
  WHEN OTHERS THEN
    ord_runtime_pkg.clear_request_context;
    RAISE;
END;
~'
  );

  ORDS.DEFINE_PARAMETER(
    p_module_name        => 'brecho-express-v1',
    p_pattern            => 'auth/login',
    p_method             => 'POST',
    p_name               => 'X-Trace-Id',
    p_bind_variable_name => 'trace_id',
    p_source_type        => 'HEADER',
    p_param_type         => 'STRING',
    p_access_method      => 'OUT',
    p_comments           => 'Core trace identifier'
  );

  ORDS.DEFINE_PARAMETER(
    p_module_name        => 'brecho-express-v1',
    p_pattern            => 'auth/login',
    p_method             => 'POST',
    p_name               => 'X-Forwarded-For',
    p_bind_variable_name => 'remote_addr',
    p_source_type        => 'HEADER',
    p_param_type         => 'STRING',
    p_access_method      => 'IN',
    p_comments           => 'Client address supplied by trusted proxy'
  );

  ORDS.DEFINE_PARAMETER(
    p_module_name        => 'brecho-express-v1',
    p_pattern            => 'auth/login',
    p_method             => 'POST',
    p_name               => 'User-Agent',
    p_bind_variable_name => 'user_agent',
    p_source_type        => 'HEADER',
    p_param_type         => 'STRING',
    p_access_method      => 'IN',
    p_comments           => 'Client user agent'
  );

  COMMIT;
END;
/

PROMPT Brecho Express ORDS v1 public foundation installed.
