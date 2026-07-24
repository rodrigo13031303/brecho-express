WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE OFF

PROMPT ============================================================
PROMPT Installing CATEGORY module...
PROMPT ============================================================

@@install_cat_rule_pkg.sql
@@install_cat_repository_pkg.sql
@@install_cat_service_pkg.sql
@@install_cat_api_pkg.sql

PROMPT CATEGORY module installed successfully.
