WHENEVER SQLERROR EXIT SQL.SQLCODE

SET DEFINE OFF

PROMPT ============================================================
PROMPT Installing ACC_API_PKG...
PROMPT ============================================================

@@acc_api_pkg.pks
SHOW ERRORS PACKAGE ACC_API_PKG

@@acc_api_pkg.pkb
SHOW ERRORS PACKAGE BODY ACC_API_PKG

DECLARE
  l_error_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO l_error_count
    FROM user_errors
   WHERE name = 'ACC_API_PKG'
     AND type IN ('PACKAGE', 'PACKAGE BODY');

  IF l_error_count > 0 THEN
    RAISE_APPLICATION_ERROR(
      -20999,
      'ACC_API_PKG possui erros de compilacao.'
    );
  END IF;
END;
/

PROMPT ACC_API_PKG installed successfully.
