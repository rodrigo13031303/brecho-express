WHENEVER SQLERROR EXIT SQL.SQLCODE

SET DEFINE OFF

PROMPT ============================================================
PROMPT Installing STU_RULE_PKG...
PROMPT ============================================================

@@stu_rule_pkg.sql
SHOW ERRORS PACKAGE STU_RULE_PKG
SHOW ERRORS PACKAGE BODY STU_RULE_PKG

DECLARE
  l_error_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO l_error_count
    FROM USER_ERRORS
   WHERE NAME = 'STU_RULE_PKG'
     AND TYPE IN ('PACKAGE', 'PACKAGE BODY');

  IF l_error_count > 0 THEN
    RAISE_APPLICATION_ERROR(
      -20999,
      'STU_RULE_PKG possui erros de compilacao.'
    );
  END IF;
END;
/

PROMPT STU_RULE_PKG installed successfully.
