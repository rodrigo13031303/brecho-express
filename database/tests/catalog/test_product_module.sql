SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

PROMPT ============================================================
PROMPT Testing PRODUCT module...
PROMPT ============================================================

@@test_bex_product.sql
@@test_bex_product_image.sql
@@test_bex_product_question.sql
@@test_prd_rule_pkg.sql
@@test_prd_repository_pkg.sql
@@test_prd_service_pkg.sql
@@test_prd_api_pkg.sql

PROMPT PRODUCT module: PASSED
