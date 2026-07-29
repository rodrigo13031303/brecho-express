SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF
SET ECHO ON
SET FEEDBACK ON
WHENEVER OSERROR EXIT FAILURE ROLLBACK
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

SPOOL order_checkout_installation.log

PROMPT ============================================================
PROMPT BRECHO EXPRESS - ORDER CHECKOUT FEATURE
PROMPT ============================================================

@@install_order_checkout_runtime.sql
@@packages/purchase/install_order_checkout_module.sql
@@packages/purchase/install_order_tracking_module.sql
@@ords/install_brecho_express_v1_order_checkout_authenticated.sql
@@ords/install_brecho_express_v1_order_tracking_authenticated.sql

DECLARE
  l_invalid_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*) INTO l_invalid_count FROM USER_OBJECTS
  WHERE OBJECT_NAME IN('OCH_API_PKG','OTR_API_PKG') AND STATUS<>'VALID';
  IF l_invalid_count>0 THEN
    RAISE_APPLICATION_ERROR(-20999,'Order checkout API was not installed correctly.');
  END IF;
  DBMS_OUTPUT.PUT_LINE('SUCCESS - ORDER CHECKOUT FEATURE INSTALLED');
END;
/

SPOOL OFF
EXIT SUCCESS COMMIT
