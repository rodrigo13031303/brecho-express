SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
  n NUMBER;a NUMBER;p NUMBER;s NUMBER;c NUMBER;prd NUMBER;pur NUMBER;pri NUMBER;
  tok VARCHAR2(12):=LOWER(SUBSTR(RAWTOHEX(SYS_GUID()),1,12));
  sp CHAR(32):=LOWER(RAWTOHEX(SYS_GUID()));pp CHAR(32):=LOWER(RAWTOHEX(SYS_GUID()));
  ap CHAR(32):=LOWER(RAWTOHEX(SYS_GUID()));dp CHAR(32):=LOWER(RAWTOHEX(SYS_GUID()));
  rp CHAR(32):=LOWER(RAWTOHEX(SYS_GUID()));op CHAR(32);ship CHAR(32);
  ar adr_repository_pkg.t_row;dr dlp_repository_pkg.t_row;ord ord_service_pkg.t_record;
  shr shp_service_pkg.t_record;ids shp_service_pkg.t_public_ids;
  PROCEDURE ok(x BOOLEAN,m VARCHAR2) IS BEGIN IF x IS NULL OR NOT x THEN RAISE_APPLICATION_ERROR(-20999,m);END IF;END;
  PROCEDURE pass(i NUMBER,m VARCHAR2) IS BEGIN DBMS_OUTPUT.PUT_LINE('PASS '||LPAD(i,2,'0')||' - '||m);END;
