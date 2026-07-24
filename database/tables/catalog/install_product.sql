WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE OFF
PROMPT ============================================================
PROMPT Installing PRODUCT structure...
PROMPT ============================================================
@@bex_product.sql
PROMPT PRODUCT structure installed successfully.
