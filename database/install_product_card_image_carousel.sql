SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

PROMPT ============================================================
PROMPT BRECHO EXPRESS - PRODUCT CARD IMAGE CAROUSEL
PROMPT Execute from the database directory.
PROMPT ============================================================

@@packages/catalog/prd_repository_pkg.pks
@@packages/catalog/prd_repository_pkg.pkb
@@packages/catalog/prd_service_pkg.pks
@@packages/catalog/prd_service_pkg.pkb
@@packages/catalog/prd_api_pkg.pkb

BEGIN
  DBMS_UTILITY.COMPILE_SCHEMA(USER,FALSE);
END;
/

DECLARE
  l_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*) INTO l_count
    FROM USER_OBJECTS
   WHERE OBJECT_NAME IN (
     'PRD_REPOSITORY_PKG','PRD_SERVICE_PKG','PRD_API_PKG'
   )
     AND OBJECT_TYPE IN ('PACKAGE','PACKAGE BODY')
     AND STATUS <> 'VALID';
  IF l_count <> 0 THEN
    RAISE_APPLICATION_ERROR(-20999,'Catalog carousel packages invalid.');
  END IF;
END;
/

@@tests/catalog/test_prd_api_pkg.sql

PROMPT Product card image carousel installed successfully.
