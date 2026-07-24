SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
  a NUMBER;p NUMBER;s NUMBER;c NUMBER;prd NUMBER;pur NUMBER;n NUMBER;
  tok VARCHAR2(12):=LOWER(SUBSTR(RAWTOHEX(SYS_GUID()),1,12));
  rp CHAR(32):=LOWER(RAWTOHEX(SYS_GUID()));provider ppr_service_pkg.t_record;
  pay pay_service_pkg.t_record;ev pev_service_pkg.t_result;payload CLOB:='{"gateway":"test"}';
  PROCEDURE ok(x BOOLEAN,m VARCHAR2) IS BEGIN IF x IS NULL OR NOT x THEN RAISE_APPLICATION_ERROR(-20999,m);END IF;END;
  PROCEDURE pass(i NUMBER,m VARCHAR2) IS BEGIN DBMS_OUTPUT.PUT_LINE('PASS '||LPAD(i,2,'0')||' - '||m);END;
BEGIN
  SELECT COUNT(*) INTO n FROM USER_TABLES WHERE TABLE_NAME IN('BEX_PAYMENT_PROVIDER','BEX_PAYMENT','BEX_PAYMENT_EVENT');
  ok(n=3,'Tabelas ausentes.');pass(1,'Tres tabelas existem');
  SELECT COUNT(*) INTO n FROM USER_OBJECTS WHERE OBJECT_NAME IN(
    'PPR_RULE_PKG','PPR_REPOSITORY_PKG','PPR_SERVICE_PKG','PPR_API_PKG',
    'PAY_RULE_PKG','PAY_REPOSITORY_PKG','PAY_SERVICE_PKG','PAY_API_PKG',
    'PEV_RULE_PKG','PEV_REPOSITORY_PKG','PEV_SERVICE_PKG','PEV_API_PKG')
    AND OBJECT_TYPE IN('PACKAGE','PACKAGE BODY') AND STATUS='VALID';
  ok(n=24,'Packages invalidas.');pass(2,'Doze packages possuem specification e body validos');
  SELECT COUNT(*) INTO n FROM USER_ERRORS WHERE NAME IN('PPR_RULE_PKG','PPR_REPOSITORY_PKG',
    'PPR_SERVICE_PKG','PPR_API_PKG','PAY_RULE_PKG','PAY_REPOSITORY_PKG','PAY_SERVICE_PKG',
    'PAY_API_PKG','PEV_RULE_PKG','PEV_REPOSITORY_PKG','PEV_SERVICE_PKG','PEV_API_PKG');
  ok(n=0,'USER_ERRORS encontrado.');pass(3,'Packages nao possuem USER_ERRORS');
  INSERT INTO BEX_ACCOUNT(ACC_PUBLIC_ID,ACC_EMAIL,ACC_PASSWORD_HASH,ACC_PASSWORD_CHANGED_AT,ACC_STATUS)
    VALUES(LOWER(RAWTOHEX(SYS_GUID())),'pay.'||tok||'@example.invalid','test',SYSTIMESTAMP,'ACTIVE')RETURNING ACC_ID INTO a;
  INSERT INTO BEX_PROFILE(ACC_ID,PFL_PUBLIC_ID,PFL_DISPLAY_NAME)VALUES(a,LOWER(RAWTOHEX(SYS_GUID())),'Pay')RETURNING PFL_ID INTO p;
  INSERT INTO BEX_STORE(STR_PUBLIC_ID,ACC_ID,STR_NAME,STR_SLUG,STR_STATUS)
    VALUES(LOWER(RAWTOHEX(SYS_GUID())),a,'Pay Store','pay-'||tok,'ACTIVE')RETURNING STR_ID INTO s;
  INSERT INTO BEX_CATEGORY(CAT_PUBLIC_ID,CAT_NAME,CAT_SLUG,CAT_STATUS)
    VALUES(LOWER(RAWTOHEX(SYS_GUID())),'Pay Cat','pay-cat-'||tok,'ACTIVE')RETURNING CAT_ID INTO c;
  INSERT INTO BEX_PRODUCT(PRD_PUBLIC_ID,STR_ID,CAT_ID,PRD_TITLE,PRD_SLUG,PRD_PRICE,PRD_QUANTITY,PRD_CONDITION,PRD_STATUS)
    VALUES(LOWER(RAWTOHEX(SYS_GUID())),s,c,'Pay Product','pay-product-'||tok,40,1,'GOOD','ACTIVE')RETURNING PRD_ID INTO prd;
  INSERT INTO BEX_PURCHASE_REQUEST(PUR_PUBLIC_ID,PFL_ID,PUR_STATUS,PUR_RESPONSE_AT,PUR_CONFIRMED_AT)
    VALUES(rp,p,'APPROVED',SYSTIMESTAMP,SYSTIMESTAMP)RETURNING PUR_ID INTO pur;
  INSERT INTO BEX_PURCHASE_REQUEST_ITEM(PRI_PUBLIC_ID,PUR_ID,PRD_ID,STR_ID,PRI_REQUESTED_QUANTITY,
    PRI_CONFIRMED_QUANTITY,PRI_UNIT_PRICE,PRI_STATUS)VALUES(LOWER(RAWTOHEX(SYS_GUID())),pur,prd,s,1,1,40,'APPROVED');
  provider:=ppr_service_pkg.create_internal('TEST_GATEWAY','Test Gateway',a);
  ok(provider.ppr_status='ACTIVE','Provider incorreto.');pass(4,'Provider interno criado');
  pay:=pay_service_pkg.create_payment(rp,provider.ppr_public_id,'charge-'||tok,'PIX',a);
  ok(pay.status='PENDING' AND pay.amount=40 AND pay.order_public_id IS NULL,'Payment incorreto.');pass(5,'Pagamento nasce PENDING sem ORDER');
  SELECT COUNT(*) INTO n FROM BEX_ORDER WHERE PUR_ID=pur;ok(n=0,'ORDER antecipado.');pass(6,'Nenhum ORDER existe antes da aprovacao');
  ev:=pev_service_pkg.process_event(pay.payment_public_id,'PAYMENT_APPROVED','event-'||tok,SYSTIMESTAMP,payload,a);
  ok(ev.event_status='PROCESSED' AND ev.payment.status='APPROVED'
    AND ev.payment.order_public_id IS NOT NULL,'Aprovacao incorreta.');pass(7,'Evento aprovado cria e vincula ORDER');
  SELECT COUNT(*) INTO n FROM BEX_ORDER WHERE PUR_ID=pur;ok(n=1,'Quantidade de ORDER incorreta.');pass(8,'Exatamente um ORDER foi criado');
  ev:=pev_service_pkg.process_event(pay.payment_public_id,'PAYMENT_APPROVED','event-'||tok,SYSTIMESTAMP,payload,a);
  SELECT COUNT(*) INTO n FROM BEX_PAYMENT_EVENT WHERE PAY_ID=(SELECT PAY_ID FROM BEX_PAYMENT WHERE PAY_PUBLIC_ID=pay.payment_public_id);
  ok(n=1 AND ev.payment.status='APPROVED','Idempotencia incorreta.');pass(9,'Webhook repetido nao duplica evento');
  SELECT COUNT(*) INTO n FROM BEX_ORDER WHERE PUR_ID=pur;ok(n=1,'Webhook duplicou ORDER.');pass(10,'Webhook repetido nao duplica ORDER');
  DBMS_OUTPUT.PUT_LINE('PAYMENT MODULE: PASSED');ROLLBACK;
EXCEPTION WHEN OTHERS THEN ROLLBACK;RAISE;
END;
/
