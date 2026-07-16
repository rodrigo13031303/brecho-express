CREATE OR REPLACE PACKAGE core_error_pkg AS
  SUBTYPE t_error_code       IS VARCHAR2(32);
  SUBTYPE t_category         IS VARCHAR2(30);
  SUBTYPE t_external_message IS VARCHAR2(1000);
  SUBTYPE t_severity         IS VARCHAR2(10);

  c_category_validation     CONSTANT t_category := 'VALIDATION_ERROR';
  c_category_business       CONSTANT t_category := 'BUSINESS_ERROR';
  c_category_not_found      CONSTANT t_category := 'NOT_FOUND';
  c_category_authentication CONSTANT t_category := 'AUTHENTICATION_ERROR';
  c_category_authorization  CONSTANT t_category := 'AUTHORIZATION_ERROR';
  c_category_security       CONSTANT t_category := 'SECURITY_ERROR';
  c_category_conflict       CONSTANT t_category := 'CONFLICT_ERROR';
  c_category_technical      CONSTANT t_category := 'TECHNICAL_ERROR';
  c_category_integration    CONSTANT t_category := 'INTEGRATION_ERROR';

  c_severity_info  CONSTANT t_severity := 'INFO';
  c_severity_warn  CONSTANT t_severity := 'WARN';
  c_severity_error CONSTANT t_severity := 'ERROR';
  c_severity_fatal CONSTANT t_severity := 'FATAL';

  TYPE t_public_error IS RECORD (
    code             t_error_code,
    category         t_category,
    external_message t_external_message,
    retryable        BOOLEAN,
    trace_id         core_trace_pkg.t_trace_id
  );

  TYPE t_error_policy IS RECORD (
    severity   t_severity,
    should_log BOOLEAN
  );

  e_invalid_error_code       EXCEPTION;
  e_invalid_category         EXCEPTION;
  e_invalid_severity         EXCEPTION;
  e_invalid_external_message EXCEPTION;

  FUNCTION is_valid_code(
    p_code IN t_error_code
  ) RETURN BOOLEAN;

  FUNCTION normalize_category(
    p_category IN t_category
  ) RETURN t_category;

  FUNCTION normalize_severity(
    p_severity IN t_severity
  ) RETURN t_severity;

  FUNCTION is_valid_category(
    p_category IN t_category
  ) RETURN BOOLEAN;

  FUNCTION is_valid_severity(
    p_severity IN t_severity
  ) RETURN BOOLEAN;

  PROCEDURE build_known_error(
    p_code             IN  t_error_code,
    p_category         IN  t_category,
    p_external_message IN  t_external_message,
    p_severity         IN  t_severity,
    p_retryable        IN  BOOLEAN,
    p_should_log       IN  BOOLEAN,
    o_public_error     OUT NOCOPY t_public_error,
    o_error_policy     OUT NOCOPY t_error_policy
  );

  PROCEDURE build_technical_error(
    p_code             IN  t_error_code,
    p_external_message IN  t_external_message,
    p_retryable        IN  BOOLEAN,
    o_public_error     OUT NOCOPY t_public_error,
    o_error_policy     OUT NOCOPY t_error_policy
  );
END core_error_pkg;
/
