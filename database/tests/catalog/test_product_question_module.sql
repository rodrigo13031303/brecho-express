SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE
@@test_bex_product_question.sql
DECLARE
  owner_id NUMBER;customer_id NUMBER;owner_p NUMBER;customer_p NUMBER;
  s NUMBER;c NUMBER;p NUMBER;st PLS_INTEGER;body CLOB;j JSON_OBJECT_T;
  qpub VARCHAR2(32);tok VARCHAR2(12):=LOWER(SUBSTR(RAWTOHEX(SYS_GUID()),1,12));
  sp CHAR(32):=LOWER(RAWTOHEX(SYS_GUID()));pp CHAR(32):=LOWER(RAWTOHEX(SYS_GUID()));n PLS_INTEGER;
  PROCEDURE ok(x BOOLEAN,m VARCHAR2) IS BEGIN IF x IS NULL OR NOT x THEN RAISE_APPLICATION_ERROR(-20999,m);END IF;END;
BEGIN
  SELECT COUNT(*) INTO n FROM USER_OBJECTS WHERE OBJECT_NAME IN(
    'PQA_RULE_PKG','PQA_REPOSITORY_PKG','PQA_SERVICE_PKG','PQA_API_PKG')
    AND OBJECT_TYPE IN('PACKAGE','PACKAGE BODY')AND STATUS='VALID';
  ok(n=8,'Packages PQA invalidas.');
  SELECT COUNT(*) INTO n FROM USER_SOURCE WHERE NAME IN('PQA_RULE_PKG','PQA_SERVICE_PKG')
    AND REGEXP_LIKE(UPPER(TEXT),
      '(^|[^A-Z_])(SELECT|INSERT|UPDATE|DELETE|MERGE|COMMIT|ROLLBACK)([^A-Z_]|$)|JSON');
  ok(n=0,'Rule ou Service PQA possui elemento proibido.');
  SELECT COUNT(*) INTO n FROM USER_SOURCE WHERE NAME='PQA_REPOSITORY_PKG'
    AND REGEXP_LIKE(UPPER(TEXT),'(^|[^A-Z_])(COMMIT|ROLLBACK)([^A-Z_]|$)|JSON');
  ok(n=0,'Repository PQA possui elemento proibido.');
  SELECT COUNT(*) INTO n FROM USER_DEPENDENCIES WHERE NAME='PQA_API_PKG'
    AND REFERENCED_NAME IN('PQA_REPOSITORY_PKG','BEX_PRODUCT_QUESTION');
  ok(n=0,'API PQA ignora Service.');
  core_context_pkg.clear;core_trace_pkg.clear;core_trace_pkg.initialize;
  core_context_pkg.initialize(core_context_pkg.c_origin_external,
    core_context_pkg.c_mode_synchronous,NULL,FALSE);
  INSERT INTO BEX_ACCOUNT(ACC_PUBLIC_ID,ACC_EMAIL,ACC_PASSWORD_HASH,ACC_PASSWORD_CHANGED_AT,ACC_STATUS)
    VALUES(LOWER(RAWTOHEX(SYS_GUID())),'owner.'||tok||'@x.invalid','x',SYSTIMESTAMP,'ACTIVE')RETURNING ACC_ID INTO owner_id;
  INSERT INTO BEX_PROFILE(ACC_ID,PFL_PUBLIC_ID,PFL_DISPLAY_NAME)
    VALUES(owner_id,LOWER(RAWTOHEX(SYS_GUID())),'Owner')RETURNING PFL_ID INTO owner_p;
  INSERT INTO BEX_ACCOUNT(ACC_PUBLIC_ID,ACC_EMAIL,ACC_PASSWORD_HASH,ACC_PASSWORD_CHANGED_AT,ACC_STATUS)
    VALUES(LOWER(RAWTOHEX(SYS_GUID())),'customer.'||tok||'@x.invalid','x',SYSTIMESTAMP,'ACTIVE')RETURNING ACC_ID INTO customer_id;
  INSERT INTO BEX_PROFILE(ACC_ID,PFL_PUBLIC_ID,PFL_DISPLAY_NAME)
    VALUES(customer_id,LOWER(RAWTOHEX(SYS_GUID())),'Customer')RETURNING PFL_ID INTO customer_p;
  INSERT INTO BEX_STORE(STR_PUBLIC_ID,ACC_ID,STR_NAME,STR_SLUG)
    VALUES(sp,owner_id,'PQA Module','pqa-mod-'||tok)RETURNING STR_ID INTO s;
  INSERT INTO BEX_CATEGORY(CAT_PUBLIC_ID,CAT_NAME,CAT_SLUG)
    VALUES(LOWER(RAWTOHEX(SYS_GUID())),'PQA Mod Cat','pqa-mod-cat-'||tok)RETURNING CAT_ID INTO c;
  INSERT INTO BEX_PRODUCT(PRD_PUBLIC_ID,STR_ID,CAT_ID,PRD_TITLE,PRD_SLUG,
    PRD_PRICE,PRD_QUANTITY,PRD_CONDITION,PRD_STATUS)VALUES(pp,s,c,'PQA Mod Product',
    'pqa-mod-prd-'||tok,10,1,'GOOD','ACTIVE')RETURNING PRD_ID INTO p;
  pqa_api_pkg.ask_question(pp,'{"questionText":" Ainda disponivel? "}',customer_id,st,body);
  j:=JSON_OBJECT_T.parse(body);qpub:=j.get_object('data').get_string('questionPublicId');
  ok(st=201 AND qpub IS NOT NULL,'ASK QUESTION.');
  pqa_api_pkg.answer_question(qpub,sp,'{"answerText":" Sim, esta disponivel. "}',owner_id,st,body);
  ok(st=200,'ANSWER QUESTION.');
  pqa_api_pkg.list_questions(pp,st,body);
  j:=JSON_OBJECT_T.parse(body);
  ok(st=200 AND j.get_array('data').get_size=1,'LIST QUESTION.');
  pqa_api_pkg.moderate_question(qpub,sp,'HIDDEN',owner_id,st,body);ok(st=200,'MODERATE QUESTION.');
  pqa_api_pkg.ask_question(pp,'{"unknown":"x"}',customer_id,st,body);ok(st=400,'UNKNOWN QUESTION FIELD.');
  DELETE FROM BEX_PRODUCT_QUESTION WHERE PRD_ID=p;DELETE FROM BEX_PRODUCT WHERE PRD_ID=p;
  DELETE FROM BEX_CATEGORY WHERE CAT_ID=c;DELETE FROM BEX_STORE WHERE STR_ID=s;
  DELETE FROM BEX_PROFILE WHERE PFL_ID IN(owner_p,customer_p);
  DELETE FROM BEX_ACCOUNT WHERE ACC_ID IN(owner_id,customer_id);COMMIT;
  core_context_pkg.clear;core_trace_pkg.clear;DBMS_OUTPUT.PUT_LINE('PRODUCT_QUESTION module: PASSED');
EXCEPTION WHEN OTHERS THEN ROLLBACK;core_context_pkg.clear;core_trace_pkg.clear;RAISE;
END;
/
