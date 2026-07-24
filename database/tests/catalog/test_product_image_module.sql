SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE
@@test_bex_product_image.sql
DECLARE
  a NUMBER;s NUMBER;c NUMBER;p NUMBER;st PLS_INTEGER;body CLOB;j JSON_OBJECT_T;
  pub VARCHAR2(32);tok VARCHAR2(12):=LOWER(SUBSTR(RAWTOHEX(SYS_GUID()),1,12));
  sp CHAR(32):=LOWER(RAWTOHEX(SYS_GUID()));pp CHAR(32):=LOWER(RAWTOHEX(SYS_GUID()));
  n PLS_INTEGER;
  PROCEDURE ok(x BOOLEAN,m VARCHAR2) IS BEGIN IF x IS NULL OR NOT x THEN RAISE_APPLICATION_ERROR(-20999,m);END IF;END;
BEGIN
  SELECT COUNT(*) INTO n FROM USER_OBJECTS WHERE OBJECT_NAME IN(
    'PIM_RULE_PKG','PIM_REPOSITORY_PKG','PIM_SERVICE_PKG','PIM_API_PKG')
    AND OBJECT_TYPE IN('PACKAGE','PACKAGE BODY')AND STATUS='VALID';
  ok(n=8,'Packages PIM invalidas.');
  SELECT COUNT(*) INTO n FROM USER_SOURCE WHERE NAME IN('PIM_RULE_PKG','PIM_SERVICE_PKG')
    AND REGEXP_LIKE(UPPER(TEXT),
      '(^|[^A-Z_])(SELECT|INSERT|UPDATE|DELETE|MERGE|COMMIT|ROLLBACK)([^A-Z_]|$)|JSON');
  ok(n=0,'Rule ou Service PIM possui elemento proibido.');
  SELECT COUNT(*) INTO n FROM USER_SOURCE WHERE NAME='PIM_REPOSITORY_PKG'
    AND REGEXP_LIKE(UPPER(TEXT),'(^|[^A-Z_])(COMMIT|ROLLBACK)([^A-Z_]|$)|JSON');
  ok(n=0,'Repository PIM possui elemento proibido.');
  SELECT COUNT(*) INTO n FROM USER_DEPENDENCIES WHERE NAME='PIM_API_PKG'
    AND REFERENCED_NAME IN('PIM_REPOSITORY_PKG','BEX_PRODUCT_IMAGE');
  ok(n=0,'API PIM ignora Service.');
  core_context_pkg.clear;core_trace_pkg.clear;core_trace_pkg.initialize;
  core_context_pkg.initialize(core_context_pkg.c_origin_external,
    core_context_pkg.c_mode_synchronous,NULL,FALSE);
  INSERT INTO BEX_ACCOUNT(ACC_PUBLIC_ID,ACC_EMAIL,ACC_PASSWORD_HASH,
    ACC_PASSWORD_CHANGED_AT,ACC_STATUS)VALUES(LOWER(RAWTOHEX(SYS_GUID())),
    'pim.mod.'||tok||'@x.invalid','x',SYSTIMESTAMP,'ACTIVE')RETURNING ACC_ID INTO a;
  INSERT INTO BEX_STORE(STR_PUBLIC_ID,ACC_ID,STR_NAME,STR_SLUG)
    VALUES(sp,a,'PIM Module','pim-mod-'||tok)RETURNING STR_ID INTO s;
  INSERT INTO BEX_CATEGORY(CAT_PUBLIC_ID,CAT_NAME,CAT_SLUG)
    VALUES(LOWER(RAWTOHEX(SYS_GUID())),'PIM Mod Cat','pim-mod-cat-'||tok)RETURNING CAT_ID INTO c;
  INSERT INTO BEX_PRODUCT(PRD_PUBLIC_ID,STR_ID,CAT_ID,PRD_TITLE,PRD_SLUG,
    PRD_PRICE,PRD_QUANTITY,PRD_CONDITION)VALUES(pp,s,c,'PIM Mod Product',
    'pim-mod-prd-'||tok,10,1,'GOOD')RETURNING PRD_ID INTO p;
  pim_api_pkg.add_image(pp,sp,'{"imageUrl":"https://img.invalid/a.jpg","altText":" Capa ","sortOrder":0,"isPrimary":true}',
    a,st,body);j:=JSON_OBJECT_T.parse(body);pub:=j.get_object('data').get_string('imagePublicId');
  ok(st=201 AND pub IS NOT NULL,'ADD IMAGE.');
  pim_api_pkg.update_image(pub,sp,'{"altText":null,"sortOrder":1}',a,st,body);
  ok(st=200,'PATCH IMAGE.');
  pim_api_pkg.list_images(pp,st,body);
  j:=JSON_OBJECT_T.parse(body);
  ok(st=200 AND j.get_array('data').get_size=1,'LIST IMAGE.');
  pim_api_pkg.deactivate_image(pub,sp,a,st,body);ok(st=200,'DEACTIVATE IMAGE.');
  pim_api_pkg.add_image(pp,sp,'{"unknown":1}',a,st,body);ok(st=400,'UNKNOWN IMAGE FIELD.');
  DELETE FROM BEX_PRODUCT_IMAGE WHERE PRD_ID=p;DELETE FROM BEX_PRODUCT WHERE PRD_ID=p;
  DELETE FROM BEX_CATEGORY WHERE CAT_ID=c;DELETE FROM BEX_STORE WHERE STR_ID=s;
  DELETE FROM BEX_ACCOUNT WHERE ACC_ID=a;COMMIT;core_context_pkg.clear;core_trace_pkg.clear;
  DBMS_OUTPUT.PUT_LINE('PRODUCT_IMAGE module: PASSED');
EXCEPTION WHEN OTHERS THEN ROLLBACK;core_context_pkg.clear;core_trace_pkg.clear;RAISE;
END;
/
