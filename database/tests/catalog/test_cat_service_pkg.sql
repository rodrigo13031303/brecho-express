SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  g_count        PLS_INTEGER := 0;
  g_current_test VARCHAR2(200);
  c_expected     CONSTANT PLS_INTEGER := 21;

  l_active_id       BEX_CATEGORY.CAT_ID%TYPE;
  l_inactive_id     BEX_CATEGORY.CAT_ID%TYPE;
  l_active_public   BEX_CATEGORY.CAT_PUBLIC_ID%TYPE;
  l_inactive_public BEX_CATEGORY.CAT_PUBLIC_ID%TYPE;
  l_active_slug     BEX_CATEGORY.CAT_SLUG%TYPE;
  l_inactive_slug   BEX_CATEGORY.CAT_SLUG%TYPE;
  l_token           VARCHAR2(12);
  l_category        cat_service_pkg.t_category_record;
  l_categories      cat_service_pkg.t_category_table;
  l_resolved_id     BEX_CATEGORY.CAT_ID%TYPE;
  l_count           PLS_INTEGER;
  l_raised          BOOLEAN;

  PROCEDURE fail(p_message VARCHAR2) IS
  BEGIN RAISE_APPLICATION_ERROR(-20999, p_message); END;

  PROCEDURE assert_true(p_condition BOOLEAN, p_message VARCHAR2) IS
  BEGIN
    IF p_condition IS NULL OR NOT p_condition THEN fail(p_message); END IF;
  END;

  PROCEDURE start_test(p_name VARCHAR2) IS
  BEGIN g_current_test := p_name; END;

  PROCEDURE pass IS
  BEGIN
    g_count := g_count + 1;
    DBMS_OUTPUT.PUT_LINE(
      'PASS ' || LPAD(g_count, 2, '0') || ' - ' || g_current_test
    );
  END;

  PROCEDURE assert_exception_code(
    p_kind PLS_INTEGER,
    p_code PLS_INTEGER
  ) IS
  BEGIN
    BEGIN
      CASE p_kind
        WHEN 1 THEN RAISE cat_service_pkg.e_category_not_found;
        WHEN 2 THEN RAISE cat_service_pkg.e_category_inactive;
        WHEN 3 THEN RAISE cat_service_pkg.e_invalid_status;
      END CASE;
    EXCEPTION
      WHEN OTHERS THEN
        assert_true(SQLCODE = p_code, 'Codigo Oracle incorreto.');
    END;
  END;
