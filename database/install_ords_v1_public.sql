SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF
SET ECHO ON
SET FEEDBACK ON
SET VERIFY OFF
SET LINESIZE 240
SET PAGESIZE 200
WHENEVER OSERROR EXIT FAILURE ROLLBACK
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

SPOOL ords_v1_public_installation.log

PROMPT ============================================================
PROMPT BRECHO EXPRESS - INSTALL ORDS V1 PUBLIC FOUNDATION
PROMPT ============================================================

@@ords/install_brecho_express_v1_public.sql
@@ords/install_brecho_express_v1_catalog_public.sql

DECLARE
  l_runtime_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO l_runtime_count
    FROM user_objects
   WHERE object_name = 'ORD_RUNTIME_PKG'
     AND object_type IN ('PACKAGE', 'PACKAGE BODY')
     AND status = 'VALID';

  IF l_runtime_count <> 2 THEN
    RAISE_APPLICATION_ERROR(
      -20999,
      'ORD runtime package was not installed correctly.'
    );
  END IF;

  DBMS_OUTPUT.PUT_LINE('SUCCESS - ORDS V1 PUBLIC FOUNDATION INSTALLED');
  DBMS_OUTPUT.PUT_LINE('Schema mapping: /ords/brechoexpress/');
  DBMS_OUTPUT.PUT_LINE('Module base path: api/v1/');
  DBMS_OUTPUT.PUT_LINE('POST accounts');
  DBMS_OUTPUT.PUT_LINE('POST auth/login');
  DBMS_OUTPUT.PUT_LINE('GET categories');
  DBMS_OUTPUT.PUT_LINE('GET products');
  DBMS_OUTPUT.PUT_LINE('GET products/{productPublicId}');
END;
/

SPOOL OFF
EXIT SUCCESS COMMIT
