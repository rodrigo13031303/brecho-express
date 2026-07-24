WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE OFF

PROMPT ============================================================
PROMPT Installing PRODUCT module...
PROMPT ============================================================

@@install_prd_rule_pkg.sql
@@install_prd_repository_pkg.sql
@@install_prd_service_pkg.sql
@@install_prd_api_pkg.sql

PROMPT PRODUCT module installed successfully.
