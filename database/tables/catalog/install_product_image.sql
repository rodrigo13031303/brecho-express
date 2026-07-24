WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE OFF
PROMPT Installing PRODUCT_IMAGE structure...
@@bex_product_image.sql
PROMPT PRODUCT_IMAGE structure installed successfully.
