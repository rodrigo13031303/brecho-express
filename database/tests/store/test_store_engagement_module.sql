SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
  a NUMBER;p NUMBER;s NUMBER;n NUMBER;tok VARCHAR2(12):=LOWER(SUBSTR(RAWTOHEX(SYS_GUID()),1,12));
  store_pub CHAR(32):=LOWER(RAWTOHEX(SYS_GUID()));plan stp_query_pkg.t_record;
  ev ste_service_pkg.t_record;f stf_service_pkg.t_record;fs stf_service_pkg.t_records;
  PROCEDURE ok(x BOOLEAN,m VARCHAR2)IS BEGIN IF x IS NULL OR NOT x THEN RAISE_APPLICATION_ERROR(-20999,m);END IF;END;
  PROCEDURE pass(i NUMBER,m VARCHAR2)IS BEGIN DBMS_OUTPUT.PUT_LINE('PASS '||LPAD(i,2,'0')||' - '||m);END;
BEGIN
  SELECT COUNT(*)INTO n FROM USER_TABLES WHERE TABLE_NAME IN('BEX_STORE_PLAN','BEX_STORE_EVENT','BEX_STORE_FOLLOWER');
  ok(n=3,'Tabelas ausentes.');pass(1,'Tres tabelas existem');
  SELECT COUNT(*)INTO n FROM USER_OBJECTS WHERE OBJECT_NAME IN(
    'STP_QUERY_PKG','STP_API_PKG','STE_RULE_PKG','STE_REPOSITORY_PKG','STE_SERVICE_PKG','STE_API_PKG',
    'STF_RULE_PKG','STF_REPOSITORY_PKG','STF_SERVICE_PKG','STF_API_PKG')
    AND OBJECT_TYPE IN('PACKAGE','PACKAGE BODY')AND STATUS='VALID';
  ok(n=20,'Packages invalidas.');pass(2,'Dez packages possuem specification e body validos');
  SELECT COUNT(*)INTO n FROM BEX_STORE_PLAN WHERE STP_CODE IN('FREE','PLUS','PREMIUM');ok(n=3,'Planos oficiais ausentes.');
  plan:=stp_query_pkg.get_plan(' free ');ok(plan.code='FREE' AND plan.price=0,'Plano FREE incorreto.');pass(3,'Planos oficiais sao instalados e consultaveis');
  INSERT INTO BEX_ACCOUNT(ACC_PUBLIC_ID,ACC_EMAIL,ACC_PASSWORD_HASH,ACC_PASSWORD_CHANGED_AT,ACC_STATUS)
    VALUES(LOWER(RAWTOHEX(SYS_GUID())),'engagement.'||tok||'@example.invalid','test',SYSTIMESTAMP,'ACTIVE')RETURNING ACC_ID INTO a;
  INSERT INTO BEX_PROFILE(ACC_ID,PFL_PUBLIC_ID,PFL_DISPLAY_NAME)VALUES(a,LOWER(RAWTOHEX(SYS_GUID())),'Engagement')RETURNING PFL_ID INTO p;
  INSERT INTO BEX_STORE(STR_PUBLIC_ID,ACC_ID,STR_NAME,STR_SLUG,STR_STATUS)
    VALUES(store_pub,a,'Engagement Store','engagement-'||tok,'ACTIVE')RETURNING STR_ID INTO s;
  ev:=ste_service_pkg.create_event(store_pub,'Bazar de Inverno','Evento sazonal',SYSTIMESTAMP,SYSTIMESTAMP+INTERVAL '7' DAY,a);
  ok(ev.status='DRAFT' AND ev.store_id=s,'Evento incorreto.');pass(4,'Administrador cria evento em DRAFT');
  ev:=ste_service_pkg.change_status(ev.public_id,'ACTIVE',a);ok(ev.status='ACTIVE','Ativacao incorreta.');pass(5,'Evento respeita transicao de estado');
  BEGIN ev:=ste_service_pkg.change_status(ev.public_id,'DRAFT',a);RAISE_APPLICATION_ERROR(-20999,'Retrocesso aceito.');
  EXCEPTION WHEN ste_service_pkg.e_invalid THEN NULL;END;pass(6,'Evento rejeita transicao invalida');
  f:=stf_service_pkg.follow_store(store_pub,a);ok(f.status='ACTIVE' AND f.profile_id=p,'Follow incorreto.');pass(7,'Profile segue Store');
  BEGIN f:=stf_service_pkg.follow_store(store_pub,a);RAISE_APPLICATION_ERROR(-20999,'Follow duplicado.');
  EXCEPTION WHEN stf_service_pkg.e_conflict THEN NULL;END;pass(8,'Follow ativo duplicado e rejeitado');
  f:=stf_service_pkg.unfollow_store(store_pub,a);ok(f.status='INACTIVE' AND f.unfollowed_at IS NOT NULL,'Unfollow incorreto.');pass(9,'Unfollow preserva historico');
  f:=stf_service_pkg.follow_store(store_pub,a);fs:=stf_service_pkg.list_following(a);
  ok(f.status='ACTIVE' AND fs.COUNT=1,'Reativacao incorreta.');pass(10,'Follow pode ser reativado sem duplicar vinculo');
  SELECT COUNT(*)INTO n FROM USER_ERRORS WHERE NAME IN(
    'STP_QUERY_PKG','STP_API_PKG','STE_RULE_PKG','STE_REPOSITORY_PKG','STE_SERVICE_PKG','STE_API_PKG',
    'STF_RULE_PKG','STF_REPOSITORY_PKG','STF_SERVICE_PKG','STF_API_PKG');
  ok(n=0,'USER_ERRORS encontrado.');pass(11,'Modulo nao possui USER_ERRORS');
  DBMS_OUTPUT.PUT_LINE('STORE ENGAGEMENT MODULE: PASSED');ROLLBACK;
EXCEPTION WHEN OTHERS THEN ROLLBACK;RAISE;
END;
/
