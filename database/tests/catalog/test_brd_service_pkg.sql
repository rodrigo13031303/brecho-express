SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
  l_id1 BEX_BRAND.BRD_ID%TYPE; l_id2 BEX_BRAND.BRD_ID%TYPE;
  l_pub1 BEX_BRAND.BRD_PUBLIC_ID%TYPE:=LOWER(RAWTOHEX(SYS_GUID()));
  l_pub2 BEX_BRAND.BRD_PUBLIC_ID%TYPE:=LOWER(RAWTOHEX(SYS_GUID()));
  l_token VARCHAR2(12):=LOWER(SUBSTR(RAWTOHEX(SYS_GUID()),1,12));
  l_record brd_service_pkg.t_brand_record;
  l_rows brd_service_pkg.t_brand_table; l_count PLS_INTEGER;
  l_raised BOOLEAN; l_resolved BEX_BRAND.BRD_ID%TYPE;
  PROCEDURE fail(p VARCHAR2) IS BEGIN RAISE_APPLICATION_ERROR(-20999,p); END;
  PROCEDURE ok(p BOOLEAN,m VARCHAR2) IS BEGIN IF p IS NULL OR NOT p THEN fail(m); END IF; END;
BEGIN
  SELECT COUNT(*) INTO l_count FROM USER_OBJECTS
   WHERE OBJECT_NAME='BRD_SERVICE_PKG' AND STATUS='VALID'
     AND OBJECT_TYPE IN ('PACKAGE','PACKAGE BODY');
  ok(l_count=2,'Package invalida.');
  brd_repository_pkg.insert_brand(l_pub1,'Alpha Brand','alpha-'||l_token,NULL,'ACTIVE',1,1,l_id1);
  brd_repository_pkg.insert_brand(l_pub2,'Beta Brand','beta-'||l_token,NULL,'INACTIVE',1,1,l_id2);
  l_record:=brd_service_pkg.get_by_public_id(l_pub1);
  ok(TRIM(l_record.brand_public_id)=l_pub1 AND l_record.brand_name='Alpha Brand','GET.');
  l_record:=brd_service_pkg.get_by_public_id(LOWER(RAWTOHEX(SYS_GUID())));
  ok(l_record.brand_public_id IS NULL,'GET vazio.');
  l_record:=brd_service_pkg.require_by_slug(UPPER('alpha-'||l_token));
  ok(TRIM(l_record.brand_public_id)=l_pub1,'Slug.');
  l_rows:=brd_service_pkg.list_brands();
  ok(l_rows.COUNT=2 AND l_rows(1).brand_name='Alpha Brand','Lista.');
  l_rows:=brd_service_pkg.list_brands(' active ');
  ok(l_rows.COUNT=1 AND l_rows(1).status='ACTIVE','Filtro.');
  l_raised:=FALSE;
  BEGIN l_rows:=brd_service_pkg.list_brands('BLOCKED');
  EXCEPTION WHEN brd_service_pkg.e_invalid_status THEN l_raised:=SQLCODE=-20772; END;
  ok(l_raised,'Status.');
  l_resolved:=brd_service_pkg.resolve_active_brand_id(l_pub1);
  ok(l_resolved=l_id1,'Resolve.');
  ok(
    TRIM(brd_service_pkg.resolve_brand_public_id(l_id1))=TRIM(l_pub1),
    'Resolve Public ID.'
  );
  l_raised:=FALSE;
  BEGIN l_resolved:=brd_service_pkg.resolve_active_brand_id(l_pub2);
  EXCEPTION WHEN brd_service_pkg.e_brand_inactive THEN l_raised:=SQLCODE=-20771; END;
  ok(l_raised,'Inactive.');
  l_raised:=FALSE;
  BEGIN l_record:=brd_service_pkg.require_by_public_id(LOWER(RAWTOHEX(SYS_GUID())));
  EXCEPTION WHEN brd_service_pkg.e_brand_not_found THEN l_raised:=SQLCODE=-20770; END;
  ok(l_raised,'Not found.');
  SELECT COUNT(*) INTO l_count FROM USER_SOURCE
   WHERE NAME='BRD_SERVICE_PKG'
     AND REGEXP_LIKE(UPPER(TEXT),
       '(^|[^A-Z_])(SELECT|INSERT|UPDATE|DELETE|MERGE|COMMIT|ROLLBACK)([^A-Z_]|$)|JSON|HTTP|SQLERRM');
  ok(l_count=0,'Elemento proibido.');
  DBMS_OUTPUT.PUT_LINE('BRD_SERVICE_PKG: PASSED');
  ROLLBACK;
EXCEPTION WHEN OTHERS THEN ROLLBACK; RAISE;
END;
/
