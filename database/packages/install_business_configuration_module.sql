WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE ON
DEFINE BEX_PACKAGE_ROOT = '&1'
@&BEX_PACKAGE_ROOT/configuration/bcf_rule_pkg.pks
@&BEX_PACKAGE_ROOT/configuration/bcf_rule_pkg.pkb
@&BEX_PACKAGE_ROOT/configuration/bcf_repository_pkg.pks
@&BEX_PACKAGE_ROOT/configuration/bcf_repository_pkg.pkb
@&BEX_PACKAGE_ROOT/configuration/bcf_service_pkg.pks
@&BEX_PACKAGE_ROOT/configuration/bcf_service_pkg.pkb
DECLARE n NUMBER;BEGIN SELECT COUNT(*) INTO n FROM USER_OBJECTS WHERE OBJECT_NAME IN('BCF_RULE_PKG','BCF_REPOSITORY_PKG','BCF_SERVICE_PKG')
  AND OBJECT_TYPE IN('PACKAGE','PACKAGE BODY') AND STATUS='VALID';
  IF n<>6 THEN RAISE_APPLICATION_ERROR(-20999,'Business configuration possui objetos invalidos.');END IF;END;
/
UNDEFINE BEX_PACKAGE_ROOT
SET DEFINE OFF
PROMPT BUSINESS CONFIGURATION module installed successfully.
