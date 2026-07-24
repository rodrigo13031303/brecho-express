SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  g_count        PLS_INTEGER := 0;
  g_current_test VARCHAR2(200);
  c_expected     CONSTANT PLS_INTEGER := 26;

  l_id_one       BEX_CATEGORY.CAT_ID%TYPE;
  l_id_two       BEX_CATEGORY.CAT_ID%TYPE;
  l_public_one   BEX_CATEGORY.CAT_PUBLIC_ID%TYPE;
  l_public_two   BEX_CATEGORY.CAT_PUBLIC_ID%TYPE;
  l_slug_one     BEX_CATEGORY.CAT_SLUG%TYPE;
  l_slug_two     BEX_CATEGORY.CAT_SLUG%TYPE;
  l_token        VARCHAR2(12);
  l_record       cat_repository_pkg.t_category_record;
  l_rows         cat_repository_pkg.t_category_table;
  l_updated      BOOLEAN;
  l_count        PLS_INTEGER;
  l_raised       BOOLEAN;
  l_now          BEX_CATEGORY.CAT_UPDATED_AT%TYPE;

  PROCEDURE fail(p_message IN VARCHAR2) IS
  BEGIN
    RAISE_APPLICATION_ERROR(-20999, p_message);
  END fail;

  PROCEDURE assert_true(p_condition BOOLEAN, p_message VARCHAR2) IS
  BEGIN
    IF p_condition IS NULL OR NOT p_condition THEN fail(p_message); END IF;
  END assert_true;

  PROCEDURE start_test(p_name VARCHAR2) IS
  BEGIN
    g_current_test := p_name;
  END start_test;

  PROCEDURE pass IS
  BEGIN
    g_count := g_count + 1;
    DBMS_OUTPUT.PUT_LINE(
      'PASS ' || LPAD(g_count, 2, '0') || ' - ' || g_current_test
    );
  END pass;
