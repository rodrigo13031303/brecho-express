WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE ON
DEFINE BEX_PACKAGE_ROOT='&1'
@&BEX_PACKAGE_ROOT/store/stp_query_pkg.pks
@&BEX_PACKAGE_ROOT/store/stp_query_pkg.pkb
@&BEX_PACKAGE_ROOT/store/stp_api_pkg.pks
@&BEX_PACKAGE_ROOT/store/stp_api_pkg.pkb
@&BEX_PACKAGE_ROOT/store/ste_rule_pkg.pks
@&BEX_PACKAGE_ROOT/store/ste_rule_pkg.pkb
@&BEX_PACKAGE_ROOT/store/ste_repository_pkg.pks
@&BEX_PACKAGE_ROOT/store/ste_repository_pkg.pkb
@&BEX_PACKAGE_ROOT/store/ste_service_pkg.pks
@&BEX_PACKAGE_ROOT/store/ste_service_pkg.pkb
@&BEX_PACKAGE_ROOT/store/ste_api_pkg.pks
@&BEX_PACKAGE_ROOT/store/ste_api_pkg.pkb
@&BEX_PACKAGE_ROOT/social/stf_rule_pkg.pks
@&BEX_PACKAGE_ROOT/social/stf_rule_pkg.pkb
@&BEX_PACKAGE_ROOT/social/stf_repository_pkg.pks
@&BEX_PACKAGE_ROOT/social/stf_repository_pkg.pkb
@&BEX_PACKAGE_ROOT/social/stf_service_pkg.pks
@&BEX_PACKAGE_ROOT/social/stf_service_pkg.pkb
@&BEX_PACKAGE_ROOT/social/stf_api_pkg.pks
@&BEX_PACKAGE_ROOT/social/stf_api_pkg.pkb
DECLARE n NUMBER;BEGIN SELECT COUNT(*)INTO n FROM USER_OBJECTS WHERE OBJECT_NAME IN(
  'STP_QUERY_PKG','STP_API_PKG','STE_RULE_PKG','STE_REPOSITORY_PKG','STE_SERVICE_PKG','STE_API_PKG',
  'STF_RULE_PKG','STF_REPOSITORY_PKG','STF_SERVICE_PKG','STF_API_PKG')
  AND OBJECT_TYPE IN('PACKAGE','PACKAGE BODY')AND STATUS='VALID';
  IF n<>20 THEN RAISE_APPLICATION_ERROR(-20999,'Store engagement possui objetos invalidos.');END IF;END;
/
UNDEFINE BEX_PACKAGE_ROOT
SET DEFINE OFF
PROMPT STORE ENGAGEMENT module installed successfully.
