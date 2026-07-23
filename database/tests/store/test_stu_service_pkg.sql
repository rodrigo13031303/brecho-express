SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  g_test_count   PLS_INTEGER := 0;
  g_current_test VARCHAR2(200);

  c_expected_test_count CONSTANT PLS_INTEGER := 28;

  l_owner_id             BEX_ACCOUNT.ACC_ID%TYPE;
  l_account_id_one       BEX_ACCOUNT.ACC_ID%TYPE;
  l_account_id_two       BEX_ACCOUNT.ACC_ID%TYPE;
  l_owner_public_id      BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE;
  l_account_public_one   BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE;
  l_account_public_two   BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE;
  l_store_id_one         BEX_STORE.STR_ID%TYPE;
  l_store_id_two         BEX_STORE.STR_ID%TYPE;
  l_store_public_one     BEX_STORE.STR_PUBLIC_ID%TYPE;
  l_store_public_two     BEX_STORE.STR_PUBLIC_ID%TYPE;
  l_run_token            VARCHAR2(16);
  l_member               stu_service_pkg.t_member_record;
  l_other_member         stu_service_pkg.t_member_record;
  l_members              stu_service_pkg.t_member_table;
  l_internal             stu_repository_pkg.t_store_user_record;
  l_history_id           BEX_STORE_USER.STU_ID%TYPE;
  l_raised               BOOLEAN;
  l_before               TIMESTAMP(6);

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

  PROCEDURE start_test(p_name IN VARCHAR2) IS
  BEGIN
    g_current_test := p_name;
  END start_test;

  PROCEDURE pass IS
  BEGIN
    g_test_count := g_test_count + 1;
    DBMS_OUTPUT.PUT_LINE(
      'PASS ' || LPAD(g_test_count, 2, '0') || ' - ' || g_current_test
    );
  END pass;

  PROCEDURE create_account_fixture(
    o_account_id        OUT BEX_ACCOUNT.ACC_ID%TYPE,
    o_account_public_id OUT BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE
  ) IS
  BEGIN
    o_account_public_id := LOWER(RAWTOHEX(SYS_GUID()));
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
      o_account_public_id,
      'stu.service.' || LOWER(RAWTOHEX(SYS_GUID())) || '@example.invalid',
      'stu-service-test-credential',
      SYSTIMESTAMP,
      'ACTIVE'
    )
    RETURNING ACC_ID INTO o_account_id;
  END create_account_fixture;

  PROCEDURE create_store_fixture(
    p_suffix          IN VARCHAR2,
    o_store_id        OUT BEX_STORE.STR_ID%TYPE,
    o_store_public_id OUT BEX_STORE.STR_PUBLIC_ID%TYPE
  ) IS
  BEGIN
    o_store_public_id := LOWER(RAWTOHEX(SYS_GUID()));
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
      o_store_public_id,
      l_owner_id,
      'STU Service Store ' || p_suffix,
      'stu-service-' || p_suffix || '-' || l_run_token,
      'ACTIVE'
    )
    RETURNING STR_ID INTO o_store_id;
  END create_store_fixture;

  PROCEDURE run_tests IS
    l_count        PLS_INTEGER;
    l_source_count PLS_INTEGER;
  BEGIN
    start_test('Specification esta valida');
    SELECT COUNT(*) INTO l_count FROM USER_OBJECTS
     WHERE OBJECT_NAME = 'STU_SERVICE_PKG'
       AND OBJECT_TYPE = 'PACKAGE' AND STATUS = 'VALID';
    assert_true(l_count = 1, 'Specification deve estar VALID.');
    pass;

    start_test('Body esta valido e sem USER_ERRORS');
    SELECT COUNT(*) INTO l_count FROM USER_OBJECTS
     WHERE OBJECT_NAME = 'STU_SERVICE_PKG'
       AND OBJECT_TYPE = 'PACKAGE BODY' AND STATUS = 'VALID';
    assert_true(l_count = 1, 'Body deve estar VALID.');
    SELECT COUNT(*) INTO l_count FROM USER_ERRORS
     WHERE NAME = 'STU_SERVICE_PKG'
       AND TYPE IN ('PACKAGE', 'PACKAGE BODY');
    assert_true(l_count = 0, 'Service nao pode possuir USER_ERRORS.');
    pass;

    start_test('Excecoes internas possuem codigos Oracle estaveis');
    BEGIN RAISE stu_service_pkg.e_account_not_found;
    EXCEPTION WHEN OTHERS THEN assert_true(SQLCODE = -20840, 'ACCOUNT.'); END;
    BEGIN RAISE stu_service_pkg.e_member_not_found;
    EXCEPTION WHEN OTHERS THEN assert_true(SQLCODE = -20880, 'MEMBER.'); END;
    BEGIN RAISE stu_service_pkg.e_invalid_role;
    EXCEPTION WHEN OTHERS THEN assert_true(SQLCODE = -20881, 'ROLE.'); END;
    BEGIN RAISE stu_service_pkg.e_invalid_status;
    EXCEPTION WHEN OTHERS THEN assert_true(SQLCODE = -20882, 'STATUS.'); END;
    BEGIN RAISE stu_service_pkg.e_invalid_transition;
    EXCEPTION WHEN OTHERS THEN assert_true(SQLCODE = -20883, 'TRANSITION.'); END;
    BEGIN RAISE stu_service_pkg.e_active_link_exists;
    EXCEPTION WHEN OTHERS THEN assert_true(SQLCODE = -20884, 'LINK.'); END;
    pass;

    start_test('CREATE_MEMBER cria vinculo ACTIVE');
    l_member := stu_service_pkg.create_member(
      l_store_id_one,
      l_store_public_one,
      l_account_public_one,
      ' admin ',
      l_owner_id
    );
    assert_true(
      l_member.status = 'ACTIVE'
      AND l_member.role_code = 'ADMIN',
      'CREATE_MEMBER nao criou ADMIN ACTIVE.'
    );
    pass;

    start_test('CREATE_MEMBER retorna somente identificadores publicos');
    assert_true(
      TRIM(l_member.store_public_id) = TRIM(l_store_public_one)
      AND TRIM(l_member.account_public_id) = TRIM(l_account_public_one)
      AND REGEXP_LIKE(
            TRIM(l_member.store_user_public_id),
            '^[0-9a-f]{32}$'
          ),
      'Projecao publica incorreta.'
    );
    pass;

    start_test('CREATE_MEMBER persiste auditoria por actor tecnico');
    l_internal := stu_repository_pkg.get_by_public_id(
      l_member.store_user_public_id
    );
    assert_true(
      l_internal.stu_created_by = l_owner_id
      AND l_member.joined_at IS NOT NULL
      AND l_member.created_at IS NOT NULL,
      'Auditoria inicial incorreta.'
    );
    pass;

    start_test('CREATE_MEMBER rejeita papel invalido');
    l_raised := FALSE;
    BEGIN
      l_other_member := stu_service_pkg.create_member(
        l_store_id_one, l_store_public_one, l_account_public_two,
        'OWNER', l_owner_id
      );
    EXCEPTION WHEN stu_service_pkg.e_invalid_role THEN l_raised := TRUE; END;
    assert_true(l_raised, 'Papel invalido deveria falhar.');
    pass;

    start_test('CREATE_MEMBER rejeita ACCOUNT inexistente');
    l_raised := FALSE;
    BEGIN
      l_other_member := stu_service_pkg.create_member(
        l_store_id_one, l_store_public_one, LOWER(RAWTOHEX(SYS_GUID())),
        'MANAGER', l_owner_id
      );
    EXCEPTION WHEN stu_service_pkg.e_account_not_found THEN l_raised := TRUE; END;
    assert_true(l_raised, 'ACCOUNT inexistente deveria falhar.');
    pass;

    start_test('CREATE_MEMBER rejeita vinculo ACTIVE duplicado');
    l_raised := FALSE;
    BEGIN
      l_other_member := stu_service_pkg.create_member(
        l_store_id_one, l_store_public_one, l_account_public_one,
        'COLLABORATOR', l_owner_id
      );
    EXCEPTION WHEN stu_service_pkg.e_active_link_exists THEN l_raised := TRUE; END;
    assert_true(l_raised, 'Vinculo duplicado deveria falhar.');
    pass;

    start_test('IS_ACTIVE_ADMIN identifica ADMIN da STORE');
    assert_true(
      stu_service_pkg.is_active_admin(l_store_id_one, l_account_id_one),
      'ADMIN ACTIVE deveria ser reconhecido.'
    );
    assert_false(
      stu_service_pkg.is_active_admin(l_store_id_one, l_account_id_two),
      'ACCOUNT sem vinculo nao deveria ser ADMIN.'
    );
    pass;

    start_test('COUNT_ACTIVE_ADMINS retorna contagem vigente');
    assert_true(
      stu_service_pkg.count_active_admins(l_store_id_one) = 1,
      'Contagem deveria ser 1.'
    );
    pass;

    start_test('GET_MEMBER retorna membro da STORE');
    l_other_member := stu_service_pkg.get_member(
      l_store_id_one,
      l_store_public_one,
      l_member.store_user_public_id
    );
    assert_true(
      TRIM(l_other_member.store_user_public_id) =
        TRIM(l_member.store_user_public_id),
      'GET_MEMBER retornou membro incorreto.'
    );
    pass;

    start_test('GET_MEMBER traduz membro inexistente');
    l_raised := FALSE;
    BEGIN
      l_other_member := stu_service_pkg.get_member(
        l_store_id_one, l_store_public_one, LOWER(RAWTOHEX(SYS_GUID()))
      );
    EXCEPTION WHEN stu_service_pkg.e_member_not_found THEN l_raised := TRUE; END;
    assert_true(l_raised, 'Membro inexistente deveria falhar.');
    pass;

    start_test('GET_MEMBER nao cruza STORE');
    l_raised := FALSE;
    BEGIN
      l_other_member := stu_service_pkg.get_member(
        l_store_id_two,
        l_store_public_two,
        l_member.store_user_public_id
      );
    EXCEPTION WHEN stu_service_pkg.e_member_not_found THEN l_raised := TRUE; END;
    assert_true(l_raised, 'Membro de outra STORE nao pode ser retornado.');
    pass;

    start_test('CHANGE_ROLE normaliza papel e atualiza auditoria');
    l_before := l_member.updated_at;
    l_member := stu_service_pkg.change_role(
      l_store_id_one,
      l_store_public_one,
      l_member.store_user_public_id,
      ' manager ',
      l_account_id_two
    );
    l_internal := stu_repository_pkg.get_by_public_id(
      l_member.store_user_public_id
    );
    assert_true(
      l_member.role_code = 'MANAGER'
      AND l_member.updated_at >= l_before
      AND l_internal.stu_updated_by = l_account_id_two,
      'Papel ou auditoria incorretos.'
    );
    pass;

    start_test('CHANGE_ROLE rejeita papel invalido');
    l_raised := FALSE;
    BEGIN
      l_other_member := stu_service_pkg.change_role(
        l_store_id_one, l_store_public_one, l_member.store_user_public_id,
        'OWNER', l_owner_id
      );
    EXCEPTION WHEN stu_service_pkg.e_invalid_role THEN l_raised := TRUE; END;
    assert_true(l_raised, 'Papel invalido deveria falhar.');
    pass;

    start_test('CHANGE_ROLE nao cruza STORE');
    l_raised := FALSE;
    BEGIN
      l_other_member := stu_service_pkg.change_role(
        l_store_id_two, l_store_public_two, l_member.store_user_public_id,
        'ADMIN', l_owner_id
      );
    EXCEPTION WHEN stu_service_pkg.e_member_not_found THEN l_raised := TRUE; END;
    assert_true(l_raised, 'Alteracao cruzada deveria falhar.');
    pass;

    start_test('DEACTIVATE_MEMBER inativa e preenche LEFT_AT');
    l_member := stu_service_pkg.deactivate_member(
      l_store_id_one,
      l_store_public_one,
      l_member.store_user_public_id,
      l_owner_id
    );
    assert_true(
      l_member.status = 'INACTIVE' AND l_member.left_at IS NOT NULL,
      'Inativacao incorreta.'
    );
    pass;

    start_test('ACTIVATE_MEMBER reativa e limpa LEFT_AT');
    l_member := stu_service_pkg.activate_member(
      l_store_id_one,
      l_store_public_one,
      l_member.store_user_public_id,
      l_account_id_two
    );
    assert_true(
      l_member.status = 'ACTIVE' AND l_member.left_at IS NULL,
      'Reativacao incorreta.'
    );
    pass;

    start_test('Operacoes de status persistem actor tecnico');
    l_internal := stu_repository_pkg.get_by_public_id(
      l_member.store_user_public_id
    );
    assert_true(
      l_internal.stu_updated_by = l_account_id_two,
      'Actor tecnico de status incorreto.'
    );
    pass;

    start_test('Operacoes de status rejeitam membro inexistente');
    l_raised := FALSE;
    BEGIN
      l_other_member := stu_service_pkg.deactivate_member(
        l_store_id_one, l_store_public_one, LOWER(RAWTOHEX(SYS_GUID())),
        l_owner_id
      );
    EXCEPTION WHEN stu_service_pkg.e_member_not_found THEN l_raised := TRUE; END;
    assert_true(l_raised, 'Membro inexistente deveria falhar.');
    pass;

    start_test('Reativacao duplicada gera erro de dominio');
    stu_repository_pkg.insert_store_user(
      RAWTOHEX(SYS_GUID()), l_store_id_one, l_account_id_one,
      'ATTENDANT', 'INACTIVE', TIMESTAMP '2025-01-01 10:00:00',
      l_owner_id, l_history_id
    );
    l_internal := stu_repository_pkg.get_by_id(l_history_id);
    l_raised := FALSE;
    BEGIN
      l_other_member := stu_service_pkg.activate_member(
        l_store_id_one, l_store_public_one, l_internal.stu_public_id,
        l_owner_id
      );
    EXCEPTION WHEN stu_service_pkg.e_active_link_exists THEN l_raised := TRUE; END;
    assert_true(l_raised, 'Reativacao duplicada deveria falhar.');
    pass;

    start_test('LIST_MEMBERS_BY_STORE retorna somente a STORE');
    l_other_member := stu_service_pkg.create_member(
      l_store_id_one, l_store_public_one, l_account_public_two,
      'ATTENDANT', l_owner_id
    );
    l_members := stu_service_pkg.list_members_by_store(
      l_store_id_one,
      l_store_public_one
    );
    assert_true(
      l_members.COUNT = 3
      AND TRIM(l_members(1).store_public_id) = TRIM(l_store_public_one),
      'Lista da STORE incorreta.'
    );
    pass;

    start_test('LIST_MEMBERS_BY_STORE filtra status');
    l_members := stu_service_pkg.list_members_by_store(
      l_store_id_one, l_store_public_one, ' active '
    );
    assert_true(
      l_members.COUNT = 2
      AND l_members(1).status = 'ACTIVE',
      'Filtro de status incorreto.'
    );
    pass;

    start_test('LIST_MEMBERS_BY_STORE filtra papel');
    l_members := stu_service_pkg.list_members_by_store(
      p_store_id        => l_store_id_one,
      p_store_public_id => l_store_public_one,
      p_role_code       => ' attendant '
    );
    assert_true(l_members.COUNT = 2, 'Filtro de papel incorreto.');
    pass;

    start_test('LIST_MEMBERS_BY_STORE rejeita filtros invalidos');
    l_raised := FALSE;
    BEGIN
      l_members := stu_service_pkg.list_members_by_store(
        l_store_id_one, l_store_public_one, 'BLOCKED'
      );
    EXCEPTION WHEN stu_service_pkg.e_invalid_status THEN l_raised := TRUE; END;
    assert_true(l_raised, 'Status invalido deveria falhar.');
    l_raised := FALSE;
    BEGIN
      l_members := stu_service_pkg.list_members_by_store(
        p_store_id        => l_store_id_one,
        p_store_public_id => l_store_public_one,
        p_role_code       => 'OWNER'
      );
    EXCEPTION WHEN stu_service_pkg.e_invalid_role THEN l_raised := TRUE; END;
    assert_true(l_raised, 'Papel invalido deveria falhar.');
    pass;

    start_test('Service nao possui SQL transacao ou apresentacao');
    SELECT COUNT(*) INTO l_source_count FROM USER_SOURCE
     WHERE NAME = 'STU_SERVICE_PKG' AND TYPE = 'PACKAGE BODY'
       AND REGEXP_LIKE(
         UPPER(TEXT),
         '(^|[^A-Z_])(SELECT|INSERT|UPDATE|DELETE|MERGE|COMMIT|ROLLBACK)' ||
         '([^A-Z_]|$)|EXECUTE[[:space:]]+IMMEDIATE|DBMS_SQL|' ||
         'AUTONOMOUS_TRANSACTION|SQLERRM|JSON|HTTP|ORDS|APEX|' ||
         'WHEN[[:space:]]+OTHERS'
       );
    assert_true(l_source_count = 0, 'Service possui operacao proibida.');
    pass;

    start_test('Service usa somente dependencias aciclicas aprovadas');
    SELECT COUNT(*) INTO l_source_count FROM USER_SOURCE
     WHERE NAME = 'STU_SERVICE_PKG'
       AND TYPE IN ('PACKAGE', 'PACKAGE BODY')
       AND REGEXP_LIKE(
         UPPER(TEXT),
         'STR_SERVICE_PKG|STR_REPOSITORY_PKG|LIST_STORES_BY_ACCOUNT|' ||
         'P_ACTOR_PUBLIC_ID'
       );
    assert_true(
      l_source_count = 0,
      'Service manteve contrato ou dependencia removida.'
    );

    SELECT COUNT(*) INTO l_source_count FROM USER_DEPENDENCIES
     WHERE NAME = 'STU_SERVICE_PKG'
       AND TYPE IN ('PACKAGE', 'PACKAGE BODY')
       AND REFERENCED_OWNER = USER
       AND REFERENCED_TYPE IN ('PACKAGE', 'PACKAGE BODY')
       AND REFERENCED_NAME NOT IN (
             'STU_SERVICE_PKG',
             'STU_RULE_PKG',
             'STU_REPOSITORY_PKG',
             'ACC_SERVICE_PKG'
           );
    assert_true(
      l_source_count = 0,
      'Service possui package de aplicacao nao aprovada.'
    );
    pass;
  END run_tests;
BEGIN
  l_run_token := LOWER(SUBSTR(RAWTOHEX(SYS_GUID()), 1, 16));
  create_account_fixture(l_owner_id, l_owner_public_id);
  create_account_fixture(l_account_id_one, l_account_public_one);
  create_account_fixture(l_account_id_two, l_account_public_two);
  create_store_fixture('one', l_store_id_one, l_store_public_one);
  create_store_fixture('two', l_store_id_two, l_store_public_two);

  run_tests;

  IF g_test_count <> c_expected_test_count THEN
    fail(
      'Quantidade de testes invalida. Esperado=' ||
      c_expected_test_count || ' executado=' || g_test_count
    );
  END IF;

  ROLLBACK;
  DBMS_OUTPUT.PUT_LINE('STU_SERVICE_PKG: PASSED');
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('FAIL - ' || NVL(g_current_test, 'initialization'));
    RAISE;
END;
/
