WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE OFF
PROMPT Installing PRODUCT_QUESTION module...
@@install_pqa_rule_pkg.sql
@@install_pqa_repository_pkg.sql
@@install_pqa_service_pkg.sql
@@install_pqa_api_pkg.sql
PROMPT PRODUCT_QUESTION module installed successfully.
