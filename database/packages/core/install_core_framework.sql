SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT SQL.SQLCODE

@@install_core_trace_pkg.sql
@@install_core_error_pkg.sql
@@install_core_context_pkg.sql
@@install_core_security_context_pkg.sql
@@install_core_json_pkg.sql
@@install_core_response_pkg.sql

DECLARE
  l_invalid_count PLS_INTEGER;
  l_error_count   PLS_INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO l_invalid_count
    FROM (
      SELECT 'CORE_TRACE_PKG' object_name, 'PACKAGE' object_type FROM dual
      UNION ALL
      SELECT 'CORE_TRACE_PKG', 'PACKAGE BODY' FROM dual
      UNION ALL
      SELECT 'CORE_ERROR_PKG', 'PACKAGE' FROM dual
      UNION ALL
      SELECT 'CORE_ERROR_PKG', 'PACKAGE BODY' FROM dual
      UNION ALL
      SELECT 'CORE_CONTEXT_PKG', 'PACKAGE' FROM dual
      UNION ALL
      SELECT 'CORE_CONTEXT_PKG', 'PACKAGE BODY' FROM dual
      UNION ALL
      SELECT 'CORE_SECURITY_CONTEXT_PKG', 'PACKAGE' FROM dual
      UNION ALL
      SELECT 'CORE_SECURITY_CONTEXT_PKG', 'PACKAGE BODY' FROM dual
      UNION ALL
      SELECT 'CORE_JSON_PKG', 'PACKAGE' FROM dual
      UNION ALL
      SELECT 'CORE_JSON_PKG', 'PACKAGE BODY' FROM dual
      UNION ALL
      SELECT 'CORE_RESPONSE_PKG', 'PACKAGE' FROM dual
      UNION ALL
      SELECT 'CORE_RESPONSE_PKG', 'PACKAGE BODY' FROM dual
    ) expected
    LEFT JOIN user_objects actual
      ON actual.object_name = expected.object_name
     AND actual.object_type = expected.object_type
   WHERE actual.object_name IS NULL
      OR actual.status <> 'VALID';

  SELECT COUNT(*)
    INTO l_error_count
    FROM user_errors
   WHERE name IN (
           'CORE_TRACE_PKG',
           'CORE_ERROR_PKG',
           'CORE_CONTEXT_PKG',
           'CORE_SECURITY_CONTEXT_PKG',
           'CORE_JSON_PKG',
           'CORE_RESPONSE_PKG'
         )
     AND type IN ('PACKAGE', 'PACKAGE BODY');

  IF l_invalid_count > 0 OR l_error_count > 0 THEN
    RAISE_APPLICATION_ERROR(
      -20999,
      'Core Framework possui objetos invalidos ou erros de compilacao.'
    );
  END IF;

  DBMS_OUTPUT.PUT_LINE('SUCCESS - CORE FRAMEWORK INSTALLED');
END;
/

EXIT SUCCESS
