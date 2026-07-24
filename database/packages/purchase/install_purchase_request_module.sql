WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE OFF
PROMPT ============================================================
PROMPT Installing PURCHASE_REQUEST module...
PROMPT ============================================================
@@install_pur_rule_pkg.sql
@@install_pur_repository_pkg.sql
@@install_pur_service_pkg.sql
@@install_pur_api_pkg.sql
PROMPT PURCHASE_REQUEST module installed successfully.
