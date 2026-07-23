SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  g_test_count   PLS_INTEGER := 0;
  g_current_test VARCHAR2(200);

  c_expected_test_count CONSTANT PLS_INTEGER := 35;

  l_owner_id       BEX_ACCOUNT.ACC_ID%TYPE;
  l_account_id_one BEX_ACCOUNT.ACC_ID%TYPE;
  l_account_id_two BEX_ACCOUNT.ACC_ID%TYPE;
  l_account_id_empty BEX_ACCOUNT.ACC_ID%TYPE;
  l_store_id_one   BEX_STORE.STR_ID%TYPE;
  l_store_id_two   BEX_STORE.STR_ID%TYPE;
  l_stu_id_one     BEX_STORE_USER.STU_ID%TYPE;
  l_stu_id_two     BEX_STORE_USER.STU_ID%TYPE;
  l_public_id_one  BEX_STORE_USER.STU_PUBLIC_ID%TYPE;
  l_public_id_two  BEX_STORE_USER.STU_PUBLIC_ID%TYPE;
  l_run_token      VARCHAR2(16);
  l_store_user     stu_repository_pkg.t_store_user_record;
  l_store_users    stu_repository_pkg.t_store_user_table;
  l_updated        BOOLEAN;
  l_raised         BOOLEAN;

  PROCEDURE fail(p_message IN VARCHAR2) IS
  BEGIN
    RAISE_APPLICATION_ERROR(-20999, p_message);
  END fail;

  PROCEDURE assert_true(
    p_condition IN BOOLEAN,
    p_message   IN VARCHAR2
  ) IS
  BEGIN
    IF p_condition IS NULL OR NOT p_condition THEN
      fail(p_message);
    END IF;
  END assert_true;

  PROCEDURE assert_false(
    p_condition IN BOOLEAN,
    p_message   IN VARCHAR2
  ) IS
  BEGIN
    IF p_condition IS NULL OR p_condition THEN
      fail(p_message);
    END IF;
  END assert_false;

  PROCEDURE start_test(p_test_name IN VARCHAR2) IS
  BEGIN
    g_current_test := p_test_name;
  END start_test;

  PROCEDURE pass IS
  BEGIN
    g_test_count := g_test_count + 1;
    DBMS_OUTPUT.PUT_LINE(
      'PASS ' || LPAD(g_test_count, 2, '0') || ' - ' || g_current_test
    );
  END pass;

  PROCEDURE create_account_fixture(
    o_account_id OUT BEX_ACCOUNT.ACC_ID%TYPE
  ) IS
  BEGIN
    INSERT INTO BEX_ACCOUNT
    (
      ACC_PUBLIC_ID,
      ACC_EMAIL,
      ACC_PASSWORD_HASH,
      ACC_PASSWORD_CHANGED_AT,
      ACC_STATUS
    )
    VALUES
    (
      RAWTOHEX(SYS_GUID()),
      'stu.repo.' || LOWER(RAWTOHEX(SYS_GUID())) || '@example.invalid',
      'stu-repository-test-credential',
      SYSTIMESTAMP,
      'ACTIVE'
    )
    RETURNING ACC_ID INTO o_account_id;
  END create_account_fixture;

  PROCEDURE create_store_fixture(
    p_owner_id IN BEX_ACCOUNT.ACC_ID%TYPE,
    p_suffix   IN VARCHAR2,
    o_store_id OUT BEX_STORE.STR_ID%TYPE
  ) IS
  BEGIN
    INSERT INTO BEX_STORE
    (
      STR_PUBLIC_ID,
      ACC_ID,
      STR_NAME,
      STR_SLUG,
      STR_STATUS
    )
    VALUES
    (
      RAWTOHEX(SYS_GUID()),
      p_owner_id,
      'STU Repository Store ' || p_suffix,
      'stu-repository-' || p_suffix || '-' || l_run_token,
      'ACTIVE'
    )
    RETURNING STR_ID INTO o_store_id;
  END create_store_fixture;

  PROCEDURE insert_link(
    p_public_id IN BEX_STORE_USER.STU_PUBLIC_ID%TYPE,
    p_store_id  IN BEX_STORE_USER.STR_ID%TYPE,
    p_account_id IN BEX_STORE_USER.ACC_ID%TYPE,
    p_role      IN BEX_STORE_USER.STU_ROLE_CODE%TYPE,
    p_status    IN BEX_STORE_USER.STU_STATUS%TYPE,
    p_joined_at IN BEX_STORE_USER.STU_JOINED_AT%TYPE,
    o_stu_id    OUT BEX_STORE_USER.STU_ID%TYPE
  ) IS
  BEGIN
    stu_repository_pkg.insert_store_user(
      p_public_id    => p_public_id,
      p_store_id     => p_store_id,
      p_account_id   => p_account_id,
      p_role_code    => p_role,
      p_status       => p_status,
      p_joined_at    => p_joined_at,
      p_created_by   => l_owner_id,
      o_store_user_id => o_stu_id
    );
  END insert_link;

  PROCEDURE run_tests IS
    l_count       PLS_INTEGER;
    l_source_count PLS_INTEGER;
    l_temp_id     BEX_STORE_USER.STU_ID%TYPE;
    l_temp_public BEX_STORE_USER.STU_PUBLIC_ID%TYPE;
    l_left_at     BEX_STORE_USER.STU_LEFT_AT%TYPE;
    l_updated_at  BEX_STORE_USER.STU_UPDATED_AT%TYPE;
  BEGIN
    start_test('Specification esta valida');
    SELECT COUNT(*)
      INTO l_count
      FROM USER_OBJECTS
     WHERE OBJECT_NAME = 'STU_REPOSITORY_PKG'
       AND OBJECT_TYPE = 'PACKAGE'
       AND STATUS = 'VALID';
    assert_true(l_count = 1, 'Specification deve estar VALID.');
    pass;

    start_test('Body esta valido');
    SELECT COUNT(*)
      INTO l_count
      FROM USER_OBJECTS
     WHERE OBJECT_NAME = 'STU_REPOSITORY_PKG'
       AND OBJECT_TYPE = 'PACKAGE BODY'
       AND STATUS = 'VALID';
    assert_true(l_count = 1, 'Body deve estar VALID.');
    pass;

    start_test('Package nao possui USER_ERRORS');
    SELECT COUNT(*)
      INTO l_count
      FROM USER_ERRORS
     WHERE NAME = 'STU_REPOSITORY_PKG'
       AND TYPE IN ('PACKAGE', 'PACKAGE BODY');
    assert_true(l_count = 0, 'Package nao pode possuir USER_ERRORS.');
    pass;

    start_test('Dependencias de tabela estao restritas a BEX_STORE_USER');
    SELECT COUNT(*)
      INTO l_count
      FROM USER_DEPENDENCIES
     WHERE NAME = 'STU_REPOSITORY_PKG'
       AND TYPE IN ('PACKAGE', 'PACKAGE BODY')
       AND REFERENCED_TYPE = 'TABLE'
       AND REFERENCED_NAME <> 'BEX_STORE_USER';
    assert_true(l_count = 0, 'Repository depende de tabela nao permitida.');
    pass;

    start_test('Dependencias de package estao restritas a STU_RULE_PKG');
    SELECT COUNT(*)
      INTO l_count
      FROM USER_DEPENDENCIES
     WHERE NAME = 'STU_REPOSITORY_PKG'
       AND TYPE IN ('PACKAGE', 'PACKAGE BODY')
       AND REFERENCED_TYPE IN ('PACKAGE', 'PACKAGE BODY')
       AND NOT (
             REFERENCED_OWNER = USER
         AND REFERENCED_NAME IN (
               'STU_REPOSITORY_PKG',
               'STU_RULE_PKG'
             )
           )
       AND NOT (
             REFERENCED_OWNER = 'SYS'
         AND REFERENCED_NAME = 'STANDARD'
           );
    assert_true(l_count = 0, 'Repository depende de package nao permitida.');
    pass;

    start_test('Repository nao possui operacoes proibidas');
    SELECT COUNT(*)
      INTO l_source_count
      FROM USER_SOURCE
     WHERE NAME = 'STU_REPOSITORY_PKG'
       AND TYPE IN ('PACKAGE', 'PACKAGE BODY')
       AND REGEXP_LIKE(
             UPPER(TEXT),
             '(^|[^A-Z_])(COMMIT|ROLLBACK)([^A-Z_]|$)|' ||
             'AUTONOMOUS_TRANSACTION|EXECUTE[[:space:]]+IMMEDIATE|' ||
             'DBMS_SQL|JSON_OBJECT|CORE_[A-Z_]+_PKG|' ||
             '(^|[^A-Z_])(DELETE|MERGE)([^A-Z_]|$)'
           );
    assert_true(l_source_count = 0, 'Repository possui operacao proibida.');
    pass;

    start_test('INSERT_STORE_USER retorna STU_ID');
    insert_link(
      l_public_id_one,
      l_store_id_one,
      l_account_id_one,
      'ADMIN',
      'ACTIVE',
      TIMESTAMP '2026-01-01 10:00:00',
      l_stu_id_one
    );
    assert_true(l_stu_id_one IS NOT NULL, 'INSERT nao retornou STU_ID.');
    pass;

    start_test('INSERT_STORE_USER persiste todos os valores explicitos');
    l_store_user := stu_repository_pkg.get_by_id(l_stu_id_one);
    assert_true(
      l_store_user.stu_id = l_stu_id_one
      AND TRIM(l_store_user.stu_public_id) = TRIM(l_public_id_one)
      AND l_store_user.str_id = l_store_id_one
      AND l_store_user.acc_id = l_account_id_one
      AND l_store_user.stu_role_code = 'ADMIN'
      AND l_store_user.stu_status = 'ACTIVE'
      AND l_store_user.stu_joined_at = TIMESTAMP '2026-01-01 10:00:00'
      AND l_store_user.stu_created_by = l_owner_id,
      'INSERT nao preservou os valores explicitos.'
    );
    pass;

    start_test('INSERT_STORE_USER aplica defaults de auditoria');
    assert_true(
      l_store_user.stu_created_at IS NOT NULL
      AND l_store_user.stu_updated_at IS NOT NULL
      AND l_store_user.stu_updated_by IS NULL
      AND l_store_user.stu_left_at IS NULL,
      'Defaults de auditoria ou STU_LEFT_AT estao incorretos.'
    );
    pass;

    start_test('GET_BY_ID retorna todas as colunas');
    assert_true(
      l_store_user.stu_id = l_stu_id_one
      AND l_store_user.stu_public_id IS NOT NULL
      AND l_store_user.str_id IS NOT NULL
      AND l_store_user.acc_id IS NOT NULL
      AND l_store_user.stu_role_code IS NOT NULL
      AND l_store_user.stu_status IS NOT NULL
      AND l_store_user.stu_joined_at IS NOT NULL
      AND l_store_user.stu_created_at IS NOT NULL
      AND l_store_user.stu_updated_at IS NOT NULL,
      'GET_BY_ID nao retornou o record completo.'
    );
    pass;

    start_test('GET_BY_ID inexistente propaga NO_DATA_FOUND');
    l_raised := FALSE;
    BEGIN
      l_store_user := stu_repository_pkg.get_by_id(-1);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'ID inexistente deveria propagar NO_DATA_FOUND.');
    pass;

    start_test('GET_BY_PUBLIC_ID encontra registro');
    l_store_user := stu_repository_pkg.get_by_public_id(l_public_id_one);
    assert_true(l_store_user.stu_id = l_stu_id_one, 'Public ID nao foi encontrado.');
    pass;

    start_test('GET_BY_PUBLIC_ID inexistente propaga NO_DATA_FOUND');
    l_raised := FALSE;
    BEGIN
      l_store_user := stu_repository_pkg.get_by_public_id(RAWTOHEX(SYS_GUID()));
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        l_raised := TRUE;
    END;
    assert_true(
      l_raised,
      'Public ID inexistente deveria propagar NO_DATA_FOUND.'
    );
    pass;

    start_test('PUBLIC_ID_EXISTS retorna verdadeiro e falso');
    assert_true(
      stu_repository_pkg.public_id_exists(l_public_id_one),
      'Public ID deveria existir.'
    );
    assert_false(
      stu_repository_pkg.public_id_exists(RAWTOHEX(SYS_GUID())),
      'Public ID inexistente nao deveria existir.'
    );
    pass;

    start_test('GET_ACTIVE_BY_STORE_ACCOUNT encontra vinculo ACTIVE');
    l_store_user := stu_repository_pkg.get_active_by_store_account(
      l_store_id_one,
      l_account_id_one
    );
    assert_true(
      l_store_user.stu_id = l_stu_id_one
      AND l_store_user.stu_status = stu_rule_pkg.c_status_active,
      'Vinculo ACTIVE nao foi encontrado.'
    );
    pass;

    start_test('ACTIVE_LINK_EXISTS retorna verdadeiro e falso');
    assert_true(
      stu_repository_pkg.active_link_exists(
        l_store_id_one,
        l_account_id_one
      ),
      'Vinculo ACTIVE deveria existir.'
    );
    assert_false(
      stu_repository_pkg.active_link_exists(
        l_store_id_one,
        l_account_id_empty
      ),
      'Vinculo ACTIVE nao deveria existir.'
    );
    pass;

    start_test('GET_ACTIVE_BY_STORE_ACCOUNT inexistente propaga NO_DATA_FOUND');
    l_raised := FALSE;
    BEGIN
      l_store_user := stu_repository_pkg.get_active_by_store_account(
        l_store_id_one,
        l_account_id_empty
      );
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        l_raised := TRUE;
    END;
    assert_true(
      l_raised,
      'Busca ACTIVE inexistente deveria propagar NO_DATA_FOUND.'
    );
    pass;

    start_test('ACTIVE_ADMIN_EXISTS identifica ADMIN ACTIVE');
    assert_true(
      stu_repository_pkg.active_admin_exists(
        l_store_id_one,
        l_account_id_one
      ),
      'ADMIN ACTIVE deveria ser encontrado.'
    );
    assert_false(
      stu_repository_pkg.active_admin_exists(
        l_store_id_one,
        l_account_id_empty
      ),
      'ACCOUNT sem vinculo nao deveria ser ADMIN ACTIVE.'
    );
    pass;

    start_test('COUNT_ACTIVE_ADMINS conta somente ADMIN ACTIVE');
    assert_true(
      stu_repository_pkg.count_active_admins(l_store_id_one) = 1,
      'Contagem de ADMIN ACTIVE deveria ser 1.'
    );
    pass;

    start_test('UPDATE_ROLE altera papel e auditoria');
    l_updated_at := TIMESTAMP '2026-02-01 11:00:00';
    stu_repository_pkg.update_role(
      l_stu_id_one,
      'MANAGER',
      l_updated_at,
      l_account_id_two,
      l_updated
    );
    l_store_user := stu_repository_pkg.get_by_id(l_stu_id_one);
    assert_true(
      l_updated
      AND l_store_user.stu_role_code = 'MANAGER'
      AND l_store_user.stu_updated_at = l_updated_at
      AND l_store_user.stu_updated_by = l_account_id_two,
      'UPDATE_ROLE nao persistiu papel e auditoria.'
    );
    pass;

    start_test('Consultas de ADMIN refletem alteracao de papel');
    assert_false(
      stu_repository_pkg.active_admin_exists(
        l_store_id_one,
        l_account_id_one
      ),
      'Vinculo MANAGER nao deveria ser ADMIN ACTIVE.'
    );
    assert_true(
      stu_repository_pkg.count_active_admins(l_store_id_one) = 0,
      'Contagem de ADMIN ACTIVE deveria refletir novo papel.'
    );
    pass;

    start_test('UPDATE_ROLE inexistente informa falso');
    stu_repository_pkg.update_role(
      -1,
      'ADMIN',
      SYSTIMESTAMP,
      l_owner_id,
      l_updated
    );
    assert_false(l_updated, 'UPDATE_ROLE inexistente deveria informar FALSE.');
    pass;

    start_test('UPDATE_STATUS altera status left_at e auditoria');
    l_left_at := TIMESTAMP '2026-03-01 12:00:00';
    l_updated_at := TIMESTAMP '2026-03-01 12:01:00';
    stu_repository_pkg.update_status(
      l_stu_id_one,
      'INACTIVE',
      l_left_at,
      l_updated_at,
      l_owner_id,
      l_updated
    );
    l_store_user := stu_repository_pkg.get_by_id(l_stu_id_one);
    assert_true(
      l_updated
      AND l_store_user.stu_status = 'INACTIVE'
      AND l_store_user.stu_left_at = l_left_at
      AND l_store_user.stu_updated_at = l_updated_at
      AND l_store_user.stu_updated_by = l_owner_id,
      'UPDATE_STATUS nao persistiu status, left_at e auditoria.'
    );
    pass;

    start_test('UPDATE_STATUS aceita STU_LEFT_AT NULL na reativacao');
    stu_repository_pkg.update_status(
      l_stu_id_one,
      'ACTIVE',
      NULL,
      TIMESTAMP '2026-03-02 12:00:00',
      l_owner_id,
      l_updated
    );
    l_store_user := stu_repository_pkg.get_by_id(l_stu_id_one);
    assert_true(
      l_updated
      AND l_store_user.stu_status = 'ACTIVE'
      AND l_store_user.stu_left_at IS NULL,
      'Reativacao nao limpou STU_LEFT_AT recebido como NULL.'
    );
    pass;

    start_test('UPDATE_STATUS inexistente informa falso');
    stu_repository_pkg.update_status(
      -1,
      'INACTIVE',
      SYSTIMESTAMP,
      SYSTIMESTAMP,
      l_owner_id,
      l_updated
    );
    assert_false(l_updated, 'UPDATE_STATUS inexistente deveria informar FALSE.');
    pass;

    start_test('LIST_BY_STORE retorna somente vinculos da loja');
    insert_link(
      l_public_id_two,
      l_store_id_one,
      l_account_id_two,
      'ATTENDANT',
      'INACTIVE',
      TIMESTAMP '2026-01-02 10:00:00',
      l_stu_id_two
    );
    insert_link(
      RAWTOHEX(SYS_GUID()),
      l_store_id_two,
      l_account_id_two,
      'COLLABORATOR',
      'ACTIVE',
      TIMESTAMP '2026-01-03 10:00:00',
      l_temp_id
    );
    l_store_users := stu_repository_pkg.list_by_store(l_store_id_one);
    assert_true(
      l_store_users.COUNT = 2
      AND l_store_users(1).str_id = l_store_id_one
      AND l_store_users(2).str_id = l_store_id_one,
      'LIST_BY_STORE retornou conjunto incorreto.'
    );
    pass;

    start_test('LIST_BY_STORE usa ordenacao deterministica');
    assert_true(
      l_store_users(1).stu_joined_at < l_store_users(2).stu_joined_at
      OR (
        l_store_users(1).stu_joined_at = l_store_users(2).stu_joined_at
        AND l_store_users(1).stu_id < l_store_users(2).stu_id
      ),
      'Ordenacao por STU_JOINED_AT e STU_ID esta incorreta.'
    );
    pass;

    start_test('LIST_BY_STORE filtra por status');
    l_store_users := stu_repository_pkg.list_by_store(
      l_store_id_one,
      'INACTIVE'
    );
    assert_true(
      l_store_users.COUNT = 1
      AND l_store_users(1).stu_id = l_stu_id_two,
      'Filtro por status retornou conjunto incorreto.'
    );
    pass;

    start_test('LIST_BY_STORE filtra por papel');
    l_store_users := stu_repository_pkg.list_by_store(
      p_store_id  => l_store_id_one,
      p_role_code => 'ATTENDANT'
    );
    assert_true(
      l_store_users.COUNT = 1
      AND l_store_users(1).stu_id = l_stu_id_two,
      'Filtro por papel retornou conjunto incorreto.'
    );
    pass;

    start_test('LIST_BY_ACCOUNT lista lojas e filtra por status');
    l_store_users := stu_repository_pkg.list_by_account(
      l_account_id_two,
      'ACTIVE'
    );
    assert_true(
      l_store_users.COUNT = 1
      AND l_store_users(1).str_id = l_store_id_two
      AND l_store_users(1).stu_status = 'ACTIVE',
      'LIST_BY_ACCOUNT com filtro retornou conjunto incorreto.'
    );
    pass;

    start_test('Listagens sem registros retornam colecao vazia');
    l_store_users := stu_repository_pkg.list_by_account(l_account_id_empty);
    assert_true(l_store_users.COUNT = 0, 'Conta vazia deveria retornar colecao vazia.');
    l_store_users := stu_repository_pkg.list_by_store(-1);
    assert_true(l_store_users.COUNT = 0, 'Loja inexistente deveria retornar colecao vazia.');
    pass;

    start_test('Segundo vinculo ACTIVE propaga DUP_VAL_ON_INDEX');
    l_raised := FALSE;
    BEGIN
      insert_link(
        RAWTOHEX(SYS_GUID()),
        l_store_id_one,
        l_account_id_one,
        'ADMIN',
        'ACTIVE',
        TIMESTAMP '2026-04-01 10:00:00',
        l_temp_id
      );
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        l_raised := TRUE;
      WHEN OTHERS THEN
        fail('Segundo ACTIVE levantou excecao inesperada.');
    END;
    assert_true(l_raised, 'Segundo ACTIVE deveria propagar DUP_VAL_ON_INDEX.');
    pass;

    start_test('Multiplos vinculos INACTIVE sao permitidos');
    insert_link(
      RAWTOHEX(SYS_GUID()),
      l_store_id_one,
      l_account_id_empty,
      'COLLABORATOR',
      'INACTIVE',
      TIMESTAMP '2026-05-01 10:00:00',
      l_temp_id
    );
    insert_link(
      RAWTOHEX(SYS_GUID()),
      l_store_id_one,
      l_account_id_empty,
      'ATTENDANT',
      'INACTIVE',
      TIMESTAMP '2026-05-02 10:00:00',
      l_temp_id
    );
    l_store_users := stu_repository_pkg.list_by_account(
      l_account_id_empty,
      'INACTIVE'
    );
    assert_true(l_store_users.COUNT = 2, 'Historico INACTIVE deveria aceitar duplicidade.');
    pass;

    start_test('Foreign key invalida e propagada');
    l_raised := FALSE;
    BEGIN
      insert_link(
        RAWTOHEX(SYS_GUID()),
        -1,
        l_account_id_one,
        'ADMIN',
        'INACTIVE',
        SYSTIMESTAMP,
        l_temp_id
      );
    EXCEPTION
      WHEN OTHERS THEN
        IF SQLCODE = -2291 THEN
          l_raised := TRUE;
        ELSE
          fail('Foreign key invalida levantou SQLCODE inesperado.');
        END IF;
    END;
    assert_true(l_raised, 'Foreign key invalida deveria propagar ORA-02291.');
    pass;

    start_test('Operacoes permanecem sob controle da transacao chamadora');
    l_temp_public := RAWTOHEX(SYS_GUID());
    SAVEPOINT before_stu_repository_insert;
    insert_link(
      l_temp_public,
      l_store_id_two,
      l_account_id_empty,
      'MANAGER',
      'INACTIVE',
      SYSTIMESTAMP,
      l_temp_id
    );
    assert_true(
      stu_repository_pkg.public_id_exists(l_temp_public),
      'Vinculo deveria estar visivel na transacao.'
    );
    ROLLBACK TO before_stu_repository_insert;
    assert_false(
      stu_repository_pkg.public_id_exists(l_temp_public),
      'ROLLBACK TO SAVEPOINT nao reverteu a insercao.'
    );
    pass;
  END run_tests;
BEGIN
  l_run_token := LOWER(SUBSTR(RAWTOHEX(SYS_GUID()), 1, 16));
  l_public_id_one := RAWTOHEX(SYS_GUID());
  l_public_id_two := RAWTOHEX(SYS_GUID());

  create_account_fixture(l_owner_id);
  create_account_fixture(l_account_id_one);
  create_account_fixture(l_account_id_two);
  create_account_fixture(l_account_id_empty);
  create_store_fixture(l_owner_id, 'one', l_store_id_one);
  create_store_fixture(l_owner_id, 'two', l_store_id_two);

  run_tests;

  IF g_test_count <> c_expected_test_count THEN
    fail(
      'Quantidade de testes invalida. Esperado=' || c_expected_test_count ||
      ', executado=' || g_test_count
    );
  END IF;

  ROLLBACK;
  DBMS_OUTPUT.PUT_LINE('STU_REPOSITORY_PKG: PASSED');
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('FAIL - ' || NVL(g_current_test, 'initialization'));
    RAISE;
END;
/
