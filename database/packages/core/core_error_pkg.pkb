CREATE OR REPLACE PACKAGE BODY core_error_pkg AS
  FUNCTION is_valid_code(
    p_code IN t_error_code
  ) RETURN BOOLEAN IS
  BEGIN
    RETURN p_code IS NOT NULL
       AND REGEXP_LIKE(
             p_code,
             '^BEX-[A-Z0-9]{3,20}-[0-9]{3}$',
             'c'
           );
  END is_valid_code;

  FUNCTION normalize_category(
    p_category IN t_category
  ) RETURN t_category IS
  BEGIN
    IF p_category IS NULL THEN
      RETURN NULL;
    END IF;

    RETURN UPPER(TRIM(p_category));
  END normalize_category;

  FUNCTION normalize_severity(
    p_severity IN t_severity
  ) RETURN t_severity IS
  BEGIN
    IF p_severity IS NULL THEN
      RETURN NULL;
    END IF;

    RETURN UPPER(TRIM(p_severity));
  END normalize_severity;

  FUNCTION is_valid_category(
    p_category IN t_category
  ) RETURN BOOLEAN IS
    l_category t_category;
  BEGIN
    l_category := normalize_category(p_category);

    RETURN l_category IS NOT NULL
       AND l_category IN (
             c_category_validation,
             c_category_business,
             c_category_not_found,
             c_category_authentication,
             c_category_authorization,
             c_category_security,
             c_category_conflict,
             c_category_technical,
             c_category_integration
           );
  END is_valid_category;

  FUNCTION is_valid_severity(
    p_severity IN t_severity
  ) RETURN BOOLEAN IS
    l_severity t_severity;
  BEGIN
    l_severity := normalize_severity(p_severity);

    RETURN l_severity IS NOT NULL
       AND l_severity IN (
             c_severity_info,
             c_severity_warn,
             c_severity_error,
             c_severity_fatal
           );
  END is_valid_severity;

  PROCEDURE build_known_error(
    p_code             IN  t_error_code,
    p_category         IN  t_category,
    p_external_message IN  t_external_message,
    p_severity         IN  t_severity,
    p_retryable        IN  BOOLEAN,
    p_should_log       IN  BOOLEAN,
    o_public_error     OUT NOCOPY t_public_error,
    o_error_policy     OUT NOCOPY t_error_policy
  ) IS
    l_category  t_category;
    l_severity  t_severity;
    l_has_trace BOOLEAN;
    l_trace_id  core_trace_pkg.t_trace_id;
  BEGIN
    o_public_error.code := NULL;
    o_public_error.category := NULL;
    o_public_error.external_message := NULL;
    o_public_error.retryable := NULL;
    o_public_error.trace_id := NULL;
    o_error_policy.severity := NULL;
    o_error_policy.should_log := NULL;

    l_category := normalize_category(p_category);
    l_severity := normalize_severity(p_severity);

    IF NOT is_valid_code(p_code) THEN
      RAISE e_invalid_error_code;
    END IF;

    IF NOT is_valid_category(l_category) THEN
      RAISE e_invalid_category;
    END IF;

    IF NOT is_valid_severity(l_severity) THEN
      RAISE e_invalid_severity;
    END IF;

    IF p_external_message IS NULL
       OR TRIM(p_external_message) IS NULL THEN
      RAISE e_invalid_external_message;
    END IF;

    l_has_trace := core_trace_pkg.has_trace;

    IF l_has_trace THEN
      l_trace_id := core_trace_pkg.current_trace_id;
    END IF;

    o_public_error.code := UPPER(TRIM(p_code));
    o_public_error.category := l_category;
    o_public_error.external_message := p_external_message;
    o_public_error.retryable := p_retryable;
    o_public_error.trace_id := l_trace_id;

    o_error_policy.severity := l_severity;
    o_error_policy.should_log := p_should_log;
  END build_known_error;

  PROCEDURE build_technical_error(
    p_code             IN  t_error_code,
    p_external_message IN  t_external_message,
    p_retryable        IN  BOOLEAN,
    o_public_error     OUT NOCOPY t_public_error,
    o_error_policy     OUT NOCOPY t_error_policy
  ) IS
  BEGIN
    build_known_error(
      p_code             => p_code,
      p_category         => c_category_technical,
      p_external_message => p_external_message,
      p_severity         => c_severity_error,
      p_retryable        => p_retryable,
      p_should_log       => TRUE,
      o_public_error     => o_public_error,
      o_error_policy     => o_error_policy
    );
  END build_technical_error;
END core_error_pkg;
/
