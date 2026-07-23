WHENEVER SQLERROR EXIT SQL.SQLCODE

SET DEFINE OFF

PROMPT ============================================================
PROMPT Installing STU_REPOSITORY_PKG...
PROMPT ============================================================

DECLARE
  l_table_count PLS_INTEGER;
  l_rule_count  PLS_INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO l_table_count
    FROM USER_TABLES
   WHERE TABLE_NAME = 'BEX_STORE_USER';

  SELECT COUNT(*)
    INTO l_rule_count
    FROM USER_OBJECTS
   WHERE OBJECT_NAME = 'STU_RULE_PKG'
     AND OBJECT_TYPE = 'PACKAGE'
     AND STATUS = 'VALID';

  IF l_table_count <> 1 OR l_rule_count <> 1 THEN
    RAISE_APPLICATION_ERROR(
      -20998,
      'BEX_STORE_USER e STU_RULE_PKG devem estar validos.'
    );
  END IF;
END;
/

@@stu_repository_pkg.pks
SHOW ERRORS PACKAGE STU_REPOSITORY_PKG

@@stu_repository_pkg.pkb
SHOW ERRORS PACKAGE BODY STU_REPOSITORY_PKG

DECLARE
  l_error_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO l_error_count
    FROM USER_ERRORS
   WHERE NAME = 'STU_REPOSITORY_PKG'
     AND TYPE IN ('PACKAGE', 'PACKAGE BODY');

  IF l_error_count > 0 THEN
    RAISE_APPLICATION_ERROR(
      -20999,
      'STU_REPOSITORY_PKG possui erros de compilacao.'
    );
  END IF;
END;
/

PROMPT STU_REPOSITORY_PKG installed successfully.
