WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE OFF
PROMPT Installing PRODUCT_IMAGE module...
@@install_pim_rule_pkg.sql
@@install_pim_repository_pkg.sql
@@install_pim_service_pkg.sql
@@install_pim_api_pkg.sql
PROMPT PRODUCT_IMAGE module installed successfully.
