WHENEVER SQLERROR EXIT SQL.SQLCODE

SET DEFINE OFF

PROMPT ============================================================
PROMPT Installing STR_REPOSITORY_PKG...
PROMPT ============================================================

@@str_repository_pkg.pks
SHOW ERRORS PACKAGE STR_REPOSITORY_PKG

@@str_repository_pkg.pkb
SHOW ERRORS PACKAGE BODY STR_REPOSITORY_PKG

DECLARE
  l_error_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO l_error_count
    FROM USER_ERRORS
   WHERE NAME = 'STR_REPOSITORY_PKG'
     AND TYPE IN ('PACKAGE', 'PACKAGE BODY');

  IF l_error_count > 0 THEN
    RAISE_APPLICATION_ERROR(
      -20999,
      'STR_REPOSITORY_PKG possui erros de compilacao.'
    );
  END IF;
END;
/

PROMPT STR_REPOSITORY_PKG installed successfully.
