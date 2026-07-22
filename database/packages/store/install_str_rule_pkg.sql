WHENEVER SQLERROR EXIT SQL.SQLCODE

SET DEFINE OFF

PROMPT ============================================================
PROMPT Installing STR_RULE_PKG...
PROMPT ============================================================

@@str_rule_pkg.pks
SHOW ERRORS PACKAGE STR_RULE_PKG

@@str_rule_pkg.pkb
SHOW ERRORS PACKAGE BODY STR_RULE_PKG

DECLARE
  l_error_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO l_error_count
    FROM USER_ERRORS
   WHERE NAME = 'STR_RULE_PKG'
     AND TYPE IN ('PACKAGE', 'PACKAGE BODY');

  IF l_error_count > 0 THEN
    RAISE_APPLICATION_ERROR(-20999, 'STR_RULE_PKG possui erros de compilacao.');
  END IF;
END;
/

PROMPT STR_RULE_PKG installed successfully.
