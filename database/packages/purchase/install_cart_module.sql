WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE OFF
PROMPT ============================================================
PROMPT Installing CART module...
PROMPT ============================================================
@@install_crt_rule_pkg.sql
@@install_crt_repository_pkg.sql
@@install_crt_service_pkg.sql
@@install_crt_api_pkg.sql
PROMPT CART module installed successfully.
