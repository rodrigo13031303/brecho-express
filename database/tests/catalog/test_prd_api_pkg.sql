SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
  l_account NUMBER; l_store NUMBER; l_category NUMBER; l_brand NUMBER;
  l_token VARCHAR2(12):=LOWER(SUBSTR(RAWTOHEX(SYS_GUID()),1,12));
  l_store_pub CHAR(32):=LOWER(RAWTOHEX(SYS_GUID()));
  l_cat_pub CHAR(32):=LOWER(RAWTOHEX(SYS_GUID()));
  l_brd_pub CHAR(32):=LOWER(RAWTOHEX(SYS_GUID()));
  l_product_pub VARCHAR2(32); l_status PLS_INTEGER; l_body CLOB;
  l_json JSON_OBJECT_T; l_data JSON_OBJECT_T; l_array JSON_ARRAY_T;
  l_count PLS_INTEGER; l_request CLOB;
  PROCEDURE fail(p VARCHAR2) IS BEGIN RAISE_APPLICATION_ERROR(-20999,p); END;
  PROCEDURE ok(p BOOLEAN,m VARCHAR2) IS BEGIN IF p IS NULL OR NOT p THEN fail(m); END IF; END;
BEGIN
  SELECT COUNT(*) INTO l_count FROM USER_OBJECTS
   WHERE OBJECT_NAME='PRD_API_PKG' AND STATUS='VALID'
     AND OBJECT_TYPE IN ('PACKAGE','PACKAGE BODY');
  ok(l_count=2,'Package invalida.');
  SELECT COUNT(*) INTO l_count FROM USER_ERRORS WHERE NAME='PRD_API_PKG';
  ok(l_count=0,'Package possui erros.');
  core_security_context_pkg.clear;
  core_context_pkg.clear;
  core_trace_pkg.clear;
  core_trace_pkg.initialize;
  core_context_pkg.initialize(
    core_context_pkg.c_origin_external,
    core_context_pkg.c_mode_synchronous,
    NULL,
    FALSE
  );
  INSERT INTO BEX_ACCOUNT(
    ACC_PUBLIC_ID,ACC_EMAIL,ACC_PASSWORD_HASH,ACC_PASSWORD_CHANGED_AT,ACC_STATUS
  ) VALUES(
    LOWER(RAWTOHEX(SYS_GUID())),'api.prd.'||l_token||'@example.invalid',
    'test-hash',SYSTIMESTAMP,'ACTIVE'
  ) RETURNING ACC_ID INTO l_account;
  INSERT INTO BEX_STORE(STR_PUBLIC_ID,ACC_ID,STR_NAME,STR_SLUG)
  VALUES(l_store_pub,l_account,'API Product Store','api-prd-'||l_token)
  RETURNING STR_ID INTO l_store;
  INSERT INTO BEX_CATEGORY(CAT_PUBLIC_ID,CAT_NAME,CAT_SLUG,CAT_STATUS)
  VALUES(l_cat_pub,'API Product Category','api-prd-cat-'||l_token,'ACTIVE')
  RETURNING CAT_ID INTO l_category;
  INSERT INTO BEX_BRAND(BRD_PUBLIC_ID,BRD_NAME,BRD_SLUG,BRD_STATUS)
  VALUES(l_brd_pub,'API Product Brand','api-prd-brd-'||l_token,'ACTIVE')
  RETURNING BRD_ID INTO l_brand;
  l_request:='{"categoryPublicId":"'||TRIM(l_cat_pub)||
    '","brandPublicId":"'||TRIM(l_brd_pub)||
    '","title":"Achado API","slug":"achado-api-'||l_token||
    '","description":null,"price":25.5,"quantity":1,"condition":"GOOD"}';
  prd_api_pkg.create_product(l_store_pub,l_request,l_account,l_status,l_body);
  l_json:=JSON_OBJECT_T.parse(l_body); l_data:=l_json.get_object('data');
  ok(l_status=201 AND l_json.get_boolean('success'),'CREATE incorreto.');
  l_product_pub:=l_data.get_string('productPublicId');
  ok(l_data.get_string('title')='Achado API'
     AND l_data.get('description').is_null
     AND NOT l_data.has('prdId') AND NOT l_data.has('createdBy'),
     'Payload publico incorreto.');
  prd_api_pkg.get_product(l_product_pub,l_status,l_body);
  ok(l_status=200,'GET incorreto.');
  prd_api_pkg.patch_product(
    l_product_pub,l_store_pub,'{"price":30,"brandPublicId":null}',
    l_account,l_status,l_body
  );
  l_json:=JSON_OBJECT_T.parse(l_body);
  l_data:=l_json.get_object('data');
  ok(l_status=200 AND l_data.get_number('price')=30
     AND l_data.get('brandPublicId').is_null,'PATCH incorreto.');
  prd_api_pkg.change_status(
    l_product_pub,l_store_pub,'ACTIVE',l_account,l_status,l_body
  );
  ok(l_status=200,'STATUS incorreto.');
  prd_api_pkg.list_public_products(
    l_cat_pub,NULL,'GOOD',l_status,l_body
  );
  l_json:=JSON_OBJECT_T.parse(l_body);
  l_array:=l_json.get_array('data');
  ok(l_status=200 AND l_array.get_size=1,'LIST publico incorreto.');
  prd_api_pkg.get_product(NULL,l_status,l_body);
  ok(l_status=400,'Obrigatorio deveria retornar 400.');
  prd_api_pkg.create_product(
    l_store_pub,'{"unknown":1}',l_account,l_status,l_body
  );
  ok(l_status=400,'Campo desconhecido deveria retornar 400.');
  SELECT COUNT(*) INTO l_count FROM USER_DEPENDENCIES
   WHERE NAME='PRD_API_PKG' AND REFERENCED_NAME IN (
     'PRD_REPOSITORY_PKG','BEX_PRODUCT'
   );
  ok(l_count=0,'API acessa Repository ou tabela.');
  DELETE FROM BEX_PRODUCT WHERE PRD_PUBLIC_ID=l_product_pub;
  DELETE FROM BEX_BRAND WHERE BRD_ID=l_brand;
  DELETE FROM BEX_CATEGORY WHERE CAT_ID=l_category;
  DELETE FROM BEX_STORE WHERE STR_ID=l_store;
  DELETE FROM BEX_ACCOUNT WHERE ACC_ID=l_account;
  COMMIT;
  core_context_pkg.clear; core_trace_pkg.clear;
  DBMS_OUTPUT.PUT_LINE('PRD_API_PKG: PASSED');
EXCEPTION WHEN OTHERS THEN
  ROLLBACK; core_context_pkg.clear; core_trace_pkg.clear; RAISE;
END;
/