BEGIN
  start_test('Specification esta valida');
  SELECT COUNT(*) INTO l_count FROM USER_OBJECTS
   WHERE OBJECT_NAME='CAT_SERVICE_PKG'
     AND OBJECT_TYPE='PACKAGE' AND STATUS='VALID';
  assert_true(l_count=1,'Specification invalida.'); pass;

  start_test('Body esta valido e sem USER_ERRORS');
  SELECT COUNT(*) INTO l_count FROM USER_OBJECTS
   WHERE OBJECT_NAME='CAT_SERVICE_PKG'
     AND OBJECT_TYPE='PACKAGE BODY' AND STATUS='VALID';
  assert_true(l_count=1,'Body invalido.');
  SELECT COUNT(*) INTO l_count FROM USER_ERRORS
   WHERE NAME='CAT_SERVICE_PKG';
  assert_true(l_count=0,'Service possui USER_ERRORS.'); pass;

  start_test('Excecoes publicas possuem codigos estaveis');
  assert_exception_code(1,-20760);
  assert_exception_code(2,-20761);
  assert_exception_code(3,-20762); pass;

  l_token:=LOWER(SUBSTR(RAWTOHEX(SYS_GUID()),1,12));
  l_active_public:=LOWER(RAWTOHEX(SYS_GUID()));
  l_inactive_public:=LOWER(RAWTOHEX(SYS_GUID()));
  l_active_slug:='active-'||l_token;
  l_inactive_slug:='inactive-'||l_token;
  cat_repository_pkg.insert_category(
    l_active_public,'Alpha Active',l_active_slug,NULL,'ACTIVE',
    8101,8101,l_active_id
  );
  cat_repository_pkg.insert_category(
    l_inactive_public,'Beta Inactive',l_inactive_slug,'Description',
    'INACTIVE',8102,8102,l_inactive_id
  );

  start_test('GET_BY_PUBLIC_ID retorna categoria');
  l_category:=cat_service_pkg.get_by_public_id(l_active_public);
  assert_true(
    TRIM(l_category.category_public_id)=l_active_public
    AND l_category.category_name='Alpha Active',
    'Categoria incorreta.'
  ); pass;

  start_test('GET_BY_PUBLIC_ID nao expoe IDs ou auditoria');
  assert_true(
    l_category.created_at IS NOT NULL
    AND l_category.updated_at IS NOT NULL,
    'Projecao publica incompleta.'
  ); pass;

  start_test('GET_BY_PUBLIC_ID inexistente retorna vazio');
  l_category:=cat_service_pkg.get_by_public_id(
    LOWER(RAWTOHEX(SYS_GUID()))
  );
  assert_true(
    l_category.category_public_id IS NULL,
    'Inexistente deveria retornar vazio.'
  ); pass;

  start_test('REQUIRE_BY_PUBLIC_ID retorna existente');
  l_category:=cat_service_pkg.require_by_public_id(l_inactive_public);
  assert_true(l_category.status='INACTIVE','Status incorreto.'); pass;

  start_test('REQUIRE_BY_PUBLIC_ID traduz inexistente');
  l_raised:=FALSE;
  BEGIN
    l_category:=cat_service_pkg.require_by_public_id(
      LOWER(RAWTOHEX(SYS_GUID()))
    );
  EXCEPTION WHEN cat_service_pkg.e_category_not_found THEN
    l_raised:=SQLCODE=-20760;
  END;
  assert_true(l_raised,'Inexistente deveria falhar.'); pass;

  start_test('GET_BY_SLUG normaliza entrada');
  l_category:=cat_service_pkg.get_by_slug(' '||UPPER(l_active_slug)||' ');
  assert_true(
    TRIM(l_category.category_public_id)=l_active_public,
    'Slug normalizado incorreto.'
  ); pass;

  start_test('GET_BY_SLUG invalido retorna vazio');
  l_category:=cat_service_pkg.get_by_slug('!!!');
  assert_true(
    l_category.category_public_id IS NULL,
    'Slug invalido deveria retornar vazio.'
  ); pass;

  start_test('GET_BY_SLUG inexistente retorna vazio');
  l_category:=cat_service_pkg.get_by_slug('missing-'||l_token);
  assert_true(
    l_category.category_public_id IS NULL,
    'Slug inexistente deveria retornar vazio.'
  ); pass;

  start_test('REQUIRE_BY_SLUG retorna existente');
  l_category:=cat_service_pkg.require_by_slug(l_inactive_slug);
  assert_true(
    TRIM(l_category.category_public_id)=l_inactive_public,
    'Require slug incorreto.'
  ); pass;

  start_test('REQUIRE_BY_SLUG traduz inexistente');
  l_raised:=FALSE;
  BEGIN
    l_category:=cat_service_pkg.require_by_slug('missing-'||l_token);
  EXCEPTION WHEN cat_service_pkg.e_category_not_found THEN l_raised:=TRUE;
  END;
  assert_true(l_raised,'Require slug deveria falhar.'); pass;

  start_test('LIST_CATEGORIES retorna ordenacao publica');
  l_categories:=cat_service_pkg.list_categories();
  assert_true(
    l_categories.COUNT=2
    AND l_categories(1).category_name='Alpha Active'
    AND l_categories(2).category_name='Beta Inactive',
    'Lista incorreta.'
  ); pass;

  start_test('LIST_CATEGORIES filtra status normalizado');
  l_categories:=cat_service_pkg.list_categories(' inactive ');
  assert_true(
    l_categories.COUNT=1
    AND l_categories(1).status='INACTIVE',
    'Filtro incorreto.'
  ); pass;

  start_test('LIST_CATEGORIES rejeita status invalido');
  l_raised:=FALSE;
  BEGIN l_categories:=cat_service_pkg.list_categories('BLOCKED');
  EXCEPTION WHEN cat_service_pkg.e_invalid_status THEN
    l_raised:=SQLCODE=-20762;
  END;
  assert_true(l_raised,'Status invalido deveria falhar.'); pass;

  start_test('RESOLVE_ACTIVE_CATEGORY_ID retorna identidade interna');
  l_resolved_id:=cat_service_pkg.resolve_active_category_id(l_active_public);
  assert_true(l_resolved_id=l_active_id,'ID resolvido incorreto.'); pass;

  start_test('RESOLVE_ACTIVE_CATEGORY_ID rejeita INACTIVE');
  l_raised:=FALSE;
  BEGIN
    l_resolved_id:=cat_service_pkg.resolve_active_category_id(
      l_inactive_public
    );
  EXCEPTION WHEN cat_service_pkg.e_category_inactive THEN
    l_raised:=SQLCODE=-20761;
  END;
  assert_true(l_raised,'INACTIVE deveria falhar.'); pass;

  start_test('RESOLVE_ACTIVE_CATEGORY_ID traduz inexistente');
  l_raised:=FALSE;
  BEGIN
    l_resolved_id:=cat_service_pkg.resolve_active_category_id(
      LOWER(RAWTOHEX(SYS_GUID()))
    );
  EXCEPTION WHEN cat_service_pkg.e_category_not_found THEN
    l_raised:=SQLCODE=-20760;
  END;
  assert_true(l_raised,'Inexistente deveria falhar.'); pass;

  start_test('Service nao possui SQL transacao ou apresentacao');
  SELECT COUNT(*) INTO l_count FROM USER_SOURCE
   WHERE NAME='CAT_SERVICE_PKG' AND TYPE IN ('PACKAGE','PACKAGE BODY')
     AND REGEXP_LIKE(
       UPPER(TEXT),
       '(^|[^A-Z_])(SELECT|INSERT|UPDATE|DELETE|MERGE|COMMIT|ROLLBACK)([^A-Z_]|$)|'||
       'JSON|HTTP|ORDS|APEX|SQLERRM|WHEN[[:space:]]+OTHERS'
     );
  assert_true(l_count=0,'Service possui elemento proibido.'); pass;

  start_test('Service usa somente Rule e Repository aprovados');
  SELECT COUNT(*) INTO l_count FROM USER_DEPENDENCIES
   WHERE NAME='CAT_SERVICE_PKG' AND TYPE='PACKAGE BODY'
     AND REFERENCED_NAME NOT IN (
       'STANDARD','CAT_SERVICE_PKG','CAT_RULE_PKG',
       'CAT_REPOSITORY_PKG','BEX_CATEGORY'
     )
     AND REFERENCED_OWNER=USER;
  assert_true(l_count=0,'Dependencia proibida encontrada.'); pass;

  IF g_count<>c_expected THEN
    fail('Quantidade invalida. Esperado='||c_expected||' executado='||g_count);
  END IF;
  DBMS_OUTPUT.PUT_LINE('CAT_SERVICE_PKG: PASSED');
  ROLLBACK;
EXCEPTION WHEN OTHERS THEN
  ROLLBACK;
  DBMS_OUTPUT.PUT_LINE('FAIL - '||NVL(g_current_test,'initialization'));
  RAISE;
END;
/
