WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE ON
DEFINE BEX_TABLE_ROOT = '&1'
DEFINE BEX_VIEW_ROOT = '&2'
PROMPT ============================================================
PROMPT Installing LEDGER AND PAYOUT structures...
PROMPT ============================================================
@&BEX_TABLE_ROOT/finance/bex_commission.sql
@&BEX_TABLE_ROOT/finance/bex_payout.sql
@&BEX_TABLE_ROOT/finance/bex_store_balance_transaction.sql
@&BEX_VIEW_ROOT/finance/bex_store_balance.sql
DECLARE n PLS_INTEGER;BEGIN
  SELECT COUNT(*) INTO n FROM USER_TABLES WHERE TABLE_NAME IN(
    'BEX_COMMISSION','BEX_PAYOUT','BEX_STORE_BALANCE_TRANSACTION');
  IF n<>3 THEN RAISE_APPLICATION_ERROR(-20999,'Ledger tables ausentes.');END IF;
  SELECT COUNT(*) INTO n FROM USER_VIEWS WHERE VIEW_NAME='BEX_STORE_BALANCE';
  IF n<>1 THEN RAISE_APPLICATION_ERROR(-20999,'Balance view ausente.');END IF;
END;
/
PROMPT LEDGER AND PAYOUT structures installed successfully.
UNDEFINE BEX_TABLE_ROOT
UNDEFINE BEX_VIEW_ROOT
SET DEFINE OFF
