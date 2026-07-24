WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE OFF
PROMPT ============================================================
PROMPT Installing initial PURCHASE structures...
PROMPT ============================================================
@@bex_cart.sql
@@bex_cart_item.sql
@@bex_purchase_request.sql
@@bex_purchase_request_item.sql
PROMPT Initial PURCHASE structures installed successfully.
