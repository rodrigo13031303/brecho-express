SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
  a NUMBER;p NUMBER;s NUMBER;c NUMBER;prd NUMBER;pur NUMBER;o NUMBER;n NUMBER;
  tok VARCHAR2(12):=LOWER(SUBSTR(RAWTOHEX(SYS_GUID()),1,12));
  acc_pub CHAR(32):=LOWER(RAWTOHEX(SYS_GUID()));store_pub CHAR(32):=LOWER(RAWTOHEX(SYS_GUID()));
  order_pub CHAR(32):=LOWER(RAWTOHEX(SYS_GUID()));
  q rrq_service_pkg.t_record;atc rat_service_pkg.t_record;rv srv_service_pkg.t_record;rep srp_query_pkg.t_record;
  PROCEDURE ok(x BOOLEAN,m VARCHAR2)IS BEGIN IF x IS NULL OR NOT x THEN RAISE_APPLICATION_ERROR(-20999,m);END IF;END;
  PROCEDURE pass(i NUMBER,m VARCHAR2)IS BEGIN DBMS_OUTPUT.PUT_LINE('PASS '||LPAD(i,2,'0')||' - '||m);END;
BEGIN
  SELECT COUNT(*) INTO n FROM USER_TABLES WHERE TABLE_NAME IN('BEX_RETURN_REQUEST','BEX_RETURN_ATTACHMENT','BEX_STORE_REVIEW');
  ok(n=3,'Tabelas ausentes.');pass(1,'Tres tabelas existem');
  SELECT COUNT(*) INTO n FROM USER_VIEWS WHERE VIEW_NAME='BEX_STORE_REPUTATION';ok(n=1,'View ausente.');pass(2,'Reputacao e derivada');
  SELECT COUNT(*) INTO n FROM USER_OBJECTS WHERE OBJECT_NAME IN(
    'RRQ_RULE_PKG','RRQ_REPOSITORY_PKG','RRQ_SERVICE_PKG','RRQ_API_PKG',
    'RAT_RULE_PKG','RAT_REPOSITORY_PKG','RAT_SERVICE_PKG','RAT_API_PKG',
    'SRV_RULE_PKG','SRV_REPOSITORY_PKG','SRV_SERVICE_PKG','SRV_API_PKG','SRP_QUERY_PKG','SRP_API_PKG')
    AND OBJECT_TYPE IN('PACKAGE','PACKAGE BODY')AND STATUS='VALID';
  ok(n=28,'Packages invalidas.');pass(3,'Quatorze packages possuem specification e body validos');
  INSERT INTO BEX_ACCOUNT(ACC_PUBLIC_ID,ACC_EMAIL,ACC_PASSWORD_HASH,ACC_PASSWORD_CHANGED_AT,ACC_STATUS)
    VALUES(acc_pub,'post.'||tok||'@example.invalid','test',SYSTIMESTAMP,'ACTIVE')RETURNING ACC_ID INTO a;
  INSERT INTO BEX_PROFILE(ACC_ID,PFL_PUBLIC_ID,PFL_DISPLAY_NAME)VALUES(a,LOWER(RAWTOHEX(SYS_GUID())),'Post Sale')RETURNING PFL_ID INTO p;
  INSERT INTO BEX_STORE(STR_PUBLIC_ID,ACC_ID,STR_NAME,STR_SLUG,STR_STATUS)VALUES(store_pub,a,'Post Store','post-'||tok,'ACTIVE')RETURNING STR_ID INTO s;
  INSERT INTO BEX_STORE_USER(STU_PUBLIC_ID,STR_ID,ACC_ID,STU_ROLE_CODE,STU_STATUS,STU_JOINED_AT)
    VALUES(LOWER(RAWTOHEX(SYS_GUID())),s,a,'ADMIN','ACTIVE',SYSTIMESTAMP);
  INSERT INTO BEX_CATEGORY(CAT_PUBLIC_ID,CAT_NAME,CAT_SLUG,CAT_STATUS)VALUES(LOWER(RAWTOHEX(SYS_GUID())),'Post Cat','post-cat-'||tok,'ACTIVE')RETURNING CAT_ID INTO c;
  INSERT INTO BEX_PRODUCT(PRD_PUBLIC_ID,STR_ID,CAT_ID,PRD_TITLE,PRD_SLUG,PRD_PRICE,PRD_QUANTITY,PRD_CONDITION,PRD_STATUS)
    VALUES(LOWER(RAWTOHEX(SYS_GUID())),s,c,'Post Product','post-product-'||tok,100,1,'GOOD','ACTIVE')RETURNING PRD_ID INTO prd;
  INSERT INTO BEX_PURCHASE_REQUEST(PUR_PUBLIC_ID,PFL_ID,PUR_STATUS,PUR_RESPONSE_AT,PUR_CONFIRMED_AT)
    VALUES(LOWER(RAWTOHEX(SYS_GUID())),p,'APPROVED',SYSTIMESTAMP,SYSTIMESTAMP)RETURNING PUR_ID INTO pur;
  INSERT INTO BEX_ORDER(ORD_PUBLIC_ID,PUR_ID,PFL_ID,ORD_NUMBER,ORD_SUBTOTAL_AMOUNT,ORD_DISCOUNT_AMOUNT,
    ORD_SHIPPING_AMOUNT,ORD_TOTAL_AMOUNT,ORD_STATUS,ORD_PAID_AT)VALUES(order_pub,pur,p,'POST-'||tok,100,0,0,100,'COMPLETED',SYSTIMESTAMP)RETURNING ORD_ID INTO o;
  INSERT INTO BEX_ORDER_ITEM(ORI_PUBLIC_ID,ORD_ID,PRD_ID,STR_ID,ORI_QUANTITY,ORI_UNIT_PRICE,ORI_DISCOUNT_AMOUNT,ORI_TOTAL_PRICE)
    VALUES(LOWER(RAWTOHEX(SYS_GUID())),o,prd,s,1,100,0,100);
  q:=rrq_service_pkg.open_request(order_pub,store_pub,'PRODUCT_MISMATCH','Divergencia observada',a);
  ok(q.status='OPEN' AND q.pfl_id=p AND q.str_id=s,'Abertura incorreta.');pass(4,'Cliente abre ocorrencia de pedido concluido');
  atc:=rat_service_pkg.add_attachment(q.rrq_public_id,'PHOTO','https://example.invalid/evidence.jpg','evidence.jpg','image/jpeg',100,'Evidencia',a);
  ok(atc.status='ACTIVE' AND atc.rrq_id=q.rrq_id,'Anexo incorreto.');pass(5,'Evidencia pertence a ocorrencia');
  rv:=srv_service_pkg.create_review(order_pub,store_pub,5,5,4,5,4,5,'Y','Otima experiencia',a);
  ok(rv.overall_rate=5 AND rv.str_id=s,'Avaliacao incorreta.');pass(6,'Cliente avalia loja do pedido');
  BEGIN rv:=srv_service_pkg.create_review(order_pub,store_pub,4,NULL,NULL,NULL,NULL,NULL,'Y',NULL,a);
    RAISE_APPLICATION_ERROR(-20999,'Duplicidade aceita.');EXCEPTION WHEN srv_service_pkg.e_conflict THEN NULL;END;
  pass(7,'Avaliacao e unica por pedido e loja');
  rep:=srp_query_pkg.get_store(store_pub);
  ok(rep.review_count=1 AND rep.order_count=1 AND rep.return_request_count=1 AND rep.overall_rate=5,'Reputacao incorreta.');
  pass(8,'Reputacao consolida somente metricas rastreaveis');
  SELECT COUNT(*) INTO n FROM USER_ERRORS WHERE NAME IN(
    'RRQ_RULE_PKG','RRQ_REPOSITORY_PKG','RRQ_SERVICE_PKG','RRQ_API_PKG','RAT_RULE_PKG','RAT_REPOSITORY_PKG',
    'RAT_SERVICE_PKG','RAT_API_PKG','SRV_RULE_PKG','SRV_REPOSITORY_PKG','SRV_SERVICE_PKG','SRV_API_PKG','SRP_QUERY_PKG','SRP_API_PKG');
  ok(n=0,'USER_ERRORS encontrado.');pass(9,'Modulo nao possui USER_ERRORS');
  DBMS_OUTPUT.PUT_LINE('POST-SALE MODULE: PASSED');ROLLBACK;
EXCEPTION WHEN OTHERS THEN ROLLBACK;RAISE;
END;
/
