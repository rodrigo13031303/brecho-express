SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

PROMPT ============================================================
PROMPT Testing BRAND module...
PROMPT ============================================================

@@test_bex_brand.sql
@@test_brd_rule_pkg.sql
@@test_brd_repository_pkg.sql
@@test_brd_service_pkg.sql
@@test_brd_api_pkg.sql

PROMPT BRAND module: PASSED