BEGIN
  SELECT COUNT(*) INTO n FROM USER_TABLES WHERE TABLE_NAME IN('BEX_ADDRESS','BEX_DELIVERY_PROFILE',
    'BEX_ORDER','BEX_ORDER_ITEM','BEX_SHIPMENT','BEX_SHIPMENT_ITEM');
  ok(n=6,'Tabelas ausentes.');pass(1,'Seis tabelas existem');
  SELECT COUNT(*) INTO n FROM USER_OBJECTS WHERE OBJECT_NAME IN(
    'ADR_RULE_PKG','ADR_REPOSITORY_PKG','ADR_SERVICE_PKG','ADR_API_PKG',
    'DLP_RULE_PKG','DLP_REPOSITORY_PKG','DLP_SERVICE_PKG','DLP_API_PKG',
    'ORD_RULE_PKG','ORD_REPOSITORY_PKG','ORD_SERVICE_PKG','ORD_API_PKG',
    'SHP_RULE_PKG','SHP_REPOSITORY_PKG','SHP_SERVICE_PKG','SHP_API_PKG')
    AND OBJECT_TYPE IN('PACKAGE','PACKAGE BODY') AND STATUS='VALID';
  ok(n=32,'Packages invalidas.');pass(2,'Dezesseis packages possuem specification e body validos');
  SELECT COUNT(*) INTO n FROM USER_ERRORS WHERE NAME IN(
    'ADR_RULE_PKG','ADR_REPOSITORY_PKG','ADR_SERVICE_PKG','ADR_API_PKG',
    'DLP_RULE_PKG','DLP_REPOSITORY_PKG','DLP_SERVICE_PKG','DLP_API_PKG',
    'ORD_RULE_PKG','ORD_REPOSITORY_PKG','ORD_SERVICE_PKG','ORD_API_PKG',
    'SHP_RULE_PKG','SHP_REPOSITORY_PKG','SHP_SERVICE_PKG','SHP_API_PKG');
  ok(n=0,'USER_ERRORS encontrado.');pass(3,'Packages nao possuem USER_ERRORS');
  BEGIN adr_rule_pkg.validate_address('12345-678','Rua A','1','Centro','Cidade','SP','BR',NULL,NULL);
    pass(4,'ADDRESS Rule aceita contrato valido');END;
  BEGIN shp_rule_pkg.validate_transition('READY','IN_TRANSIT');pass(5,'SHIPMENT Rule aceita transicao oficial');END;

  INSERT INTO BEX_ACCOUNT(ACC_PUBLIC_ID,ACC_EMAIL,ACC_PASSWORD_HASH,ACC_PASSWORD_CHANGED_AT,ACC_STATUS)
    VALUES(ap,'flow.'||tok||'@example.invalid','test',SYSTIMESTAMP,'ACTIVE')RETURNING ACC_ID INTO a;
  INSERT INTO BEX_PROFILE(ACC_ID,PFL_PUBLIC_ID,PFL_DISPLAY_NAME)VALUES(a,pp,'Flow')RETURNING PFL_ID INTO p;
  INSERT INTO BEX_STORE(STR_PUBLIC_ID,ACC_ID,STR_NAME,STR_SLUG,STR_STATUS)
    VALUES(sp,a,'Flow Store','flow-'||tok,'ACTIVE')RETURNING STR_ID INTO s;
  INSERT INTO BEX_CATEGORY(CAT_PUBLIC_ID,CAT_NAME,CAT_SLUG,CAT_STATUS)
    VALUES(LOWER(RAWTOHEX(SYS_GUID())),'Flow Cat','flow-cat-'||tok,'ACTIVE')RETURNING CAT_ID INTO c;
  INSERT INTO BEX_PRODUCT(PRD_PUBLIC_ID,STR_ID,CAT_ID,PRD_TITLE,PRD_SLUG,PRD_PRICE,PRD_QUANTITY,PRD_CONDITION,PRD_STATUS)
    VALUES(LOWER(RAWTOHEX(SYS_GUID())),s,c,'Flow Product','flow-product-'||tok,25,2,'GOOD','ACTIVE')RETURNING PRD_ID INTO prd;
  INSERT INTO BEX_PURCHASE_REQUEST(PUR_PUBLIC_ID,PFL_ID,PUR_STATUS,PUR_RESPONSE_AT,PUR_CONFIRMED_AT)
    VALUES(rp,p,'APPROVED',SYSTIMESTAMP,SYSTIMESTAMP)RETURNING PUR_ID INTO pur;
  INSERT INTO BEX_PURCHASE_REQUEST_ITEM(PRI_PUBLIC_ID,PUR_ID,PRD_ID,STR_ID,PRI_REQUESTED_QUANTITY,
    PRI_CONFIRMED_QUANTITY,PRI_UNIT_PRICE,PRI_STATUS)VALUES(LOWER(RAWTOHEX(SYS_GUID())),pur,prd,s,2,2,25,'APPROVED')RETURNING PRI_ID INTO pri;
  ar.adr_zip_code:='12345-678';ar.adr_street:='Rua A';ar.adr_number:='1';ar.adr_district:='Centro';
  ar.adr_city:='Cidade';ar.adr_state:='SP';ar.adr_country:='BR';ar.adr_is_default:=1;
  ar:=adr_service_pkg.create_address(ar,a);ok(ar.adr_is_default=1,'Endereco incorreto.');pass(6,'ADDRESS Service cria endereco padrao');
  dr.dlp_code:='LOCAL';dr.dlp_name:='Entrega Local';dr.dlp_base_price:=5;dr.dlp_max_distance_km:=20;
  dr.dlp_max_weight_kg:=30;dr.dlp_is_express:=0;dr.dlp_status:='ACTIVE';dr:=dlp_service_pkg.create_internal(dr,a);
  pass(7,'DELIVERY_PROFILE Service cria modalidade');
  ord:=ord_service_pkg.create_paid_order(rp,0,5,SYSTIMESTAMP,a);op:=ord.order_public_id;
  ok(ord.total_amount=55 AND ord.items.COUNT=1,'Pedido incorreto.');pass(8,'ORDER nasce internamente da solicitacao aprovada');
  ids(1):=ord.items(1).item_public_id;shr:=shp_service_pkg.create_shipment(op,sp,ar.adr_public_id,
    dr.dlp_public_id,ids,SYSTIMESTAMP + INTERVAL '2' DAY,a);ship:=shr.shipment_public_id;
  ok(shr.items.COUNT=1 AND shr.status='CREATED','Remessa incorreta.');pass(9,'SHIPMENT aloca item da mesma loja');
  shr:=shp_service_pkg.change_status(ship,'READY',NULL,a);
  shr:=shp_service_pkg.change_status(ship,'IN_TRANSIT','TRACK-'||tok,a);
  shr:=shp_service_pkg.change_status(ship,'DELIVERED',NULL,a);
  ok(shr.status='DELIVERED' AND shr.delivered_at IS NOT NULL,'Entrega incorreta.');pass(10,'SHIPMENT conclui ciclo logistico');
  DBMS_OUTPUT.PUT_LINE('ORDER AND LOGISTICS MODULE: PASSED');
  ROLLBACK;
EXCEPTION WHEN OTHERS THEN ROLLBACK;RAISE;
END;
/
