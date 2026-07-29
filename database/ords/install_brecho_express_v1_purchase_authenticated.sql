WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT Installing authenticated purchase request endpoints...

DECLARE
  PROCEDURE auth(p_pattern VARCHAR2,p_method VARCHAR2) IS
  BEGIN
    ORDS.DEFINE_PARAMETER(
      p_module_name=>'brecho-express-v1',p_pattern=>p_pattern,
      p_method=>p_method,p_name=>'Authorization',
      p_bind_variable_name=>'authorization',p_source_type=>'HEADER',
      p_param_type=>'STRING',p_access_method=>'IN'
    );
    ORDS.DEFINE_PARAMETER(
      p_module_name=>'brecho-express-v1',p_pattern=>p_pattern,
      p_method=>p_method,p_name=>'X-Trace-Id',
      p_bind_variable_name=>'trace_id',p_source_type=>'HEADER',
      p_param_type=>'STRING',p_access_method=>'OUT'
    );
  END;
BEGIN
  ORDS.DEFINE_TEMPLATE(
    p_module_name=>'brecho-express-v1',
    p_pattern=>'purchase-requests',p_etag_type=>'NONE'
  );
  ORDS.DEFINE_HANDLER(
    p_module_name=>'brecho-express-v1',
    p_pattern=>'purchase-requests',p_method=>'GET',
    p_source_type=>ORDS.SOURCE_TYPE_PLSQL,p_mimes_allowed=>'application/json',
    p_source=>q'~
DECLARE
  a BOOLEAN;account_id NUMBER;s VARCHAR2(32);status PLS_INTEGER;body CLOB;
BEGIN
  ord_runtime_pkg.begin_authenticated_request(
    :authorization,a,account_id,s,status,body
  );
  :trace_id:=core_context_pkg.trace_id();
  IF a THEN pur_api_pkg.list_buyer_requests(account_id,status,body);END IF;
  :status_code:=status;ord_runtime_pkg.write_json_response(body);
  ord_runtime_pkg.clear_request_context;
EXCEPTION WHEN OTHERS THEN
  ROLLBACK;ord_runtime_pkg.clear_request_context;RAISE;
END;
~'
  );
  auth('purchase-requests','GET');

  ORDS.DEFINE_TEMPLATE(
    p_module_name=>'brecho-express-v1',
    p_pattern=>'stores/:storePublicId/purchase-requests',
    p_etag_type=>'NONE'
  );
  ORDS.DEFINE_HANDLER(
    p_module_name=>'brecho-express-v1',
    p_pattern=>'stores/:storePublicId/purchase-requests',p_method=>'GET',
    p_source_type=>ORDS.SOURCE_TYPE_PLSQL,p_mimes_allowed=>'application/json',
    p_source=>q'~
DECLARE
  a BOOLEAN;account_id NUMBER;s VARCHAR2(32);status PLS_INTEGER;body CLOB;
BEGIN
  ord_runtime_pkg.begin_authenticated_request(
    :authorization,a,account_id,s,status,body
  );
  :trace_id:=core_context_pkg.trace_id();
  IF a THEN
    pur_api_pkg.list_store_requests(:storePublicId,account_id,status,body);
  END IF;
  :status_code:=status;ord_runtime_pkg.write_json_response(body);
  ord_runtime_pkg.clear_request_context;
EXCEPTION WHEN OTHERS THEN
  ROLLBACK;ord_runtime_pkg.clear_request_context;RAISE;
END;
~'
  );
  auth('stores/:storePublicId/purchase-requests','GET');

  ORDS.DEFINE_TEMPLATE(
    p_module_name=>'brecho-express-v1',
    p_pattern=>
      'stores/:storePublicId/purchase-requests/:requestPublicId/items/:itemPublicId/respond',
    p_etag_type=>'NONE'
  );
  ORDS.DEFINE_HANDLER(
    p_module_name=>'brecho-express-v1',
    p_pattern=>
      'stores/:storePublicId/purchase-requests/:requestPublicId/items/:itemPublicId/respond',
    p_method=>'POST',p_source_type=>ORDS.SOURCE_TYPE_PLSQL,
    p_mimes_allowed=>'application/json',
    p_source=>q'~
DECLARE
  a BOOLEAN;account_id NUMBER;s VARCHAR2(32);status PLS_INTEGER;body CLOB;
  request_body CLOB:=:body_text;
BEGIN
  ord_runtime_pkg.begin_authenticated_request(
    :authorization,a,account_id,s,status,body
  );
  :trace_id:=core_context_pkg.trace_id();
  IF a THEN
    pur_api_pkg.respond_item(
      :requestPublicId,:itemPublicId,:storePublicId,request_body,
      account_id,status,body
    );
  END IF;
  :status_code:=status;ord_runtime_pkg.write_json_response(body);
  ord_runtime_pkg.clear_request_context;
EXCEPTION WHEN OTHERS THEN
  ROLLBACK;ord_runtime_pkg.clear_request_context;RAISE;
END;
~'
  );
  auth(
    'stores/:storePublicId/purchase-requests/:requestPublicId/items/:itemPublicId/respond',
    'POST'
  );
  COMMIT;
END;
/

PROMPT Authenticated purchase request endpoints installed.
