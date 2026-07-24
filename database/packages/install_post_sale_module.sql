WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE ON
DEFINE BEX_PACKAGE_ROOT = '&1'
DEFINE BEX_DATABASE_ROOT = '&2'
PROMPT Installing POST-SALE module...
@&BEX_PACKAGE_ROOT/purchase/ord_service_pkg.pks
@&BEX_PACKAGE_ROOT/purchase/ord_service_pkg.pkb
@&BEX_PACKAGE_ROOT/post_sale/rrq_rule_pkg.pks
@&BEX_PACKAGE_ROOT/post_sale/rrq_rule_pkg.pkb
@&BEX_PACKAGE_ROOT/post_sale/rrq_repository_pkg.pks
@&BEX_PACKAGE_ROOT/post_sale/rrq_repository_pkg.pkb
@&BEX_PACKAGE_ROOT/post_sale/rrq_service_pkg.pks
@&BEX_PACKAGE_ROOT/post_sale/rrq_service_pkg.pkb
@&BEX_PACKAGE_ROOT/post_sale/rrq_api_pkg.pks
@&BEX_PACKAGE_ROOT/post_sale/rrq_api_pkg.pkb
@&BEX_PACKAGE_ROOT/post_sale/rat_rule_pkg.pks
@&BEX_PACKAGE_ROOT/post_sale/rat_rule_pkg.pkb
@&BEX_PACKAGE_ROOT/post_sale/rat_repository_pkg.pks
@&BEX_PACKAGE_ROOT/post_sale/rat_repository_pkg.pkb
@&BEX_PACKAGE_ROOT/post_sale/rat_service_pkg.pks
@&BEX_PACKAGE_ROOT/post_sale/rat_service_pkg.pkb
@&BEX_PACKAGE_ROOT/post_sale/rat_api_pkg.pks
@&BEX_PACKAGE_ROOT/post_sale/rat_api_pkg.pkb
@&BEX_PACKAGE_ROOT/post_sale/srv_rule_pkg.pks
@&BEX_PACKAGE_ROOT/post_sale/srv_rule_pkg.pkb
@&BEX_PACKAGE_ROOT/post_sale/srv_repository_pkg.pks
@&BEX_PACKAGE_ROOT/post_sale/srv_repository_pkg.pkb
@&BEX_PACKAGE_ROOT/post_sale/srv_service_pkg.pks
@&BEX_PACKAGE_ROOT/post_sale/srv_service_pkg.pkb
@&BEX_PACKAGE_ROOT/post_sale/srv_api_pkg.pks
@&BEX_PACKAGE_ROOT/post_sale/srv_api_pkg.pkb
@&BEX_DATABASE_ROOT/views/post_sale/bex_store_reputation.sql
@&BEX_PACKAGE_ROOT/post_sale/srp_query_pkg.pks
@&BEX_PACKAGE_ROOT/post_sale/srp_query_pkg.pkb
@&BEX_PACKAGE_ROOT/post_sale/srp_api_pkg.pks
@&BEX_PACKAGE_ROOT/post_sale/srp_api_pkg.pkb
DECLARE n PLS_INTEGER;BEGIN SELECT COUNT(*) INTO n FROM USER_OBJECTS WHERE OBJECT_NAME IN(
  'RRQ_RULE_PKG','RRQ_REPOSITORY_PKG','RRQ_SERVICE_PKG','RRQ_API_PKG',
  'RAT_RULE_PKG','RAT_REPOSITORY_PKG','RAT_SERVICE_PKG','RAT_API_PKG',
  'SRV_RULE_PKG','SRV_REPOSITORY_PKG','SRV_SERVICE_PKG','SRV_API_PKG','SRP_QUERY_PKG','SRP_API_PKG')
  AND OBJECT_TYPE IN('PACKAGE','PACKAGE BODY')AND STATUS='VALID';
  IF n<>28 THEN RAISE_APPLICATION_ERROR(-20999,'Post-sale possui objetos ausentes ou invalidos.');END IF;END;
/
PROMPT POST-SALE module installed successfully.
UNDEFINE BEX_PACKAGE_ROOT
UNDEFINE BEX_DATABASE_ROOT
SET DEFINE OFF
