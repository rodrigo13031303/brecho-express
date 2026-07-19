WHENEVER SQLERROR EXIT SQL.SQLCODE

@@core_error_pkg.pks
@@core_error_pkg.pkb

SHOW ERRORS PACKAGE core_error_pkg
SHOW ERRORS PACKAGE BODY core_error_pkg

DECLARE
  l_error_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO l_error_count
    FROM user_errors
   WHERE name = 'CORE_ERROR_PKG'
     AND type IN ('PACKAGE', 'PACKAGE BODY');

  IF l_error_count > 0 THEN
    RAISE_APPLICATION_ERROR(
      -20999,
      'CORE_ERROR_PKG possui erros de compilacao.'
    );
  END IF;
END;
/
