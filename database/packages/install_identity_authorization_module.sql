WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE ON
DEFINE BEX_PACKAGE_ROOT = '&1'
@&BEX_PACKAGE_ROOT/identity/rol_query_pkg.pks
@&BEX_PACKAGE_ROOT/identity/rol_query_pkg.pkb
@&BEX_PACKAGE_ROOT/identity/prl_rule_pkg.pks
@&BEX_PACKAGE_ROOT/identity/prl_rule_pkg.pkb
@&BEX_PACKAGE_ROOT/identity/prl_repository_pkg.pks
@&BEX_PACKAGE_ROOT/identity/prl_repository_pkg.pkb
@&BEX_PACKAGE_ROOT/identity/prl_service_pkg.pks
@&BEX_PACKAGE_ROOT/identity/prl_service_pkg.pkb
@&BEX_PACKAGE_ROOT/identity/iam_authorization_pkg.pks
@&BEX_PACKAGE_ROOT/identity/iam_authorization_pkg.pkb
DECLARE n NUMBER;BEGIN SELECT COUNT(*)INTO n FROM USER_OBJECTS WHERE OBJECT_NAME IN(
  'ROL_QUERY_PKG','PRL_RULE_PKG','PRL_REPOSITORY_PKG','PRL_SERVICE_PKG','IAM_AUTHORIZATION_PKG')
  AND OBJECT_TYPE IN('PACKAGE','PACKAGE BODY')AND STATUS='VALID';
  IF n<>10 THEN RAISE_APPLICATION_ERROR(-20999,'Identity authorization possui objetos invalidos.');END IF;END;
/
UNDEFINE BEX_PACKAGE_ROOT
SET DEFINE OFF
PROMPT IDENTITY AUTHORIZATION module installed successfully.
