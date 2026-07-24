WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE OFF
PROMPT ============================================================
PROMPT Installing initial PURCHASE module...
PROMPT ============================================================
@@..\catalog\install_prd_service_pkg.sql
DECLARE
  l_contract_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*) INTO l_contract_count
    FROM USER_SOURCE
   WHERE NAME='PRD_SERVICE_PKG'
     AND TYPE='PACKAGE'
     AND UPPER(TEXT) LIKE '%RESOLVE_AVAILABLE_PRODUCT%';
  IF l_contract_count=0 THEN
    RAISE_APPLICATION_ERROR(
      -20999,
      'PRD_SERVICE_PKG nao expoe o contrato exigido pela Compra.'
    );
  END IF;
END;
/
@@install_cart_module.sql
@@install_purchase_request_module.sql
PROMPT Initial PURCHASE module installed successfully.
