WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT Installing Brecho Express ORDS v1 public catalog...

BEGIN
  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'brecho-express-v1',
    p_pattern     => 'categories',
    p_etag_type   => 'NONE',
    p_comments    => 'Public category collection'
  );

  ORDS.DEFINE_HANDLER(
    p_module_name   => 'brecho-express-v1',
    p_pattern       => 'categories',
    p_method        => 'GET',
    p_source_type   => ORDS.SOURCE_TYPE_PLSQL,
    p_mimes_allowed => 'application/json',
    p_comments      => 'List active categories',
    p_source        => q'~
DECLARE
  l_status PLS_INTEGER;
  l_body   CLOB;
BEGIN
  ord_runtime_pkg.begin_anonymous_request;
  :trace_id := core_context_pkg.trace_id();
  cat_api_pkg.list_categories(l_status, l_body);
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
    p_pattern            => 'categories',
    p_method             => 'GET',
    p_name               => 'X-Trace-Id',
    p_bind_variable_name => 'trace_id',
    p_source_type        => 'HEADER',
    p_param_type         => 'STRING',
    p_access_method      => 'OUT'
  );

  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'brecho-express-v1',
    p_pattern     => 'products',
    p_etag_type   => 'NONE',
    p_comments    => 'Public product collection'
  );

  ORDS.DEFINE_HANDLER(
    p_module_name   => 'brecho-express-v1',
    p_pattern       => 'products',
    p_method        => 'GET',
    p_source_type   => ORDS.SOURCE_TYPE_PLSQL,
    p_mimes_allowed => 'application/json',
    p_comments      => 'List active public products',
    p_source        => q'~
DECLARE
  l_status PLS_INTEGER;
  l_body   CLOB;
BEGIN
  ord_runtime_pkg.begin_anonymous_request;
  :trace_id := core_context_pkg.trace_id();
  prd_api_pkg.list_public_products(
    p_category_public_id => :category_public_id,
    p_brand_public_id    => :brand_public_id,
    p_condition          => :condition_value,
    o_status_code        => l_status,
    o_response_body      => l_body
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
    p_module_name        => 'brecho-express-v1', p_pattern => 'products',
    p_method             => 'GET', p_name => 'categoryPublicId',
    p_bind_variable_name => 'category_public_id', p_source_type => 'URI',
    p_param_type         => 'STRING', p_access_method => 'IN'
  );
  ORDS.DEFINE_PARAMETER(
    p_module_name        => 'brecho-express-v1', p_pattern => 'products',
    p_method             => 'GET', p_name => 'brandPublicId',
    p_bind_variable_name => 'brand_public_id', p_source_type => 'URI',
    p_param_type         => 'STRING', p_access_method => 'IN'
  );
  ORDS.DEFINE_PARAMETER(
    p_module_name        => 'brecho-express-v1', p_pattern => 'products',
    p_method             => 'GET', p_name => 'condition',
    p_bind_variable_name => 'condition_value', p_source_type => 'URI',
    p_param_type         => 'STRING', p_access_method => 'IN'
  );
  ORDS.DEFINE_PARAMETER(
    p_module_name        => 'brecho-express-v1', p_pattern => 'products',
    p_method             => 'GET', p_name => 'X-Trace-Id',
    p_bind_variable_name => 'trace_id', p_source_type => 'HEADER',
    p_param_type         => 'STRING', p_access_method => 'OUT'
  );

  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'brecho-express-v1',
    p_pattern     => 'products/:productPublicId',
    p_etag_type   => 'NONE',
    p_comments    => 'Public product item'
  );

  ORDS.DEFINE_HANDLER(
    p_module_name   => 'brecho-express-v1',
    p_pattern       => 'products/:productPublicId',
    p_method        => 'GET',
    p_source_type   => ORDS.SOURCE_TYPE_PLSQL,
    p_mimes_allowed => 'application/json',
    p_comments      => 'Get public product by public identifier',
    p_source        => q'~
DECLARE
  l_status PLS_INTEGER;
  l_body   CLOB;
BEGIN
  ord_runtime_pkg.begin_anonymous_request;
  :trace_id := core_context_pkg.trace_id();
  prd_api_pkg.get_product(:productPublicId, l_status, l_body);
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
    p_pattern            => 'products/:productPublicId',
    p_method             => 'GET',
    p_name               => 'X-Trace-Id',
    p_bind_variable_name => 'trace_id',
    p_source_type        => 'HEADER',
    p_param_type         => 'STRING',
    p_access_method      => 'OUT'
  );

  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'brecho-express-v1',
    p_pattern     => 'products/:productPublicId/images',
    p_etag_type   => 'NONE',
    p_comments    => 'Public product image collection'
  );

  ORDS.DEFINE_HANDLER(
    p_module_name   => 'brecho-express-v1',
    p_pattern       => 'products/:productPublicId/images',
    p_method        => 'GET',
    p_source_type   => ORDS.SOURCE_TYPE_PLSQL,
    p_mimes_allowed => 'application/json',
    p_comments      => 'List active images for a public product',
    p_source        => q'~
DECLARE
  l_status PLS_INTEGER;
  l_body   CLOB;
BEGIN
  ord_runtime_pkg.begin_anonymous_request;
  :trace_id := core_context_pkg.trace_id();
  pim_api_pkg.list_images(:productPublicId, l_status, l_body);
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
    p_pattern            => 'products/:productPublicId/images',
    p_method             => 'GET',
    p_name               => 'X-Trace-Id',
    p_bind_variable_name => 'trace_id',
    p_source_type        => 'HEADER',
    p_param_type         => 'STRING',
    p_access_method      => 'OUT'
  );
  COMMIT;
END;
/

PROMPT Brecho Express ORDS v1 public catalog installed.
