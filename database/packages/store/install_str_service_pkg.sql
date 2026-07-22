WHENEVER SQLERROR EXIT SQL.SQLCODE

SET DEFINE OFF

PROMPT ============================================================
PROMPT Installing STR_SERVICE_PKG...
PROMPT ============================================================

@@str_service_pkg.pks
SHOW ERRORS PACKAGE STR_SERVICE_PKG

@@str_service_pkg.pkb
SHOW ERRORS PACKAGE BODY STR_SERVICE_PKG

DECLARE
  l_error_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO l_error_count
    FROM USER_ERRORS
   WHERE NAME = 'STR_SERVICE_PKG'
     AND TYPE IN ('PACKAGE', 'PACKAGE BODY');

  IF l_error_count > 0 THEN
    RAISE_APPLICATION_ERROR(
      -20999,
      'STR_SERVICE_PKG possui erros de compilacao.'
    );
  END IF;
END;
/

PROMPT STR_SERVICE_PKG installed successfully.
