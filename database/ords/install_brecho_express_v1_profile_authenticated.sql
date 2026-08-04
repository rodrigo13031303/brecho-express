SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

BEGIN
  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'me/profile',
    p_etag_type => 'NONE',
    p_comments => 'Authenticated profile summary for the current account'
  );
  ORDS.DEFINE_HANDLER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'me/profile',
    p_method => 'GET',
    p_source_type => ORDS.SOURCE_TYPE_PLSQL,
    p_source => q'~
DECLARE
  l_authenticated BOOLEAN;
  l_account_id NUMBER;
  l_session_public_id VARCHAR2(32);
  l_status PLS_INTEGER;
  l_body CLOB;
BEGIN
  ord_runtime_pkg.begin_authenticated_request(
    :authorization, l_authenticated, l_account_id, l_session_public_id,
    l_status, l_body
  );
  IF l_authenticated THEN
    pfl_api_pkg.get_my_profile(l_account_id, l_status, l_body);
  END IF;
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
    p_module_name => 'brecho-express-v1',
    p_pattern => 'me/profile',
    p_method => 'GET',
    p_name => 'Authorization',
    p_bind_variable_name => 'authorization',
    p_source_type => 'HEADER',
    p_param_type => 'STRING',
    p_access_method => 'IN'
  );
  COMMIT;
END;
/

PROMPT SUCCESS - GET me/profile installed
