WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT Installing Brecho Express ORDS v1 authenticated foundation...

@@install_ord_runtime_pkg.sql

BEGIN
  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'brecho-express-v1',
    p_pattern     => 'auth/logout',
    p_etag_type   => 'NONE',
    p_comments    => 'Authentication logout'
  );

  ORDS.DEFINE_HANDLER(
    p_module_name   => 'brecho-express-v1',
    p_pattern       => 'auth/logout',
    p_method        => 'POST',
    p_source_type   => ORDS.SOURCE_TYPE_PLSQL,
    p_mimes_allowed => 'application/json',
    p_comments      => 'Revoke current authenticated session',
    p_source        => q'~
DECLARE
  l_authenticated     BOOLEAN;
  l_account_id        NUMBER;
  l_session_public_id VARCHAR2(32);
  l_status            PLS_INTEGER;
  l_body              CLOB;
BEGIN
  ord_runtime_pkg.begin_authenticated_request(
    p_authorization     => :authorization,
    o_authenticated     => l_authenticated,
    o_account_id        => l_account_id,
    o_session_public_id => l_session_public_id,
    o_status_code       => l_status,
    o_response_body     => l_body
  );
  :trace_id := core_context_pkg.trace_id();

  IF l_authenticated THEN
    acc_auth_api_pkg.logout(
      p_session_public_id => l_session_public_id,
      p_actor_id          => l_account_id,
      o_status_code       => l_status,
      o_response_body     => l_body
    );
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
    p_module_name        => 'brecho-express-v1',
    p_pattern            => 'auth/logout',
    p_method             => 'POST',
    p_name               => 'Authorization',
    p_bind_variable_name => 'authorization',
    p_source_type        => 'HEADER',
    p_param_type         => 'STRING',
    p_access_method      => 'IN',
    p_comments           => 'Bearer session token'
  );

  ORDS.DEFINE_PARAMETER(
    p_module_name        => 'brecho-express-v1',
    p_pattern            => 'auth/logout',
    p_method             => 'POST',
    p_name               => 'X-Trace-Id',
    p_bind_variable_name => 'trace_id',
    p_source_type        => 'HEADER',
    p_param_type         => 'STRING',
    p_access_method      => 'OUT',
    p_comments           => 'Core trace identifier'
  );

  COMMIT;
END;
/

PROMPT Brecho Express ORDS v1 authenticated foundation installed.
