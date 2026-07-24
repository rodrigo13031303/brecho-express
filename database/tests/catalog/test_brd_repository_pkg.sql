SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
  l_id1 BEX_BRAND.BRD_ID%TYPE;
  l_id2 BEX_BRAND.BRD_ID%TYPE;
  l_pub1 BEX_BRAND.BRD_PUBLIC_ID%TYPE:=LOWER(RAWTOHEX(SYS_GUID()));
  l_pub2 BEX_BRAND.BRD_PUBLIC_ID%TYPE:=LOWER(RAWTOHEX(SYS_GUID()));
  l_token VARCHAR2(12):=LOWER(SUBSTR(RAWTOHEX(SYS_GUID()),1,12));
  l_slug1 BEX_BRAND.BRD_SLUG%TYPE;
  l_slug2 BEX_BRAND.BRD_SLUG%TYPE;
  l_record brd_repository_pkg.t_brand_record;
  l_rows brd_repository_pkg.t_brand_table;
  l_updated BOOLEAN;
  l_raised BOOLEAN;
  l_count PLS_INTEGER;
  PROCEDURE fail(p VARCHAR2) IS BEGIN RAISE_APPLICATION_ERROR(-20999,p); END;
  PROCEDURE ok(p BOOLEAN,m VARCHAR2) IS BEGIN IF p IS NULL OR NOT p THEN fail(m); END IF; END;
BEGIN
  SELECT COUNT(*) INTO l_count FROM USER_OBJECTS
   WHERE OBJECT_NAME='BRD_REPOSITORY_PKG' AND STATUS='VALID'
     AND OBJECT_TYPE IN ('PACKAGE','PACKAGE BODY');
  ok(l_count=2,'Package invalida.');
  SELECT COUNT(*) INTO l_count FROM USER_ERRORS
   WHERE NAME='BRD_REPOSITORY_PKG';
  ok(l_count=0,'Package possui erros.');
  l_slug1:='alpha-'||l_token; l_slug2:='beta-'||l_token;
  brd_repository_pkg.insert_brand(
    l_pub1,'Alpha Brand',l_slug1,NULL,'ACTIVE',101,101,l_id1
  );
  brd_repository_pkg.insert_brand(
    l_pub2,'Beta Brand',l_slug2,'Description','INACTIVE',102,102,l_id2
  );
  ok(l_id1 IS NOT NULL AND l_id2 IS NOT NULL,'IDs ausentes.');
  l_record:=brd_repository_pkg.get_by_id(l_id1);
  ok(
    TRIM(l_record.brd_public_id)=l_pub1
    AND l_record.brd_name='Alpha Brand'
    AND l_record.brd_created_at IS NOT NULL,
    'GET ID incorreto.'
  );
  l_record:=brd_repository_pkg.get_by_public_id(l_pub2);
  ok(l_record.brd_id=l_id2,'GET Public ID incorreto.');
  l_record:=brd_repository_pkg.get_by_slug(l_slug1);
  ok(l_record.brd_id=l_id1,'GET slug incorreto.');
  l_raised:=FALSE;
  BEGIN l_record:=brd_repository_pkg.get_by_id(-1);
  EXCEPTION WHEN NO_DATA_FOUND THEN l_raised:=TRUE; END;
  ok(l_raised,'Ausencia deveria propagar.');
  brd_repository_pkg.lock_by_id(l_id1);
  ok(
    brd_repository_pkg.public_id_exists(l_pub1)
    AND NOT brd_repository_pkg.public_id_exists(LOWER(RAWTOHEX(SYS_GUID()))),
    'Public exists.'
  );
  ok(
    brd_repository_pkg.slug_exists(l_slug1)
    AND NOT brd_repository_pkg.slug_exists('missing-'||l_token),
    'Slug exists.'
  );
  l_rows:=brd_repository_pkg.list_all();
  ok(
    l_rows.COUNT=2 AND l_rows(1).brd_name='Alpha Brand'
    AND l_rows(2).brd_name='Beta Brand',
    'Lista incorreta.'
  );
  l_rows:=brd_repository_pkg.list_all('ACTIVE');
  ok(l_rows.COUNT=1 AND l_rows(1).brd_id=l_id1,'Filtro incorreto.');
  brd_repository_pkg.update_brand(
    l_id1,'Alpha Updated',l_slug1||'-updated','Text',
    SYSTIMESTAMP,201,l_updated
  );
  l_record:=brd_repository_pkg.get_by_id(l_id1);
  ok(
    l_updated AND l_record.brd_name='Alpha Updated'
    AND l_record.brd_updated_by=201,
    'Update incorreto.'
  );
  brd_repository_pkg.update_status(
    l_id2,'ACTIVE',SYSTIMESTAMP,202,l_updated
  );
  l_record:=brd_repository_pkg.get_by_id(l_id2);
  ok(l_updated AND l_record.brd_status='ACTIVE','Status incorreto.');
  brd_repository_pkg.update_status(-1,'ACTIVE',SYSTIMESTAMP,1,l_updated);
  ok(NOT l_updated,'Update inexistente.');
  l_raised:=FALSE;
  BEGIN
    brd_repository_pkg.insert_brand(
      l_pub1,'Duplicate','dup-'||l_token,NULL,'ACTIVE',NULL,NULL,l_count
    );
  EXCEPTION WHEN DUP_VAL_ON_INDEX THEN l_raised:=TRUE; END;
  ok(l_raised,'Public duplicado.');
  l_raised:=FALSE;
  BEGIN
    brd_repository_pkg.update_status(
      l_id1,'BLOCKED',SYSTIMESTAMP,1,l_updated
    );
  EXCEPTION WHEN OTHERS THEN l_raised:=SQLCODE=-2290; END;
  ok(l_raised,'Status fisico.');
  SELECT COUNT(*) INTO l_count FROM USER_SOURCE
   WHERE NAME='BRD_REPOSITORY_PKG'
     AND REGEXP_LIKE(
       UPPER(TEXT),
       '(^|[^A-Z_])(COMMIT|ROLLBACK)([^A-Z_]|$)|CORE_|JSON|HTTP|EXECUTE[[:space:]]+IMMEDIATE'
     );
  ok(l_count=0,'Elemento proibido.');
  DBMS_OUTPUT.PUT_LINE('BRD_REPOSITORY_PKG: PASSED');
  ROLLBACK;
EXCEPTION WHEN OTHERS THEN ROLLBACK; RAISE;
END;
/
