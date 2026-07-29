SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF
SET ECHO ON
SET FEEDBACK ON
SET VERIFY OFF
SET LINESIZE 240
SET PAGESIZE 200
WHENEVER OSERROR EXIT FAILURE ROLLBACK
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

SPOOL ords_v1_authenticated_installation.log

PROMPT ============================================================
PROMPT BRECHO EXPRESS - INSTALL ORDS V1 AUTHENTICATED FOUNDATION
PROMPT ============================================================

@@ords/install_brecho_express_v1_authenticated.sql
@@install_store_logo_media.sql
@@install_store_location.sql
@@install_api_error_logging.sql
@@packages/catalog/install_prd_api_pkg.sql
@@install_product_image_media.sql
@@packages/store/install_store_onboarding_api_pkg.sql
@@install_cart_runtime.sql
@@packages/purchase/install_cart_module.sql
@@install_purchase_request_runtime.sql
@@packages/purchase/install_purchase_request_module.sql
@@ords/install_brecho_express_v1_seller_authenticated.sql
@@ords/install_brecho_express_v1_store_onboarding.sql
@@ords/install_brecho_express_v1_cart_authenticated.sql
@@tests/ords/test_ord_runtime_pkg.sql

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

  DBMS_OUTPUT.PUT_LINE(
    'SUCCESS - ORDS V1 AUTHENTICATED FOUNDATION INSTALLED'
  );
  DBMS_OUTPUT.PUT_LINE('POST auth/logout');
  DBMS_OUTPUT.PUT_LINE('GET/POST accounts/:accountPublicId/stores');
  DBMS_OUTPUT.PUT_LINE('POST accounts/:accountPublicId/stores/onboarding');
  DBMS_OUTPUT.PUT_LINE('POST stores/:storePublicId/actions/activate');
  DBMS_OUTPUT.PUT_LINE('POST stores/:storePublicId/products');
  DBMS_OUTPUT.PUT_LINE('GET cart');
  DBMS_OUTPUT.PUT_LINE('POST/PUT/DELETE cart/:cartPublicId/items');
  DBMS_OUTPUT.PUT_LINE('POST cart/:cartPublicId/checkout');
END;
/

SPOOL OFF
EXIT SUCCESS COMMIT
