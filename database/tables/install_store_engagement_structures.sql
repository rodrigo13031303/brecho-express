WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE ON
DEFINE BEX_TABLE_ROOT='&1'
@&BEX_TABLE_ROOT/store/bex_store_plan.sql
@&BEX_TABLE_ROOT/store/bex_store_event.sql
@&BEX_TABLE_ROOT/social/bex_store_follower.sql
UNDEFINE BEX_TABLE_ROOT
SET DEFINE OFF
PROMPT STORE ENGAGEMENT structures installed successfully.
