WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE ON
DEFINE BEX_PACKAGE_ROOT = '&1'
PROMPT ============================================================
PROMPT Installing PAYMENT module...
PROMPT ============================================================
@&BEX_PACKAGE_ROOT/purchase/pur_service_pkg.pks
@&BEX_PACKAGE_ROOT/purchase/pur_service_pkg.pkb
@&BEX_PACKAGE_ROOT/finance/ppr_rule_pkg.pks
@&BEX_PACKAGE_ROOT/finance/ppr_rule_pkg.pkb
@&BEX_PACKAGE_ROOT/finance/ppr_repository_pkg.pks
@&BEX_PACKAGE_ROOT/finance/ppr_repository_pkg.pkb
@&BEX_PACKAGE_ROOT/finance/ppr_service_pkg.pks
@&BEX_PACKAGE_ROOT/finance/ppr_service_pkg.pkb
@&BEX_PACKAGE_ROOT/finance/ppr_api_pkg.pks
@&BEX_PACKAGE_ROOT/finance/ppr_api_pkg.pkb
@&BEX_PACKAGE_ROOT/finance/pay_rule_pkg.pks
@&BEX_PACKAGE_ROOT/finance/pay_rule_pkg.pkb
@&BEX_PACKAGE_ROOT/finance/pay_repository_pkg.pks
@&BEX_PACKAGE_ROOT/finance/pay_repository_pkg.pkb
@&BEX_PACKAGE_ROOT/finance/pay_service_pkg.pks
@&BEX_PACKAGE_ROOT/finance/pay_service_pkg.pkb
@&BEX_PACKAGE_ROOT/finance/pay_api_pkg.pks
@&BEX_PACKAGE_ROOT/finance/pay_api_pkg.pkb
@&BEX_PACKAGE_ROOT/finance/pev_rule_pkg.pks
@&BEX_PACKAGE_ROOT/finance/pev_rule_pkg.pkb
@&BEX_PACKAGE_ROOT/finance/pev_repository_pkg.pks
@&BEX_PACKAGE_ROOT/finance/pev_repository_pkg.pkb
@&BEX_PACKAGE_ROOT/finance/pev_service_pkg.pks
@&BEX_PACKAGE_ROOT/finance/pev_service_pkg.pkb
@&BEX_PACKAGE_ROOT/finance/pev_api_pkg.pks
@&BEX_PACKAGE_ROOT/finance/pev_api_pkg.pkb
DECLARE n PLS_INTEGER;BEGIN SELECT COUNT(*) INTO n FROM USER_OBJECTS WHERE OBJECT_NAME IN(
  'PPR_RULE_PKG','PPR_REPOSITORY_PKG','PPR_SERVICE_PKG','PPR_API_PKG',
  'PAY_RULE_PKG','PAY_REPOSITORY_PKG','PAY_SERVICE_PKG','PAY_API_PKG',
  'PEV_RULE_PKG','PEV_REPOSITORY_PKG','PEV_SERVICE_PKG','PEV_API_PKG')
  AND OBJECT_TYPE IN('PACKAGE','PACKAGE BODY') AND STATUS='VALID';
  IF n<>24 THEN RAISE_APPLICATION_ERROR(-20999,'PAYMENT module possui objetos ausentes ou invalidos.');END IF;END;
/
PROMPT PAYMENT module installed successfully.
UNDEFINE BEX_PACKAGE_ROOT
SET DEFINE OFF
