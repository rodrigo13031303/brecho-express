WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE OFF
SET DEFINE ON
DEFINE BEX_PACKAGE_ROOT = '&1'
PROMPT ============================================================
PROMPT Installing ORDER AND LOGISTICS module...
PROMPT ============================================================
@&BEX_PACKAGE_ROOT/identity/adr_rule_pkg.pks
@&BEX_PACKAGE_ROOT/identity/adr_rule_pkg.pkb
@&BEX_PACKAGE_ROOT/identity/adr_repository_pkg.pks
@&BEX_PACKAGE_ROOT/identity/adr_repository_pkg.pkb
@&BEX_PACKAGE_ROOT/identity/adr_service_pkg.pks
@&BEX_PACKAGE_ROOT/identity/adr_service_pkg.pkb
@&BEX_PACKAGE_ROOT/identity/adr_api_pkg.pks
@&BEX_PACKAGE_ROOT/identity/adr_api_pkg.pkb
@&BEX_PACKAGE_ROOT/logistics/dlp_rule_pkg.pks
@&BEX_PACKAGE_ROOT/logistics/dlp_rule_pkg.pkb
@&BEX_PACKAGE_ROOT/logistics/dlp_repository_pkg.pks
@&BEX_PACKAGE_ROOT/logistics/dlp_repository_pkg.pkb
@&BEX_PACKAGE_ROOT/logistics/dlp_service_pkg.pks
@&BEX_PACKAGE_ROOT/logistics/dlp_service_pkg.pkb
@&BEX_PACKAGE_ROOT/logistics/dlp_api_pkg.pks
@&BEX_PACKAGE_ROOT/logistics/dlp_api_pkg.pkb
@&BEX_PACKAGE_ROOT/purchase/pur_service_pkg.pks
@&BEX_PACKAGE_ROOT/purchase/pur_service_pkg.pkb
@&BEX_PACKAGE_ROOT/purchase/ord_rule_pkg.pks
@&BEX_PACKAGE_ROOT/purchase/ord_rule_pkg.pkb
@&BEX_PACKAGE_ROOT/purchase/ord_repository_pkg.pks
@&BEX_PACKAGE_ROOT/purchase/ord_repository_pkg.pkb
@&BEX_PACKAGE_ROOT/purchase/ord_service_pkg.pks
@&BEX_PACKAGE_ROOT/purchase/ord_service_pkg.pkb
@&BEX_PACKAGE_ROOT/purchase/ord_api_pkg.pks
@&BEX_PACKAGE_ROOT/purchase/ord_api_pkg.pkb
@&BEX_PACKAGE_ROOT/logistics/shp_rule_pkg.pks
@&BEX_PACKAGE_ROOT/logistics/shp_rule_pkg.pkb
@&BEX_PACKAGE_ROOT/logistics/shp_repository_pkg.pks
@&BEX_PACKAGE_ROOT/logistics/shp_repository_pkg.pkb
@&BEX_PACKAGE_ROOT/logistics/shp_service_pkg.pks
@&BEX_PACKAGE_ROOT/logistics/shp_service_pkg.pkb
@&BEX_PACKAGE_ROOT/logistics/shp_api_pkg.pks
@&BEX_PACKAGE_ROOT/logistics/shp_api_pkg.pkb
DECLARE
  n PLS_INTEGER;
BEGIN
  SELECT COUNT(*) INTO n FROM USER_OBJECTS WHERE OBJECT_NAME IN(
    'ADR_RULE_PKG','ADR_REPOSITORY_PKG','ADR_SERVICE_PKG','ADR_API_PKG',
    'DLP_RULE_PKG','DLP_REPOSITORY_PKG','DLP_SERVICE_PKG','DLP_API_PKG',
    'ORD_RULE_PKG','ORD_REPOSITORY_PKG','ORD_SERVICE_PKG','ORD_API_PKG',
    'SHP_RULE_PKG','SHP_REPOSITORY_PKG','SHP_SERVICE_PKG','SHP_API_PKG')
    AND OBJECT_TYPE IN('PACKAGE','PACKAGE BODY') AND STATUS='VALID';
  IF n<>32 THEN RAISE_APPLICATION_ERROR(-20999,'Modulo possui objetos ausentes ou invalidos.');END IF;
  SELECT COUNT(*) INTO n FROM USER_ERRORS WHERE NAME IN(
    'ADR_RULE_PKG','ADR_REPOSITORY_PKG','ADR_SERVICE_PKG','ADR_API_PKG',
    'DLP_RULE_PKG','DLP_REPOSITORY_PKG','DLP_SERVICE_PKG','DLP_API_PKG',
    'ORD_RULE_PKG','ORD_REPOSITORY_PKG','ORD_SERVICE_PKG','ORD_API_PKG',
    'SHP_RULE_PKG','SHP_REPOSITORY_PKG','SHP_SERVICE_PKG','SHP_API_PKG',
    'PUR_SERVICE_PKG');
  IF n>0 THEN RAISE_APPLICATION_ERROR(-20999,'Modulo possui erros de compilacao.');END IF;
END;
/
PROMPT ORDER AND LOGISTICS module installed successfully.
UNDEFINE BEX_PACKAGE_ROOT
SET DEFINE OFF
