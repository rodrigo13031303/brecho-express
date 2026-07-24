SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
  a NUMBER;p NUMBER;s NUMBER;c NUMBER;prd NUMBER;pur NUMBER;ord NUMBER;pay NUMBER;ppr NUMBER;n NUMBER;
  tok VARCHAR2(12):=LOWER(SUBSTR(RAWTOHEX(SYS_GUID()),1,12));
  store_pub CHAR(32):=LOWER(RAWTOHEX(SYS_GUID()));pay_pub CHAR(32):=LOWER(RAWTOHEX(SYS_GUID()));
  payout pot_service_pkg.t_record;bal sbl_query_pkg.t_record;
  PROCEDURE ok(x BOOLEAN,m VARCHAR2) IS BEGIN IF x IS NULL OR NOT x THEN RAISE_APPLICATION_ERROR(-20999,m);END IF;END;
  PROCEDURE pass(i NUMBER,m VARCHAR2) IS BEGIN DBMS_OUTPUT.PUT_LINE('PASS '||LPAD(i,2,'0')||' - '||m);END;
BEGIN
  SELECT COUNT(*) INTO n FROM USER_TABLES WHERE TABLE_NAME IN('BEX_COMMISSION','BEX_PAYOUT','BEX_STORE_BALANCE_TRANSACTION');
  ok(n=3,'Tabelas ausentes.');pass(1,'Tres tabelas existem');
  SELECT COUNT(*) INTO n FROM USER_VIEWS WHERE VIEW_NAME='BEX_STORE_BALANCE';ok(n=1,'View ausente.');pass(2,'STORE_BALANCE e view derivada');
  SELECT COUNT(*) INTO n FROM USER_OBJECTS WHERE OBJECT_NAME IN('SBT_RULE_PKG','SBT_REPOSITORY_PKG','SBT_SERVICE_PKG',
    'SBL_QUERY_PKG','SBL_API_PKG','COM_RULE_PKG','COM_REPOSITORY_PKG','COM_SERVICE_PKG',
    'POT_RULE_PKG','POT_REPOSITORY_PKG','POT_SERVICE_PKG','POT_API_PKG')
    AND OBJECT_TYPE IN('PACKAGE','PACKAGE BODY') AND STATUS='VALID';
  ok(n=24,'Packages invalidas.');pass(3,'Doze packages possuem specification e body validos');
  INSERT INTO BEX_ACCOUNT(ACC_PUBLIC_ID,ACC_EMAIL,ACC_PASSWORD_HASH,ACC_PASSWORD_CHANGED_AT,ACC_STATUS)
    VALUES(LOWER(RAWTOHEX(SYS_GUID())),'ledger.'||tok||'@example.invalid','test',SYSTIMESTAMP,'ACTIVE')RETURNING ACC_ID INTO a;
  INSERT INTO BEX_PROFILE(ACC_ID,PFL_PUBLIC_ID,PFL_DISPLAY_NAME)VALUES(a,LOWER(RAWTOHEX(SYS_GUID())),'Ledger')RETURNING PFL_ID INTO p;
  INSERT INTO BEX_STORE(STR_PUBLIC_ID,ACC_ID,STR_NAME,STR_SLUG,STR_STATUS)VALUES(store_pub,a,'Ledger Store','ledger-'||tok,'ACTIVE')RETURNING STR_ID INTO s;
  INSERT INTO BEX_CATEGORY(CAT_PUBLIC_ID,CAT_NAME,CAT_SLUG,CAT_STATUS)VALUES(LOWER(RAWTOHEX(SYS_GUID())),'Ledger Cat','ledger-cat-'||tok,'ACTIVE')RETURNING CAT_ID INTO c;
  INSERT INTO BEX_PRODUCT(PRD_PUBLIC_ID,STR_ID,CAT_ID,PRD_TITLE,PRD_SLUG,PRD_PRICE,PRD_QUANTITY,PRD_CONDITION,PRD_STATUS)
    VALUES(LOWER(RAWTOHEX(SYS_GUID())),s,c,'Ledger Product','ledger-product-'||tok,100,1,'GOOD','ACTIVE')RETURNING PRD_ID INTO prd;
  INSERT INTO BEX_PURCHASE_REQUEST(PUR_PUBLIC_ID,PFL_ID,PUR_STATUS,PUR_RESPONSE_AT,PUR_CONFIRMED_AT)
    VALUES(LOWER(RAWTOHEX(SYS_GUID())),p,'APPROVED',SYSTIMESTAMP,SYSTIMESTAMP)RETURNING PUR_ID INTO pur;
  INSERT INTO BEX_ORDER(ORD_PUBLIC_ID,PUR_ID,PFL_ID,ORD_NUMBER,ORD_SUBTOTAL_AMOUNT,ORD_DISCOUNT_AMOUNT,
    ORD_SHIPPING_AMOUNT,ORD_TOTAL_AMOUNT,ORD_PAID_AT)VALUES(LOWER(RAWTOHEX(SYS_GUID())),pur,p,'LED-'||tok,100,0,0,100,SYSTIMESTAMP)RETURNING ORD_ID INTO ord;
  INSERT INTO BEX_ORDER_ITEM(ORI_PUBLIC_ID,ORD_ID,PRD_ID,STR_ID,ORI_QUANTITY,ORI_UNIT_PRICE,ORI_DISCOUNT_AMOUNT,ORI_TOTAL_PRICE)
    VALUES(LOWER(RAWTOHEX(SYS_GUID())),ord,prd,s,1,100,0,100);
  INSERT INTO BEX_PAYMENT_PROVIDER(PPR_PUBLIC_ID,PPR_CODE,PPR_NAME)VALUES(LOWER(RAWTOHEX(SYS_GUID())),'LEDGER_TEST_'||UPPER(tok),'Ledger Test')RETURNING PPR_ID INTO ppr;
  INSERT INTO BEX_PAYMENT(PAY_PUBLIC_ID,PUR_ID,ORD_ID,PPR_ID,PAY_EXTERNAL_ID,PAY_AMOUNT,PAY_METHOD,PAY_STATUS,PAY_APPROVED_AT)
    VALUES(pay_pub,pur,ord,ppr,'ledger-'||tok,100,'PIX','APPROVED',SYSTIMESTAMP)RETURNING PAY_ID INTO pay;
  com_service_pkg.settle_payment(pay_pub,10,5,SYSTIMESTAMP + INTERVAL '7' DAY,a);
  bal:=sbl_query_pkg.get_balance(store_pub,a);ok(bal.blocked_amount=85 AND bal.available_amount=0,'Liquidacao incorreta.');pass(4,'Comissao gera credito liquido bloqueado');
  sbt_service_pkg.release_hold(s,ord,pay,85,a);bal:=sbl_query_pkg.get_balance(store_pub,a);
  ok(bal.blocked_amount=0 AND bal.available_amount=85,'Liberacao incorreta.');pass(5,'Retencao e liberada para saldo disponivel');
  payout:=pot_service_pkg.request_payout(store_pub,50,'pix-'||tok,'RANDOM',a);bal:=sbl_query_pkg.get_balance(store_pub,a);
  ok(bal.available_amount=35 AND bal.pending_payout_amount=50,'Reserva incorreta.');pass(6,'Payout reserva saldo disponivel');
  payout:=pot_service_pkg.change_state_internal(payout.payout_public_id,'APPROVED',NULL,a);
  payout:=pot_service_pkg.change_state_internal(payout.payout_public_id,'PAID',NULL,a);
  bal:=sbl_query_pkg.get_balance(store_pub,a);ok(bal.pending_payout_amount=0 AND bal.paid_amount=50,'Pagamento incorreto.');pass(7,'Payout pago consolida valor repassado');
  DBMS_OUTPUT.PUT_LINE('LEDGER AND PAYOUT MODULE: PASSED');ROLLBACK;
EXCEPTION WHEN OTHERS THEN ROLLBACK;RAISE;
END;
/
