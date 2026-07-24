WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE OFF

PROMPT ============================================================
PROMPT Installing CAT_SERVICE_PKG...
PROMPT ============================================================

@@cat_service_pkg.pks
SHOW ERRORS PACKAGE CAT_SERVICE_PKG
@@cat_service_pkg.pkb
SHOW ERRORS PACKAGE BODY CAT_SERVICE_PKG

DECLARE
  l_errors PLS_INTEGER;
BEGIN
  SELECT COUNT(*) INTO l_errors FROM USER_ERRORS
   WHERE NAME = 'CAT_SERVICE_PKG'
     AND TYPE IN ('PACKAGE', 'PACKAGE BODY');
  IF l_errors > 0 THEN
    RAISE_APPLICATION_ERROR(-20999, 'CAT_SERVICE_PKG possui erros.');
  END IF;
END;
/

PROMPT CAT_SERVICE_PKG installed successfully.
