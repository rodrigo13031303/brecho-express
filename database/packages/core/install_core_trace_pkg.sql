WHENEVER SQLERROR EXIT SQL.SQLCODE

@@core_trace_pkg.pks
@@core_trace_pkg.pkb

SHOW ERRORS PACKAGE core_trace_pkg
SHOW ERRORS PACKAGE BODY core_trace_pkg

DECLARE
  l_error_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO l_error_count
    FROM user_errors
   WHERE name = 'CORE_TRACE_PKG'
     AND type IN ('PACKAGE', 'PACKAGE BODY');

  IF l_error_count > 0 THEN
    RAISE_APPLICATION_ERROR(
      -20999,
      'CORE_TRACE_PKG possui erros de compilacao.'
    );
  END IF;
END;
/

EXIT SUCCESS