BEGIN
  start_test('Specification esta valida');
  SELECT COUNT(*) INTO l_count FROM USER_OBJECTS
   WHERE OBJECT_NAME = 'CAT_REPOSITORY_PKG'
     AND OBJECT_TYPE = 'PACKAGE' AND STATUS = 'VALID';
  assert_true(l_count = 1, 'Specification invalida.'); pass;

  start_test('Body esta valido e sem USER_ERRORS');
  SELECT COUNT(*) INTO l_count FROM USER_OBJECTS
   WHERE OBJECT_NAME = 'CAT_REPOSITORY_PKG'
     AND OBJECT_TYPE = 'PACKAGE BODY' AND STATUS = 'VALID';
  assert_true(l_count = 1, 'Body invalido.');
  SELECT COUNT(*) INTO l_count FROM USER_ERRORS
   WHERE NAME = 'CAT_REPOSITORY_PKG';
  assert_true(l_count = 0, 'Repository possui USER_ERRORS.'); pass;

  l_token := LOWER(SUBSTR(RAWTOHEX(SYS_GUID()), 1, 12));
  l_public_one := LOWER(RAWTOHEX(SYS_GUID()));
  l_public_two := LOWER(RAWTOHEX(SYS_GUID()));
  l_slug_one := 'alpha-' || l_token;
  l_slug_two := 'beta-' || l_token;

  cat_repository_pkg.insert_category(
    l_public_one, 'Alpha Category', l_slug_one, NULL, 'ACTIVE',
    7101, 7101, l_id_one
  );

  start_test('INSERT_CATEGORY retorna CAT_ID');
  assert_true(l_id_one IS NOT NULL, 'CAT_ID nao retornado.'); pass;

  start_test('INSERT_CATEGORY persiste valores preparados');
  l_record := cat_repository_pkg.get_by_id(l_id_one);
  assert_true(
    TRIM(l_record.cat_public_id) = l_public_one
    AND l_record.cat_name = 'Alpha Category'
    AND l_record.cat_slug = l_slug_one
    AND l_record.cat_description IS NULL
    AND l_record.cat_status = 'ACTIVE'
    AND l_record.cat_created_by = 7101
    AND l_record.cat_updated_by = 7101,
    'Valores persistidos incorretos.'
  ); pass;

  start_test('INSERT_CATEGORY aplica timestamps');
  assert_true(
    l_record.cat_created_at IS NOT NULL
    AND l_record.cat_updated_at IS NOT NULL,
    'Timestamps ausentes.'
  ); pass;

  cat_repository_pkg.insert_category(
    l_public_two, 'Beta Category', l_slug_two, 'Beta description',
    'INACTIVE', NULL, NULL, l_id_two
  );

  start_test('GET_BY_ID retorna todas as colunas');
  l_record := cat_repository_pkg.get_by_id(l_id_two);
  assert_true(
    l_record.cat_id = l_id_two
    AND TRIM(l_record.cat_public_id) = l_public_two
    AND l_record.cat_description = 'Beta description'
    AND l_record.cat_status = 'INACTIVE',
    'GET_BY_ID incorreto.'
  ); pass;

  start_test('GET_BY_ID inexistente propaga NO_DATA_FOUND');
  l_raised := FALSE;
  BEGIN l_record := cat_repository_pkg.get_by_id(-1);
  EXCEPTION WHEN NO_DATA_FOUND THEN l_raised := TRUE; END;
  assert_true(l_raised, 'ID inexistente deveria falhar.'); pass;

  start_test('GET_BY_PUBLIC_ID retorna categoria');
  l_record := cat_repository_pkg.get_by_public_id(l_public_one);
  assert_true(l_record.cat_id = l_id_one, 'Public ID incorreto.'); pass;

  start_test('GET_BY_PUBLIC_ID inexistente propaga NO_DATA_FOUND');
  l_raised := FALSE;
  BEGIN
    l_record := cat_repository_pkg.get_by_public_id(
      LOWER(RAWTOHEX(SYS_GUID()))
    );
  EXCEPTION WHEN NO_DATA_FOUND THEN l_raised := TRUE; END;
  assert_true(l_raised, 'Public ID inexistente deveria falhar.'); pass;

  start_test('GET_BY_SLUG retorna categoria');
  l_record := cat_repository_pkg.get_by_slug(l_slug_two);
  assert_true(l_record.cat_id = l_id_two, 'Slug incorreto.'); pass;

  start_test('GET_BY_SLUG nao normaliza entrada');
  l_raised := FALSE;
  BEGIN l_record := cat_repository_pkg.get_by_slug(UPPER(l_slug_two));
  EXCEPTION WHEN NO_DATA_FOUND THEN l_raised := TRUE; END;
  assert_true(l_raised, 'Repository nao deve normalizar slug.'); pass;

  start_test('LOCK_BY_ID encontra categoria');
  cat_repository_pkg.lock_by_id(l_id_one); pass;

  start_test('LOCK_BY_ID inexistente propaga NO_DATA_FOUND');
  l_raised := FALSE;
  BEGIN cat_repository_pkg.lock_by_id(-1);
  EXCEPTION WHEN NO_DATA_FOUND THEN l_raised := TRUE; END;
  assert_true(l_raised, 'Lock inexistente deveria falhar.'); pass;

  start_test('PUBLIC_ID_EXISTS retorna verdadeiro e falso');
  assert_true(
    cat_repository_pkg.public_id_exists(l_public_one)
    AND NOT cat_repository_pkg.public_id_exists(
      LOWER(RAWTOHEX(SYS_GUID()))
    ),
    'PUBLIC_ID_EXISTS incorreto.'
  ); pass;

  start_test('SLUG_EXISTS retorna verdadeiro e falso');
  assert_true(
    cat_repository_pkg.slug_exists(l_slug_one)
    AND NOT cat_repository_pkg.slug_exists('missing-' || l_token),
    'SLUG_EXISTS incorreto.'
  ); pass;

  start_test('LIST_ALL retorna ordenacao deterministica');
  l_rows := cat_repository_pkg.list_all();
  assert_true(
    l_rows.COUNT = 2
    AND l_rows(1).cat_name = 'Alpha Category'
    AND l_rows(2).cat_name = 'Beta Category',
    'Lista completa incorreta.'
  ); pass;

  start_test('LIST_ALL filtra status');
  l_rows := cat_repository_pkg.list_all('ACTIVE');
  assert_true(
    l_rows.COUNT = 1 AND l_rows(1).cat_id = l_id_one,
    'Filtro ACTIVE incorreto.'
  ); pass;

  start_test('LIST_ALL vazia retorna colecao vazia');
  l_rows := cat_repository_pkg.list_all('UNKNOWN');
  assert_true(l_rows.COUNT = 0, 'Lista deveria estar vazia.'); pass;

  start_test('UPDATE_CATEGORY altera dados e auditoria');
  l_now := SYSTIMESTAMP;
  cat_repository_pkg.update_category(
    l_id_one, 'Alpha Updated', l_slug_one || '-updated', 'Description',
    l_now, 7201, l_updated
  );
  l_record := cat_repository_pkg.get_by_id(l_id_one);
  assert_true(
    l_updated AND l_record.cat_name = 'Alpha Updated'
    AND l_record.cat_slug = l_slug_one || '-updated'
    AND l_record.cat_description = 'Description'
    AND l_record.cat_updated_at = l_now
    AND l_record.cat_updated_by = 7201,
    'UPDATE_CATEGORY incorreto.'
  ); pass;

  start_test('UPDATE_CATEGORY inexistente informa falso');
  cat_repository_pkg.update_category(
    -1, 'Missing', 'missing', NULL, SYSTIMESTAMP, 1, l_updated
  );
  assert_true(NOT l_updated, 'Update inexistente deveria informar falso.');
  pass;

  start_test('UPDATE_STATUS altera somente estado e auditoria');
  l_now := SYSTIMESTAMP;
  cat_repository_pkg.update_status(
    l_id_two, 'ACTIVE', l_now, 7202, l_updated
  );
  l_record := cat_repository_pkg.get_by_id(l_id_two);
  assert_true(
    l_updated AND l_record.cat_status = 'ACTIVE'
    AND l_record.cat_name = 'Beta Category'
    AND l_record.cat_updated_at = l_now
    AND l_record.cat_updated_by = 7202,
    'UPDATE_STATUS incorreto.'
  ); pass;

  start_test('UPDATE_STATUS inexistente informa falso');
  cat_repository_pkg.update_status(
    -1, 'ACTIVE', SYSTIMESTAMP, 1, l_updated
  );
  assert_true(NOT l_updated, 'Status inexistente deveria informar falso.');
  pass;

  start_test('Public ID duplicado propaga DUP_VAL_ON_INDEX');
  l_raised := FALSE;
  BEGIN
    cat_repository_pkg.insert_category(
      l_public_one, 'Duplicate Public', 'duplicate-public-' || l_token,
      NULL, 'ACTIVE', NULL, NULL, l_count
    );
  EXCEPTION WHEN DUP_VAL_ON_INDEX THEN l_raised := TRUE; END;
  assert_true(l_raised, 'Public ID duplicado deveria propagar.'); pass;

  start_test('Slug duplicado propaga DUP_VAL_ON_INDEX');
  l_raised := FALSE;
  BEGIN
    cat_repository_pkg.insert_category(
      LOWER(RAWTOHEX(SYS_GUID())), 'Duplicate Slug',
      l_slug_one || '-updated', NULL, 'ACTIVE', NULL, NULL, l_count
    );
  EXCEPTION WHEN DUP_VAL_ON_INDEX THEN l_raised := TRUE; END;
  assert_true(l_raised, 'Slug duplicado deveria propagar.'); pass;

  start_test('Status invalido propaga constraint');
  l_raised := FALSE;
  BEGIN
    cat_repository_pkg.update_status(
      l_id_one, 'BLOCKED', SYSTIMESTAMP, 1, l_updated
    );
  EXCEPTION WHEN OTHERS THEN l_raised := SQLCODE = -2290; END;
  assert_true(l_raised, 'Constraint de status deveria propagar.'); pass;

  start_test('Repository nao executa transacao ou apresentacao');
  SELECT COUNT(*) INTO l_count FROM USER_SOURCE
   WHERE NAME = 'CAT_REPOSITORY_PKG'
     AND TYPE IN ('PACKAGE', 'PACKAGE BODY')
     AND REGEXP_LIKE(
       UPPER(TEXT),
       '(^|[^A-Z_])(COMMIT|ROLLBACK)([^A-Z_]|$)|CORE_|JSON|HTTP|ORDS|' ||
       'EXECUTE[[:space:]]+IMMEDIATE|DBMS_SQL'
     );
  assert_true(l_count = 0, 'Repository possui elemento proibido.'); pass;

  IF g_count <> c_expected THEN
    fail(
      'Quantidade invalida. Esperado=' || c_expected ||
      ' executado=' || g_count
    );
  END IF;
  DBMS_OUTPUT.PUT_LINE('CAT_REPOSITORY_PKG: PASSED');
  ROLLBACK;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('FAIL - ' || NVL(g_current_test, 'initialization'));
    RAISE;
END;
/
