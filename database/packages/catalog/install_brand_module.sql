WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE OFF

PROMPT ============================================================
PROMPT Installing BRAND module...
PROMPT ============================================================

@@install_brd_rule_pkg.sql
@@install_brd_repository_pkg.sql
@@install_brd_service_pkg.sql
@@install_brd_api_pkg.sql

PROMPT BRAND module installed successfully.
