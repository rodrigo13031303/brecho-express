WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE OFF

PROMPT ============================================================
PROMPT Installing CAT_REPOSITORY_PKG...
PROMPT ============================================================

@@cat_repository_pkg.pks
SHOW ERRORS PACKAGE CAT_REPOSITORY_PKG
@@cat_repository_pkg.pkb
SHOW ERRORS PACKAGE BODY CAT_REPOSITORY_PKG

DECLARE
  l_errors PLS_INTEGER;
BEGIN
  SELECT COUNT(*) INTO l_errors FROM USER_ERRORS
   WHERE NAME = 'CAT_REPOSITORY_PKG'
     AND TYPE IN ('PACKAGE', 'PACKAGE BODY');
  IF l_errors > 0 THEN
    RAISE_APPLICATION_ERROR(-20999, 'CAT_REPOSITORY_PKG possui erros.');
  END IF;
END;
/

PROMPT CAT_REPOSITORY_PKG installed successfully.
