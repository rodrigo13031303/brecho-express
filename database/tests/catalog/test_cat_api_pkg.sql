SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  g_count CONSTANT PLS_INTEGER := 16;
  l_done PLS_INTEGER := 0;
  l_current VARCHAR2(200);
  l_token VARCHAR2(12);
  l_active_id BEX_CATEGORY.CAT_ID%TYPE;
  l_inactive_id BEX_CATEGORY.CAT_ID%TYPE;
  l_active_public BEX_CATEGORY.CAT_PUBLIC_ID%TYPE;
  l_inactive_public BEX_CATEGORY.CAT_PUBLIC_ID%TYPE;
  l_active_slug BEX_CATEGORY.CAT_SLUG%TYPE;
  l_inactive_slug BEX_CATEGORY.CAT_SLUG%TYPE;
  l_status PLS_INTEGER;
  l_response CLOB;
  l_envelope JSON_OBJECT_T;
  l_data JSON_OBJECT_T;
  l_error JSON_OBJECT_T;
  l_array JSON_ARRAY_T;
  l_count PLS_INTEGER;

  PROCEDURE fail(p_message VARCHAR2) IS
  BEGIN RAISE_APPLICATION_ERROR(-20999,p_message); END;
  PROCEDURE assert_true(p_condition BOOLEAN,p_message VARCHAR2) IS
  BEGIN IF p_condition IS NULL OR NOT p_condition THEN fail(p_message); END IF; END;
  PROCEDURE start_test(p_name VARCHAR2) IS BEGIN l_current:=p_name; END;
  PROCEDURE pass IS
  BEGIN
    l_done:=l_done+1;
    DBMS_OUTPUT.PUT_LINE('PASS '||LPAD(l_done,2,'0')||' - '||l_current);
  END;
  PROCEDURE free_response IS
  BEGIN
    IF l_response IS NOT NULL AND DBMS_LOB.ISTEMPORARY(l_response)=1 THEN
      DBMS_LOB.FREETEMPORARY(l_response);
    END IF;
    l_response:=NULL;
  END;
  PROCEDURE init_context IS
  BEGIN
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
  END;
  PROCEDURE parse IS
  BEGIN l_envelope:=JSON_OBJECT_T.parse(l_response); END;
  PROCEDURE assert_error(p_status PLS_INTEGER,p_code VARCHAR2) IS
  BEGIN
    assert_true(l_status=p_status,'Status incorreto.');
    parse;
    l_error:=l_envelope.get_object('error');
    assert_true(
      NOT l_envelope.get_boolean('success')
      AND l_error.get_string('code')=p_code,
      'Envelope de erro incorreto.'
    );
  END;
