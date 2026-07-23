WHENEVER SQLERROR EXIT SQL.SQLCODE

SET DEFINE OFF

PROMPT ============================================================
PROMPT Installing STU_SERVICE_PKG...
PROMPT ============================================================

@@stu_service_pkg.pks
SHOW ERRORS PACKAGE STU_SERVICE_PKG

@@stu_service_pkg.pkb
SHOW ERRORS PACKAGE BODY STU_SERVICE_PKG

DECLARE
  l_error_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO l_error_count
    FROM USER_ERRORS
   WHERE NAME = 'STU_SERVICE_PKG'
     AND TYPE IN ('PACKAGE', 'PACKAGE BODY');

  IF l_error_count > 0 THEN
    RAISE_APPLICATION_ERROR(
      -20999,
      'STU_SERVICE_PKG possui erros de compilacao.'
    );
  END IF;
END;
/

PROMPT STU_SERVICE_PKG installed successfully.
