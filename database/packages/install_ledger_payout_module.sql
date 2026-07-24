WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE ON
DEFINE BEX_PACKAGE_ROOT = '&1'
PROMPT ============================================================
PROMPT Installing LEDGER AND PAYOUT module...
PROMPT ============================================================
@&BEX_PACKAGE_ROOT/purchase/ord_service_pkg.pks
@&BEX_PACKAGE_ROOT/purchase/ord_service_pkg.pkb
@&BEX_PACKAGE_ROOT/finance/sbt_rule_pkg.pks
@&BEX_PACKAGE_ROOT/finance/sbt_rule_pkg.pkb
@&BEX_PACKAGE_ROOT/finance/sbt_repository_pkg.pks
@&BEX_PACKAGE_ROOT/finance/sbt_repository_pkg.pkb
@&BEX_PACKAGE_ROOT/finance/sbt_service_pkg.pks
@&BEX_PACKAGE_ROOT/finance/sbt_service_pkg.pkb
@&BEX_PACKAGE_ROOT/finance/sbl_query_pkg.pks
@&BEX_PACKAGE_ROOT/finance/sbl_query_pkg.pkb
@&BEX_PACKAGE_ROOT/finance/sbl_api_pkg.pks
@&BEX_PACKAGE_ROOT/finance/sbl_api_pkg.pkb
@&BEX_PACKAGE_ROOT/finance/com_rule_pkg.pks
@&BEX_PACKAGE_ROOT/finance/com_rule_pkg.pkb
@&BEX_PACKAGE_ROOT/finance/com_repository_pkg.pks
@&BEX_PACKAGE_ROOT/finance/com_repository_pkg.pkb
@&BEX_PACKAGE_ROOT/finance/com_service_pkg.pks
@&BEX_PACKAGE_ROOT/finance/com_service_pkg.pkb
@&BEX_PACKAGE_ROOT/finance/pot_rule_pkg.pks
@&BEX_PACKAGE_ROOT/finance/pot_rule_pkg.pkb
@&BEX_PACKAGE_ROOT/finance/pot_repository_pkg.pks
@&BEX_PACKAGE_ROOT/finance/pot_repository_pkg.pkb
@&BEX_PACKAGE_ROOT/finance/pot_service_pkg.pks
@&BEX_PACKAGE_ROOT/finance/pot_service_pkg.pkb
@&BEX_PACKAGE_ROOT/finance/pot_api_pkg.pks
@&BEX_PACKAGE_ROOT/finance/pot_api_pkg.pkb
DECLARE n PLS_INTEGER;BEGIN SELECT COUNT(*) INTO n FROM USER_OBJECTS WHERE OBJECT_NAME IN(
  'SBT_RULE_PKG','SBT_REPOSITORY_PKG','SBT_SERVICE_PKG','SBL_QUERY_PKG','SBL_API_PKG',
  'COM_RULE_PKG','COM_REPOSITORY_PKG','COM_SERVICE_PKG',
  'POT_RULE_PKG','POT_REPOSITORY_PKG','POT_SERVICE_PKG','POT_API_PKG')
  AND OBJECT_TYPE IN('PACKAGE','PACKAGE BODY') AND STATUS='VALID';
  IF n<>24 THEN RAISE_APPLICATION_ERROR(-20999,'Ledger module possui objetos ausentes ou invalidos.');END IF;END;
/
PROMPT LEDGER AND PAYOUT module installed successfully.
UNDEFINE BEX_PACKAGE_ROOT
SET DEFINE OFF
