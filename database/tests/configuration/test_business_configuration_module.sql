SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
  a NUMBER;p NUMBER;n NUMBER;tok VARCHAR2(12):=LOWER(SUBSTR(RAWTOHEX(SYS_GUID()),1,12));
  cfg bcf_service_pkg.t_record;xs bcf_service_pkg.t_records;
  PROCEDURE ok(v BOOLEAN,m VARCHAR2) IS BEGIN IF v IS NULL OR NOT v THEN RAISE_APPLICATION_ERROR(-20999,m); END IF; END;
  PROCEDURE pass(i NUMBER,m VARCHAR2) IS BEGIN DBMS_OUTPUT.PUT_LINE('PASS '||LPAD(i,2,'0')||' - '||m); END;
BEGIN
  SELECT COUNT(*) INTO n FROM USER_TABLES WHERE TABLE_NAME='BEX_BUSINESS_CONFIGURATION';
  ok(n=1,'Tabela ausente.'); pass(1,'Tabela existe');
  SELECT COUNT(*) INTO n FROM USER_OBJECTS WHERE OBJECT_NAME IN('BCF_RULE_PKG','BCF_REPOSITORY_PKG','BCF_SERVICE_PKG')
    AND OBJECT_TYPE IN('PACKAGE','PACKAGE BODY') AND STATUS='VALID';
  ok(n=6,'Packages invalidos.'); pass(2,'Tres packages possuem specification e body validos');
  SELECT COUNT(*) INTO n FROM BEX_BUSINESS_CONFIGURATION WHERE BCF_CODE IN('PURCHASE_STORE_CONFIRMATION_TIMEOUT','RETURN_FIRST_FREE','SOCIAL_PUBLIC_COMMENTS');
  ok(n>=3,'Seeds ausentes.'); pass(3,'Políticas iniciais foram carregadas');
  INSERT INTO BEX_ACCOUNT(ACC_PUBLIC_ID,ACC_EMAIL,ACC_PASSWORD_HASH,ACC_PASSWORD_CHANGED_AT,ACC_STATUS)
    VALUES(LOWER(RAWTOHEX(SYS_GUID())),'cfg.'||tok||'@example.invalid','test',SYSTIMESTAMP,'ACTIVE') RETURNING ACC_ID INTO a;
  INSERT INTO BEX_PROFILE(ACC_ID,PFL_PUBLIC_ID,PFL_DISPLAY_NAME) VALUES(a,LOWER(RAWTOHEX(SYS_GUID())),'Config Tester') RETURNING PFL_ID INTO p;
  cfg:=bcf_service_pkg.upsert_config('TEST_MAX_UPLOADS','CATALOG','Máximo de uploads','teste',NULL,8,NULL,'quantity',p);
  ok(cfg.code='TEST_MAX_UPLOADS' AND cfg.value_number=8,'Upsert incorreto.'); pass(4,'Upsert cria política numérica');
  cfg:=bcf_service_pkg.upsert_config('TEST_MAX_UPLOADS','CATALOG','Máximo de uploads','teste',NULL,12,NULL,'quantity',p);
  ok(cfg.value_number=12,'Atualização incorreta.'); pass(5,'Upsert atualiza política existente');
  xs:=bcf_service_pkg.list_module('CATALOG'); ok(xs.COUNT>=1,'Listagem vazia.'); pass(6,'Listagem por módulo funciona');
  BEGIN cfg:=bcf_service_pkg.upsert_config('TEST_INVALID','CATALOG','Inv','',NULL,1,'Y','unit',p); RAISE_APPLICATION_ERROR(-20999,'Valor múltiplo aceito.');
  EXCEPTION WHEN bcf_service_pkg.e_invalid THEN NULL; END; pass(7,'Validação de tipo único funciona');
  SELECT COUNT(*) INTO n FROM USER_ERRORS WHERE NAME IN('BCF_RULE_PKG','BCF_REPOSITORY_PKG','BCF_SERVICE_PKG');
  ok(n=0,'USER_ERRORS encontrado.'); pass(8,'Modulo nao possui USER_ERRORS');
  DBMS_OUTPUT.PUT_LINE('BUSINESS CONFIGURATION MODULE: PASSED'); ROLLBACK;
EXCEPTION WHEN OTHERS THEN ROLLBACK; RAISE;
END;
/
