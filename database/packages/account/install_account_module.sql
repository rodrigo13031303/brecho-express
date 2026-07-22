WHENEVER SQLERROR EXIT SQL.SQLCODE

SET DEFINE OFF

PROMPT ============================================================
PROMPT Installing ACCOUNT module...
PROMPT ============================================================

@@install_acc_repository_pkg.sql
@@install_acc_rule_pkg.sql
@@install_acc_password_pkg.sql
@@install_acc_service_pkg.sql
@@install_acc_session_repository_pkg.sql
@@install_acc_session_pkg.sql
@@install_acc_session_api_pkg.sql
@@install_acc_api_pkg.sql

PROMPT ACCOUNT module installed successfully.
