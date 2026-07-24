SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
  l_account NUMBER; l_store NUMBER; l_category NUMBER; l_brand NUMBER;
  l_id1 NUMBER; l_id2 NUMBER; l_id3 NUMBER; l_count PLS_INTEGER;
  l_token VARCHAR2(12):=LOWER(SUBSTR(RAWTOHEX(SYS_GUID()),1,12));
  l_pub1 CHAR(32):=LOWER(RAWTOHEX(SYS_GUID()));
  l_pub2 CHAR(32):=LOWER(RAWTOHEX(SYS_GUID()));
  l_pub3 CHAR(32):=LOWER(RAWTOHEX(SYS_GUID()));
  l_row prd_repository_pkg.t_product_record;
  l_rows prd_repository_pkg.t_product_table;
  l_updated BOOLEAN; l_raised BOOLEAN;
  PROCEDURE fail(p VARCHAR2) IS BEGIN RAISE_APPLICATION_ERROR(-20999,p); END;
  PROCEDURE ok(p BOOLEAN,m VARCHAR2) IS BEGIN IF p IS NULL OR NOT p THEN fail(m); END IF; END;
  PROCEDURE prepare_row(
    p_public_id CHAR,p_title VARCHAR2,p_slug VARCHAR2,
    p_status VARCHAR2,p_quantity NUMBER
  ) IS
  BEGIN
    l_row.prd_public_id:=p_public_id; l_row.str_id:=l_store;
    l_row.cat_id:=l_category; l_row.brd_id:=l_brand;
    l_row.prd_title:=p_title; l_row.prd_slug:=p_slug;
    l_row.prd_description:=NULL; l_row.prd_price:=10;
    l_row.prd_quantity:=p_quantity; l_row.prd_condition:='GOOD';
    l_row.prd_weight:=NULL; l_row.prd_width:=NULL;
    l_row.prd_height:=NULL; l_row.prd_length:=NULL;
    l_row.prd_status:=p_status; l_row.prd_created_by:=101;
    l_row.prd_updated_by:=101;
  END;
