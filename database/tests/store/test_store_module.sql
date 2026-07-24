SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

PROMPT ============================================================
PROMPT Testing STORE module...
PROMPT ============================================================

@@test_bex_store.sql
@@test_bex_store_user.sql

@@test_str_rule_pkg.sql
@@test_str_repository_pkg.sql

@@test_stu_rule.sql
@@test_stu_repository_pkg.sql
@@test_stu_service_pkg.sql

@@test_str_service_pkg.sql
@@test_str_api_pkg.sql

PROMPT STORE module: PASSED
