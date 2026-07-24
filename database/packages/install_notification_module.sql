WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE ON
DEFINE BEX_PACKAGE_ROOT = '&1'
@&BEX_PACKAGE_ROOT/notification/ntf_rule_pkg.pks
@&BEX_PACKAGE_ROOT/notification/ntf_rule_pkg.pkb
@&BEX_PACKAGE_ROOT/notification/ntf_repository_pkg.pks
@&BEX_PACKAGE_ROOT/notification/ntf_repository_pkg.pkb
@&BEX_PACKAGE_ROOT/notification/ntf_service_pkg.pks
@&BEX_PACKAGE_ROOT/notification/ntf_service_pkg.pkb
UNDEFINE BEX_PACKAGE_ROOT
SET DEFINE OFF
PROMPT NOTIFICATION module installed successfully.