BEGIN
  start_test('Specification esta valida');
  SELECT COUNT(*) INTO l_count FROM USER_OBJECTS
   WHERE OBJECT_NAME='CAT_API_PKG' AND OBJECT_TYPE='PACKAGE'
     AND STATUS='VALID';
  assert_true(l_count=1,'Specification invalida.'); pass;

  start_test('Body esta valido e sem USER_ERRORS');
  SELECT COUNT(*) INTO l_count FROM USER_OBJECTS
   WHERE OBJECT_NAME='CAT_API_PKG' AND OBJECT_TYPE='PACKAGE BODY'
     AND STATUS='VALID';
  assert_true(l_count=1,'Body invalido.');
  SELECT COUNT(*) INTO l_count FROM USER_ERRORS WHERE NAME='CAT_API_PKG';
  assert_true(l_count=0,'API possui USER_ERRORS.'); pass;

  l_token:=LOWER(SUBSTR(RAWTOHEX(SYS_GUID()),1,12));
  l_active_public:=LOWER(RAWTOHEX(SYS_GUID()));
  l_inactive_public:=LOWER(RAWTOHEX(SYS_GUID()));
  l_active_slug:='api-active-'||l_token;
  l_inactive_slug:='api-inactive-'||l_token;
  cat_repository_pkg.insert_category(
    l_active_public,'API Active',l_active_slug,NULL,'ACTIVE',
    9101,9101,l_active_id
  );
  cat_repository_pkg.insert_category(
    l_inactive_public,'API Inactive',l_inactive_slug,'Hidden',
    'INACTIVE',9101,9101,l_inactive_id
  );

  start_test('GET retorna 200 e envelope oficial');
  init_context; cat_api_pkg.get_category(
    l_active_public,l_status,l_response
  ); parse;
  assert_true(
    l_status=200 AND l_envelope.get_boolean('success'),
    'GET incorreto.'
  ); pass;

  start_test('GET retorna payload publico');
  l_data:=l_envelope.get_object('data');
  assert_true(
    l_data.get_string('categoryPublicId')=l_active_public
    AND l_data.get_string('categoryName')='API Active'
    AND l_data.get_string('categorySlug')=l_active_slug
    AND l_data.get_string('status')='ACTIVE',
    'Payload incorreto.'
  ); pass;

  start_test('Payload possui null e timestamps');
  assert_true(
    l_data.get('description').is_null
    AND l_data.has('createdAt') AND l_data.has('updatedAt'),
    'Campos publicos incompletos.'
  ); pass;

  start_test('Payload nao expoe IDs internos ou auditoria');
  assert_true(
    NOT l_data.has('catId') AND NOT l_data.has('createdBy')
    AND NOT l_data.has('updatedBy'),
    'Detalhe interno exposto.'
  ); pass;

  start_test('GET exige Public ID');
  free_response; init_context;
  cat_api_pkg.get_category(' ',l_status,l_response);
  assert_error(400,'BEX-REQ-004'); pass;

  start_test('GET inexistente retorna 404');
  free_response; init_context;
  cat_api_pkg.get_category(
    LOWER(RAWTOHEX(SYS_GUID())),l_status,l_response
  );
  assert_error(404,'BEX-CAT-001'); pass;

  start_test('GET oculta CATEGORY INACTIVE');
  free_response; init_context;
  cat_api_pkg.get_category(l_inactive_public,l_status,l_response);
  assert_error(404,'BEX-CAT-001'); pass;

  start_test('GET por slug normaliza entrada');
  free_response; init_context;
  cat_api_pkg.get_category_by_slug(
    ' '||UPPER(l_active_slug)||' ',l_status,l_response
  ); parse;
  assert_true(
    l_status=200
    AND l_envelope.get_object('data').get_string(
      'categoryPublicId'
    )=l_active_public,
    'GET slug incorreto.'
  ); pass;

  start_test('GET por slug exige valor');
  free_response; init_context;
  cat_api_pkg.get_category_by_slug(NULL,l_status,l_response);
  assert_error(400,'BEX-REQ-004'); pass;

  start_test('GET por slug oculta INACTIVE');
  free_response; init_context;
  cat_api_pkg.get_category_by_slug(
    l_inactive_slug,l_status,l_response
  );
  assert_error(404,'BEX-CAT-001'); pass;

  start_test('LIST retorna somente CATEGORY ACTIVE');
  free_response; init_context;
  cat_api_pkg.list_categories(l_status,l_response); parse;
  l_array:=l_envelope.get_array('data');
  assert_true(
    l_status=200 AND l_array.get_size=1
    AND TREAT(l_array.get(0) AS JSON_OBJECT_T).get_string(
      'categoryPublicId'
    )=l_active_public,
    'Lista publica incorreta.'
  ); pass;

  start_test('API nao possui SQL transacao ou IDs internos');
  SELECT COUNT(*) INTO l_count FROM USER_SOURCE
   WHERE NAME='CAT_API_PKG' AND TYPE IN ('PACKAGE','PACKAGE BODY')
     AND REGEXP_LIKE(
       UPPER(TEXT),
       '(^|[^A-Z_])(SELECT|INSERT|UPDATE|DELETE|MERGE|COMMIT|ROLLBACK)([^A-Z_]|$)|'||
       'CAT_ID|CREATED_BY|UPDATED_BY|SQLERRM'
     );
  assert_true(l_count=0,'API possui detalhe proibido.'); pass;

  start_test('API chama somente CAT_SERVICE_PKG');
  SELECT COUNT(*) INTO l_count FROM USER_DEPENDENCIES
   WHERE NAME='CAT_API_PKG'
     AND REFERENCED_NAME IN (
       'CAT_RULE_PKG','CAT_REPOSITORY_PKG','BEX_CATEGORY'
     );
  assert_true(l_count=0,'Dependencia proibida.'); pass;

  start_test('API publica nao exige ator tecnico');
  SELECT COUNT(*) INTO l_count FROM USER_ARGUMENTS
   WHERE PACKAGE_NAME='CAT_API_PKG'
     AND ARGUMENT_NAME='P_ACTOR_ID';
  assert_true(l_count=0,'API publica nao deve exigir ator.'); pass;

  IF l_done<>g_count THEN
    fail('Quantidade invalida. Esperado='||g_count||' executado='||l_done);
  END IF;
  free_response;
  core_context_pkg.clear; core_trace_pkg.clear;
  ROLLBACK;
  DBMS_OUTPUT.PUT_LINE('CAT_API_PKG: PASSED');
EXCEPTION WHEN OTHERS THEN
  free_response;
  core_context_pkg.clear; core_trace_pkg.clear;
  ROLLBACK;
  DBMS_OUTPUT.PUT_LINE('FAIL - '||NVL(l_current,'initialization'));
  RAISE;
END;
/
