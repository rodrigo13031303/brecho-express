WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
SET DEFINE OFF

@@ord_runtime_pkg.pks
@@ord_runtime_pkg.pkb

SHOW ERRORS PACKAGE ord_runtime_pkg
SHOW ERRORS PACKAGE BODY ord_runtime_pkg

DECLARE
  l_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO l_count
    FROM user_objects
   WHERE object_name = 'ORD_RUNTIME_PKG'
     AND object_type IN ('PACKAGE', 'PACKAGE BODY')
     AND status = 'VALID';

  IF l_count <> 2 THEN
    RAISE_APPLICATION_ERROR(-20999, 'ORD_RUNTIME_PKG invalido.');
  END IF;
END;
/
