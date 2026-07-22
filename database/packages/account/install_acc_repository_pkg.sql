WHENEVER SQLERROR EXIT SQL.SQLCODE

SET DEFINE OFF

PROMPT ============================================================
PROMPT Installing ACC_REPOSITORY_PKG...
PROMPT ============================================================

@@acc_repository_pkg.pks
SHOW ERRORS PACKAGE ACC_REPOSITORY_PKG

@@acc_repository_pkg.pkb
SHOW ERRORS PACKAGE BODY ACC_REPOSITORY_PKG

DECLARE
  l_error_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO l_error_count
    FROM USER_ERRORS
   WHERE NAME = 'ACC_REPOSITORY_PKG'
     AND TYPE IN ('PACKAGE', 'PACKAGE BODY');

  IF l_error_count > 0 THEN
    RAISE_APPLICATION_ERROR(
      -20999,
      'ACC_REPOSITORY_PKG possui erros de compilacao.'
    );
  END IF;
END;
/

PROMPT ACC_REPOSITORY_PKG installed successfully.
