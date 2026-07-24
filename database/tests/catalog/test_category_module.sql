SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

PROMPT ============================================================
PROMPT Testing CATEGORY module...
PROMPT ============================================================

@@test_bex_category.sql
@@test_cat_rule_pkg.sql
@@test_cat_repository_pkg.sql
@@test_cat_service_pkg.sql
@@test_cat_api_pkg.sql

PROMPT CATEGORY module: PASSED
