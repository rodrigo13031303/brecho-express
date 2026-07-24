WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE ON
DEFINE BEX_TABLE_ROOT = '&1'
PROMPT ============================================================
PROMPT Installing PAYMENT structures...
PROMPT ============================================================
@&BEX_TABLE_ROOT/finance/bex_payment_provider.sql
@&BEX_TABLE_ROOT/finance/bex_payment.sql
@&BEX_TABLE_ROOT/finance/bex_payment_event.sql
DECLARE n PLS_INTEGER;BEGIN SELECT COUNT(*) INTO n FROM USER_TABLES WHERE TABLE_NAME IN(
  'BEX_PAYMENT_PROVIDER','BEX_PAYMENT','BEX_PAYMENT_EVENT');
  IF n<>3 THEN RAISE_APPLICATION_ERROR(-20999,'PAYMENT structures ausentes.');END IF;END;
/
PROMPT PAYMENT structures installed successfully.
UNDEFINE BEX_TABLE_ROOT
SET DEFINE OFF
