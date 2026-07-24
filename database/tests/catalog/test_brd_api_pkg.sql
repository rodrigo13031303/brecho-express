SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
  l_id1 NUMBER; l_id2 NUMBER;
  l_pub1 VARCHAR2(32):=LOWER(RAWTOHEX(SYS_GUID()));
  l_pub2 VARCHAR2(32):=LOWER(RAWTOHEX(SYS_GUID()));
  l_token VARCHAR2(12):=LOWER(SUBSTR(RAWTOHEX(SYS_GUID()),1,12));
  l_status PLS_INTEGER; l_body CLOB; l_obj JSON_OBJECT_T; l_arr JSON_ARRAY_T;
  l_count PLS_INTEGER;
  PROCEDURE fail(p VARCHAR2) IS BEGIN RAISE_APPLICATION_ERROR(-20999,p); END;
  PROCEDURE ok(p BOOLEAN,m VARCHAR2) IS BEGIN IF p IS NULL OR NOT p THEN fail(m); END IF; END;
  PROCEDURE ctx IS BEGIN
    core_context_pkg.clear; core_trace_pkg.clear; core_trace_pkg.initialize;
    core_context_pkg.initialize(core_context_pkg.c_origin_external,core_context_pkg.c_mode_synchronous,NULL,FALSE);
  END;
BEGIN
  SELECT COUNT(*) INTO l_count FROM USER_OBJECTS WHERE OBJECT_NAME='BRD_API_PKG' AND STATUS='VALID' AND OBJECT_TYPE IN ('PACKAGE','PACKAGE BODY');
  ok(l_count=2,'Package invalida.');
  brd_repository_pkg.insert_brand(l_pub1,'Active Brand','active-'||l_token,NULL,'ACTIVE',1,1,l_id1);
  brd_repository_pkg.insert_brand(l_pub2,'Inactive Brand','inactive-'||l_token,NULL,'INACTIVE',1,1,l_id2);
  ctx; brd_api_pkg.get_brand(l_pub1,l_status,l_body); l_obj:=JSON_OBJECT_T.parse(l_body);
  ok(l_status=200 AND l_obj.get_boolean('success') AND l_obj.get_object('data').get_string('brandPublicId')=l_pub1,'GET.');
  brd_api_pkg.get_brand(l_pub2,l_status,l_body); l_obj:=JSON_OBJECT_T.parse(l_body);
  ok(l_status=404 AND l_obj.get_object('error').get_string('code')='BEX-BRD-001','Ocultacao.');
  brd_api_pkg.get_brand(NULL,l_status,l_body); ok(l_status=400,'Obrigatorio.');
  brd_api_pkg.get_brand_by_slug(UPPER('active-'||l_token),l_status,l_body); ok(l_status=200,'Slug.');
  brd_api_pkg.list_brands(l_status,l_body); l_obj:=JSON_OBJECT_T.parse(l_body); l_arr:=l_obj.get_array('data');
  ok(l_status=200 AND l_arr.get_size=1,'Lista.');
  SELECT COUNT(*) INTO l_count FROM USER_SOURCE WHERE NAME='BRD_API_PKG' AND REGEXP_LIKE(UPPER(TEXT),'(^|[^A-Z_])(SELECT|INSERT|UPDATE|DELETE|MERGE|COMMIT|ROLLBACK)([^A-Z_]|$)|BRD_ID|CREATED_BY|UPDATED_BY|SQLERRM');
  ok(l_count=0,'Elemento proibido.');
  SELECT COUNT(*) INTO l_count FROM USER_DEPENDENCIES WHERE NAME='BRD_API_PKG' AND REFERENCED_NAME IN ('BRD_RULE_PKG','BRD_REPOSITORY_PKG','BEX_BRAND');
  ok(l_count=0,'Dependencia proibida.');
  DBMS_OUTPUT.PUT_LINE('BRD_API_PKG: PASSED'); ROLLBACK;
EXCEPTION WHEN OTHERS THEN ROLLBACK; RAISE;
END;
/
