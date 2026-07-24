SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
  l_account NUMBER; l_store NUMBER; l_category NUMBER; l_brand NUMBER;
  l_token VARCHAR2(12):=LOWER(SUBSTR(RAWTOHEX(SYS_GUID()),1,12));
  l_store_pub CHAR(32):=LOWER(RAWTOHEX(SYS_GUID()));
  l_cat_pub CHAR(32):=LOWER(RAWTOHEX(SYS_GUID()));
  l_brd_pub CHAR(32):=LOWER(RAWTOHEX(SYS_GUID()));
  l_creation prd_rule_pkg.t_product_creation;
  l_patch prd_rule_pkg.t_product_patch;
  l_row prd_service_pkg.t_product_record;
  l_rows prd_service_pkg.t_product_table;
  l_count PLS_INTEGER; l_raised BOOLEAN;
  PROCEDURE fail(p VARCHAR2) IS BEGIN RAISE_APPLICATION_ERROR(-20999,p); END;
  PROCEDURE ok(p BOOLEAN,m VARCHAR2) IS BEGIN IF p IS NULL OR NOT p THEN fail(m); END IF; END;
BEGIN
  SELECT COUNT(*) INTO l_count FROM USER_OBJECTS
   WHERE OBJECT_NAME='PRD_SERVICE_PKG' AND STATUS='VALID'
     AND OBJECT_TYPE IN ('PACKAGE','PACKAGE BODY');
  ok(l_count=2,'Package invalida.');
  SELECT COUNT(*) INTO l_count FROM USER_ERRORS WHERE NAME='PRD_SERVICE_PKG';
  ok(l_count=0,'Package possui erros.');
  INSERT INTO BEX_ACCOUNT(
    ACC_PUBLIC_ID,ACC_EMAIL,ACC_PASSWORD_HASH,ACC_PASSWORD_CHANGED_AT,ACC_STATUS
  ) VALUES(
    LOWER(RAWTOHEX(SYS_GUID())),'service.'||l_token||'@example.invalid',
    'test-hash',SYSTIMESTAMP,'ACTIVE'
  ) RETURNING ACC_ID INTO l_account;
  INSERT INTO BEX_STORE(STR_PUBLIC_ID,ACC_ID,STR_NAME,STR_SLUG)
  VALUES(l_store_pub,l_account,'Service Store','service-'||l_token)
  RETURNING STR_ID INTO l_store;
  INSERT INTO BEX_CATEGORY(CAT_PUBLIC_ID,CAT_NAME,CAT_SLUG,CAT_STATUS)
  VALUES(l_cat_pub,'Service Category','service-cat-'||l_token,'ACTIVE')
  RETURNING CAT_ID INTO l_category;
  INSERT INTO BEX_BRAND(BRD_PUBLIC_ID,BRD_NAME,BRD_SLUG,BRD_STATUS)
  VALUES(l_brd_pub,'Service Brand','service-brd-'||l_token,'ACTIVE')
  RETURNING BRD_ID INTO l_brand;

  l_creation.title_value:='  Achado   Service ';
  l_creation.slug_value:=' Achado Service ';
  l_creation.description_value:='  Teste  '; l_creation.price_value:=10;
  l_creation.quantity_value:=1; l_creation.condition_value:=' good ';
  l_row:=prd_service_pkg.create_product(
    l_store_pub,l_cat_pub,l_brd_pub,l_creation,l_account
  );
  ok(l_row.product_public_id IS NOT NULL AND l_row.title='Achado Service'
     AND l_row.slug='achado-service' AND l_row.status='DRAFT'
     AND TRIM(l_row.store_public_id)=TRIM(l_store_pub)
     AND TRIM(l_row.category_public_id)=TRIM(l_cat_pub)
     AND TRIM(l_row.brand_public_id)=TRIM(l_brd_pub),'Create incorreto.');

  l_row:=prd_service_pkg.get_by_public_id(l_row.product_public_id);
  ok(l_row.price=10 AND l_row.created_at IS NOT NULL,'GET incorreto.');
  l_row:=prd_service_pkg.get_by_store_slug(l_store_pub,' ACHADO SERVICE ');
  ok(l_row.product_public_id IS NOT NULL,'GET slug incorreto.');
  l_rows:=prd_service_pkg.list_by_store(l_store_pub,' draft ',l_account);
  ok(l_rows.COUNT=1,'Lista administrativa incorreta.');

  l_patch.set_price:=TRUE; l_patch.price_value:=20;
  l_patch.set_description:=TRUE; l_patch.description_value:=' ';
  l_row:=prd_service_pkg.update_product(
    l_row.product_public_id,l_store_pub,l_patch,FALSE,NULL,FALSE,NULL,l_account
  );
  ok(l_row.price=20 AND l_row.description IS NULL,'Patch incorreto.');
  l_row:=prd_service_pkg.change_status(
    l_row.product_public_id,l_store_pub,' active ',l_account
  );
  ok(l_row.status='ACTIVE','Ativacao incorreta.');
  l_rows:=prd_service_pkg.list_public(l_cat_pub,l_brd_pub,' good ');
  ok(l_rows.COUNT=1 AND l_rows(1).status='ACTIVE','Lista publica incorreta.');
  l_raised:=FALSE;
  BEGIN
    l_row:=prd_service_pkg.change_status(
      l_row.product_public_id,l_store_pub,'DRAFT',l_account
    );
  EXCEPTION WHEN prd_service_pkg.e_invalid_transition THEN
    l_raised:=SQLCODE=-20783;
  END;
  ok(l_raised,'Transicao invalida nao traduzida.');
  l_raised:=FALSE;
  BEGIN l_row:=prd_service_pkg.get_by_public_id(LOWER(RAWTOHEX(SYS_GUID())));
  EXCEPTION WHEN prd_service_pkg.e_product_not_found THEN
    l_raised:=SQLCODE=-20780;
  END;
  ok(l_raised,'Inexistente nao traduzido.');
  SELECT COUNT(*) INTO l_count FROM USER_SOURCE
   WHERE NAME='PRD_SERVICE_PKG'
     AND REGEXP_LIKE(
       UPPER(TEXT),
       '(^|[^A-Z_])(SELECT|INSERT|UPDATE|DELETE|MERGE|COMMIT|ROLLBACK)([^A-Z_]|$)|JSON|HTTP|SQLERRM|WHEN[[:space:]]+OTHERS'
     );
  ok(l_count=0,'Service possui SQL, transacao ou apresentacao.');
  DBMS_OUTPUT.PUT_LINE('PRD_SERVICE_PKG: PASSED');
  ROLLBACK;
EXCEPTION WHEN OTHERS THEN ROLLBACK; RAISE;
END;
/
