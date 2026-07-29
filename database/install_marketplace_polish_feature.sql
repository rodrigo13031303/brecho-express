SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF
SET ECHO ON
SET FEEDBACK ON
WHENEVER OSERROR EXIT FAILURE ROLLBACK
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

SPOOL marketplace_polish_installation.log

PROMPT ============================================================
PROMPT BRECHO EXPRESS - MARKETPLACE POLISH FEATURE
PROMPT ============================================================

UPDATE BEX_PURCHASE_REQUEST
   SET PUR_EXPIRES_AT = PUR_REQUESTED_AT + INTERVAL '5' MINUTE,
       PUR_UPDATED_AT = SYSTIMESTAMP
 WHERE PUR_STATUS = 'PENDING'
   AND (
     PUR_EXPIRES_AT IS NULL OR
     PUR_EXPIRES_AT > PUR_REQUESTED_AT + INTERVAL '5' MINUTE
   );
COMMIT;

@@packages/purchase/install_pur_service_pkg.sql
@@ords/install_brecho_express_v1_product_management_authenticated.sql

DECLARE
  l_invalid_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*) INTO l_invalid_count
    FROM USER_OBJECTS
   WHERE OBJECT_NAME IN('PUR_SERVICE_PKG')
     AND STATUS <> 'VALID';
  IF l_invalid_count > 0 THEN
    RAISE_APPLICATION_ERROR(
      -20999,
      'Marketplace polish feature was not installed correctly.'
    );
  END IF;
  DBMS_OUTPUT.PUT_LINE('SUCCESS - MARKETPLACE POLISH FEATURE INSTALLED');
END;
/

SPOOL OFF
EXIT SUCCESS COMMIT
