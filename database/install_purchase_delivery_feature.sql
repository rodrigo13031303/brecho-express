SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF
SET ECHO ON
SET FEEDBACK ON
WHENEVER OSERROR EXIT FAILURE ROLLBACK
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

SPOOL purchase_delivery_installation.log

PROMPT ============================================================
PROMPT BRECHO EXPRESS - PURCHASE DELIVERY FEATURE
PROMPT ============================================================

@@packages/identity/adr_api_pkg.pkb
@@install_purchase_delivery_runtime.sql
@@packages/purchase/install_delivery_module.sql
@@ords/install_brecho_express_v1_delivery_authenticated.sql

DECLARE
  l_invalid_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*) INTO l_invalid_count
  FROM USER_OBJECTS
  WHERE OBJECT_NAME IN('ADR_API_PKG','PDL_SERVICE_PKG','PDL_API_PKG')
    AND STATUS<>'VALID';

  IF l_invalid_count>0 THEN
    RAISE_APPLICATION_ERROR(
      -20999,
      'Purchase delivery packages were not installed correctly.'
    );
  END IF;

  DBMS_OUTPUT.PUT_LINE('SUCCESS - PURCHASE DELIVERY FEATURE INSTALLED');
  DBMS_OUTPUT.PUT_LINE('GET/POST addresses');
  DBMS_OUTPUT.PUT_LINE('GET/PUT purchase-requests/:id/delivery-address');
END;
/

SPOOL OFF
EXIT SUCCESS COMMIT
