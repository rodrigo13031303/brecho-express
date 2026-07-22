WHENEVER SQLERROR EXIT SQL.SQLCODE

@@pfl_repository_pkg.pks
SHOW ERRORS PACKAGE PFL_REPOSITORY_PKG

@@pfl_repository_pkg.pkb
SHOW ERRORS PACKAGE BODY PFL_REPOSITORY_PKG

DECLARE
  l_error_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO l_error_count
    FROM user_errors
   WHERE name = 'PFL_REPOSITORY_PKG'
     AND type IN ('PACKAGE', 'PACKAGE BODY');

  IF l_error_count > 0 THEN
    RAISE_APPLICATION_ERROR(
      -20999,
      'PFL_REPOSITORY_PKG possui erros de compilacao.'
    );
  END IF;
END;
/