BEGIN
  SELECT COUNT(*) INTO l_count FROM USER_OBJECTS
   WHERE OBJECT_NAME='PRD_REPOSITORY_PKG' AND STATUS='VALID'
     AND OBJECT_TYPE IN ('PACKAGE','PACKAGE BODY');
  ok(l_count=2,'Package invalida.');
  SELECT COUNT(*) INTO l_count FROM USER_ERRORS
   WHERE NAME='PRD_REPOSITORY_PKG';
  ok(l_count=0,'Package possui erros.');

  INSERT INTO BEX_ACCOUNT(
    ACC_PUBLIC_ID,ACC_EMAIL,ACC_PASSWORD_HASH,
    ACC_PASSWORD_CHANGED_AT,ACC_STATUS
  ) VALUES(
    LOWER(RAWTOHEX(SYS_GUID())),'repo.'||l_token||'@example.invalid',
    'test-hash',SYSTIMESTAMP,'ACTIVE'
  ) RETURNING ACC_ID INTO l_account;
  INSERT INTO BEX_STORE(STR_PUBLIC_ID,ACC_ID,STR_NAME,STR_SLUG)
  VALUES(
    LOWER(RAWTOHEX(SYS_GUID())),l_account,'Repository Store',
    'repo-store-'||l_token
  ) RETURNING STR_ID INTO l_store;
  INSERT INTO BEX_CATEGORY(CAT_PUBLIC_ID,CAT_NAME,CAT_SLUG)
  VALUES(
    LOWER(RAWTOHEX(SYS_GUID())),'Repository Category','repo-cat-'||l_token
  ) RETURNING CAT_ID INTO l_category;
  INSERT INTO BEX_BRAND(BRD_PUBLIC_ID,BRD_NAME,BRD_SLUG)
  VALUES(
    LOWER(RAWTOHEX(SYS_GUID())),'Repository Brand','repo-brd-'||l_token
  ) RETURNING BRD_ID INTO l_brand;

  prepare_row(l_pub1,'Active Product','active-'||l_token,'ACTIVE',1);
  prd_repository_pkg.insert_product(l_row,l_id1);
  prepare_row(l_pub2,'Draft Product','draft-'||l_token,'DRAFT',1);
  prd_repository_pkg.insert_product(l_row,l_id2);
  prepare_row(l_pub3,'Empty Product','empty-'||l_token,'ACTIVE',0);
  prd_repository_pkg.insert_product(l_row,l_id3);
  ok(l_id1 IS NOT NULL AND l_id2 IS NOT NULL AND l_id3 IS NOT NULL,
     'Insert nao retornou IDs.');

  l_row:=prd_repository_pkg.get_by_id(l_id1);
  ok(TRIM(l_row.prd_public_id)=TRIM(l_pub1)
     AND l_row.prd_title='Active Product'
     AND l_row.prd_created_at IS NOT NULL,'GET ID incorreto.');
  l_row:=prd_repository_pkg.get_by_public_id(l_pub2);
  ok(l_row.prd_id=l_id2,'GET Public ID incorreto.');
  l_row:=prd_repository_pkg.get_by_store_slug(
    l_store,'active-'||l_token
  );
  ok(l_row.prd_id=l_id1,'GET STORE/slug incorreto.');
  l_raised:=FALSE;
  BEGIN l_row:=prd_repository_pkg.get_by_id(-1);
  EXCEPTION WHEN NO_DATA_FOUND THEN l_raised:=TRUE; END;
  ok(l_raised,'Ausencia deve propagar NO_DATA_FOUND.');
  prd_repository_pkg.lock_by_id(l_id1);

  ok(prd_repository_pkg.public_id_exists(l_pub1)
     AND NOT prd_repository_pkg.public_id_exists(
       LOWER(RAWTOHEX(SYS_GUID()))
     ),'Public ID exists incorreto.');
  ok(prd_repository_pkg.slug_exists(l_store,'active-'||l_token)
     AND NOT prd_repository_pkg.slug_exists(
       l_store,'active-'||l_token,l_id1
     ),'Slug exists/exclusao incorreto.');

  l_rows:=prd_repository_pkg.list_by_store(l_store);
  ok(l_rows.COUNT=3,'Lista da STORE incorreta.');
  l_rows:=prd_repository_pkg.list_by_store(l_store,'DRAFT');
  ok(l_rows.COUNT=1 AND l_rows(1).prd_id=l_id2,
     'Filtro administrativo incorreto.');
  l_rows:=prd_repository_pkg.list_public(
    l_category,l_brand,'GOOD'
  );
  ok(l_rows.COUNT=1 AND l_rows(1).prd_id=l_id1,
     'Catalogo publico incorreto.');
  l_rows:=prd_repository_pkg.list_public(l_category,l_brand,'NEW');
  ok(l_rows.COUNT=0,'Filtro publico vazio incorreto.');

  l_row:=prd_repository_pkg.get_by_id(l_id2);
  l_row.prd_title:='Updated Product'; l_row.prd_description:='Text';
  l_row.prd_price:=25.50; l_row.prd_updated_at:=SYSTIMESTAMP;
  l_row.prd_updated_by:=202;
  prd_repository_pkg.update_product(l_row,l_updated);
  l_row:=prd_repository_pkg.get_by_id(l_id2);
  ok(l_updated AND l_row.prd_title='Updated Product'
     AND l_row.prd_price=25.50 AND l_row.prd_updated_by=202,
     'Update incorreto.');
  prd_repository_pkg.update_product(l_row,l_updated);
  ok(l_updated,'Update existente nao reconhecido.');
  l_row.prd_id:=-1;
  prd_repository_pkg.update_product(l_row,l_updated);
  ok(NOT l_updated,'Update inexistente incorreto.');

  prd_repository_pkg.update_status(
    l_id2,'ACTIVE',SYSTIMESTAMP,303,l_updated
  );
  l_row:=prd_repository_pkg.get_by_id(l_id2);
  ok(l_updated AND l_row.prd_status='ACTIVE'
     AND l_row.prd_updated_by=303,'Status incorreto.');
  prd_repository_pkg.update_status(-1,'ACTIVE',SYSTIMESTAMP,1,l_updated);
  ok(NOT l_updated,'Status inexistente incorreto.');

  SELECT COUNT(*) INTO l_count FROM USER_DEPENDENCIES
   WHERE NAME='PRD_REPOSITORY_PKG' AND REFERENCED_TYPE='TABLE'
     AND REFERENCED_NAME<>'BEX_PRODUCT';
  ok(l_count=0,'Repository depende de tabela nao permitida.');
  SELECT COUNT(*) INTO l_count FROM USER_SOURCE
   WHERE NAME='PRD_REPOSITORY_PKG'
     AND REGEXP_LIKE(
       UPPER(TEXT),
       '(^|[^A-Z_])(COMMIT|ROLLBACK)([^A-Z_]|$)|CORE_|JSON|HTTP|EXECUTE[[:space:]]+IMMEDIATE'
     );
  ok(l_count=0,'Elemento proibido.');
  DBMS_OUTPUT.PUT_LINE('PRD_REPOSITORY_PKG: PASSED');
  ROLLBACK;
EXCEPTION WHEN OTHERS THEN ROLLBACK; RAISE;
END;
/
