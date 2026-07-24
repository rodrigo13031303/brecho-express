WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE ON
DEFINE BEX_TABLE_ROOT = '&1'
@&BEX_TABLE_ROOT/notification/bex_notification.sql
@&BEX_TABLE_ROOT/notification/bex_notification_delivery.sql
@&BEX_TABLE_ROOT/notification/bex_notification_template.sql
UNDEFINE BEX_TABLE_ROOT
SET DEFINE OFF
PROMPT NOTIFICATION structures installed successfully.
