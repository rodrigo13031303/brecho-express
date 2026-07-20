WHENEVER SQLERROR EXIT SQL.SQLCODE

@@core_response_pkg.pks
@@core_response_pkg.pkb

SHOW ERRORS PACKAGE core_response_pkg
SHOW ERRORS PACKAGE BODY core_response_pkg

DECLARE
  l_error_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO l_error_count
    FROM user_errors
   WHERE name = 'CORE_RESPONSE_PKG'
     AND type IN ('PACKAGE', 'PACKAGE BODY');

  IF l_error_count > 0 THEN
    RAISE_APPLICATION_ERROR(
      -20999,
      'CORE_RESPONSE_PKG possui erros de compilacao.'
    );
  END IF;
END;
/
