WHENEVER SQLERROR EXIT SQL.SQLCODE

SET DEFINE OFF

PROMPT ============================================================
PROMPT Installing STORE module...
PROMPT ============================================================

@@install_str_rule_pkg.sql
@@install_str_repository_pkg.sql

@@install_stu_rule.sql
@@install_stu_repository_pkg.sql
@@install_stu_service_pkg.sql

@@install_str_service_pkg.sql
@@install_str_api_pkg.sql

PROMPT STORE module installed successfully.
