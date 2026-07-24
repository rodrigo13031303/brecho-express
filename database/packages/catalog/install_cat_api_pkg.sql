WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE OFF

PROMPT ============================================================
PROMPT Installing CAT_API_PKG...
PROMPT ============================================================

@@cat_api_pkg.pks
SHOW ERRORS PACKAGE CAT_API_PKG
@@cat_api_pkg.pkb
SHOW ERRORS PACKAGE BODY CAT_API_PKG

DECLARE
  l_errors PLS_INTEGER;
BEGIN
  SELECT COUNT(*) INTO l_errors FROM USER_ERRORS
   WHERE NAME='CAT_API_PKG' AND TYPE IN ('PACKAGE','PACKAGE BODY');
  IF l_errors>0 THEN
    RAISE_APPLICATION_ERROR(-20999,'CAT_API_PKG possui erros.');
  END IF;
END;
/

PROMPT CAT_API_PKG installed successfully.
