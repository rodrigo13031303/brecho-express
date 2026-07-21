WHENEVER SQLERROR EXIT SQL.SQLCODE

@@pfl_rule_pkg.pks
SHOW ERRORS PACKAGE PFL_RULE_PKG

@@pfl_rule_pkg.pkb
SHOW ERRORS PACKAGE BODY PFL_RULE_PKG

DECLARE
  l_error_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO l_error_count
    FROM user_errors
   WHERE name = 'PFL_RULE_PKG'
     AND type IN ('PACKAGE', 'PACKAGE BODY');

  IF l_error_count > 0 THEN
    RAISE_APPLICATION_ERROR(
      -20999,
      'PFL_RULE_PKG possui erros de compilacao.'
    );
  END IF;
END;
/
