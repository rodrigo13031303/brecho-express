SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
  a NUMBER;p NUMBER;n NUMBER;tok VARCHAR2(12):=LOWER(SUBSTR(RAWTOHEX(SYS_GUID()),1,12));
  profile_pub CHAR(32):=LOWER(RAWTOHEX(SYS_GUID()));x prl_service_pkg.t_record;xs prl_service_pkg.t_records;
  PROCEDURE ok(v BOOLEAN,m VARCHAR2)IS BEGIN IF v IS NULL OR NOT v THEN RAISE_APPLICATION_ERROR(-20999,m);END IF;END;
  PROCEDURE pass(i NUMBER,m VARCHAR2)IS BEGIN DBMS_OUTPUT.PUT_LINE('PASS '||LPAD(i,2,'0')||' - '||m);END;
BEGIN
  SELECT COUNT(*)INTO n FROM USER_TABLES WHERE TABLE_NAME IN('BEX_ROLE','BEX_PROFILE_ROLE');
  ok(n=2,'Tabelas ausentes.');pass(1,'Duas tabelas existem');
  SELECT COUNT(*)INTO n FROM USER_OBJECTS WHERE OBJECT_NAME IN(
    'ROL_QUERY_PKG','PRL_RULE_PKG','PRL_REPOSITORY_PKG','PRL_SERVICE_PKG','IAM_AUTHORIZATION_PKG')
    AND OBJECT_TYPE IN('PACKAGE','PACKAGE BODY')AND STATUS='VALID';
  ok(n=10,'Packages invalidas.');pass(2,'Cinco packages possuem specification e body validos');
  SELECT COUNT(*)INTO n FROM BEX_ROLE WHERE ROL_CODE IN('SYSTEM','ADMIN','CUSTOMER','STORE_OWNER','STORE_ATTENDANT');
  ok(n=5,'Roles oficiais ausentes.');pass(3,'Cinco Roles oficiais foram instalados');
  INSERT INTO BEX_ACCOUNT(ACC_PUBLIC_ID,ACC_EMAIL,ACC_PASSWORD_HASH,ACC_PASSWORD_CHANGED_AT,ACC_STATUS)
    VALUES(LOWER(RAWTOHEX(SYS_GUID())),'role.'||tok||'@example.invalid','test',SYSTIMESTAMP,'ACTIVE')RETURNING ACC_ID INTO a;
  INSERT INTO BEX_PROFILE(ACC_ID,PFL_PUBLIC_ID,PFL_DISPLAY_NAME)VALUES(a,profile_pub,'Role Test')RETURNING PFL_ID INTO p;
  x:=prl_service_pkg.grant_role(profile_pub,' customer ',NULL,p);
  ok(x.status='ACTIVE' AND iam_authorization_pkg.has_role(a,'customer'),'Grant incorreto.');pass(4,'Role e concedido e reconhecido');
  BEGIN x:=prl_service_pkg.grant_role(profile_pub,'CUSTOMER',NULL,p);RAISE_APPLICATION_ERROR(-20999,'Duplicidade aceita.');
  EXCEPTION WHEN prl_service_pkg.e_already_active THEN NULL;END;pass(5,'Concessao ativa duplicada e rejeitada');
  x:=prl_service_pkg.revoke_role(profile_pub,'CUSTOMER',p);
  ok(x.status='INACTIVE' AND NOT iam_authorization_pkg.has_role(a,'CUSTOMER'),'Revogacao incorreta.');pass(6,'Role revogado perde autorizacao');
  x:=prl_service_pkg.grant_role(profile_pub,'CUSTOMER',SYSTIMESTAMP+INTERVAL '1' DAY,p);xs:=prl_service_pkg.list_roles(profile_pub);
  ok(x.id=xs(1).id AND xs.COUNT=1 AND iam_authorization_pkg.has_role(a,'CUSTOMER'),'Reativacao incorreta.');pass(7,'Associacao e reativada sem perder identidade');
  BEGIN x:=prl_service_pkg.grant_role(profile_pub,'ADMIN',SYSTIMESTAMP-INTERVAL '1' SECOND,p);
    RAISE_APPLICATION_ERROR(-20999,'Expiracao passada aceita.');EXCEPTION WHEN prl_service_pkg.e_invalid_expiry THEN NULL;END;
  pass(8,'Expiracao passada e rejeitada');
  BEGIN iam_authorization_pkg.require_role(a,'ADMIN');RAISE_APPLICATION_ERROR(-20999,'Acesso indevido.');
  EXCEPTION WHEN iam_authorization_pkg.e_forbidden THEN NULL;END;pass(9,'Require Role bloqueia papel ausente');
  SELECT COUNT(*)INTO n FROM USER_ERRORS WHERE NAME IN(
    'ROL_QUERY_PKG','PRL_RULE_PKG','PRL_REPOSITORY_PKG','PRL_SERVICE_PKG','IAM_AUTHORIZATION_PKG');
  ok(n=0,'USER_ERRORS encontrado.');pass(10,'Modulo nao possui USER_ERRORS');
  DBMS_OUTPUT.PUT_LINE('IDENTITY AUTHORIZATION MODULE: PASSED');ROLLBACK;
EXCEPTION WHEN OTHERS THEN ROLLBACK;RAISE;
END;
/
