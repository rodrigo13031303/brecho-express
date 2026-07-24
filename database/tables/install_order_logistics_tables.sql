WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE OFF
SET DEFINE ON
DEFINE BEX_TABLE_ROOT = '&1'
PROMPT ============================================================
PROMPT Installing ORDER AND LOGISTICS structures...
PROMPT ============================================================
@&BEX_TABLE_ROOT/identity/bex_address.sql
@&BEX_TABLE_ROOT/logistics/bex_delivery_profile.sql
@&BEX_TABLE_ROOT/purchase/bex_order.sql
@&BEX_TABLE_ROOT/purchase/bex_order_item.sql
@&BEX_TABLE_ROOT/logistics/bex_shipment.sql
@&BEX_TABLE_ROOT/logistics/bex_shipment_item.sql
DECLARE
  n PLS_INTEGER;
BEGIN
  SELECT COUNT(*) INTO n FROM USER_TABLES WHERE TABLE_NAME IN(
    'BEX_ADDRESS','BEX_DELIVERY_PROFILE','BEX_ORDER','BEX_ORDER_ITEM',
    'BEX_SHIPMENT','BEX_SHIPMENT_ITEM');
  IF n<>6 THEN RAISE_APPLICATION_ERROR(
    -20999,'Estruturas ORDER AND LOGISTICS nao foram instaladas.');END IF;
END;
/
PROMPT ORDER AND LOGISTICS structures installed successfully.
UNDEFINE BEX_TABLE_ROOT
SET DEFINE OFF
