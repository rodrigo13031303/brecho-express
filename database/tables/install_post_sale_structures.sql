WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE ON
DEFINE BEX_TABLE_ROOT = '&1'
PROMPT Installing POST-SALE structures...
@&BEX_TABLE_ROOT/post_sale/bex_return_request.sql
@&BEX_TABLE_ROOT/post_sale/bex_return_attachment.sql
@&BEX_TABLE_ROOT/post_sale/bex_store_review.sql
UNDEFINE BEX_TABLE_ROOT
SET DEFINE OFF
PROMPT POST-SALE structures installed successfully.
