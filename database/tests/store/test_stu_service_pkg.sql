SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  g_test_count   PLS_INTEGER := 0;
  g_current_test VARCHAR2(200);

  c_expected_test_count CONSTANT PLS_INTEGER := 33;

  l_owner_id         BEX_ACCOUNT.ACC_ID%TYPE;
  l_account_id_one   BEX_ACCOUNT.ACC_ID%TYPE;
  l_account_id_two   BEX_ACCOUNT.ACC_ID%TYPE;
  l_empty_account_id BEX_ACCOUNT.ACC_ID%TYPE;
  l_owner_public_id  BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE;
  l_account_public_id_one BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE;
  l_account_public_id_two BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE;
  l_empty_account_public_id BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE;
  l_store_id_one     BEX_STORE.STR_ID%TYPE;
  l_store_id_two     BEX_STORE.STR_ID%TYPE;
  l_store_public_id_one BEX_STORE.STR_PUBLIC_ID%TYPE;
  l_store_public_id_two BEX_STORE.STR_PUBLIC_ID%TYPE;
  l_run_token        VARCHAR2(16);
  l_member           stu_service_pkg.t_member_record;
  l_other_member     stu_service_pkg.t_member_record;
  l_members          stu_service_pkg.t_member_table;
  l_internal         stu_repository_pkg.t_store_user_record;
  l_raised           BOOLEAN;

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

  PROCEDURE assert_exception_code(
    p_index         IN PLS_INTEGER,
    p_expected_code IN PLS_INTEGER
  ) IS
  BEGIN
    BEGIN
      CASE p_index
        WHEN 1 THEN RAISE stu_service_pkg.e_store_not_found;
        WHEN 2 THEN RAISE stu_service_pkg.e_account_not_found;
        WHEN 3 THEN RAISE stu_service_pkg.e_member_not_found;
        WHEN 4 THEN RAISE stu_service_pkg.e_invalid_role;
        WHEN 5 THEN RAISE stu_service_pkg.e_invalid_status;
        WHEN 6 THEN RAISE stu_service_pkg.e_invalid_transition;
        WHEN 7 THEN RAISE stu_service_pkg.e_active_link_exists;
        WHEN 8 THEN RAISE stu_service_pkg.e_actor_not_found;
        ELSE RAISE VALUE_ERROR;
      END CASE;
    EXCEPTION
      WHEN OTHERS THEN
        IF SQLCODE <> p_expected_code THEN
          fail('Codigo Oracle incorreto para excecao ' || p_index || '.');
        END IF;
    END;
  END assert_exception_code;

  PROCEDURE run_tests IS
    l_count        PLS_INTEGER;
    l_source_count PLS_INTEGER;
    l_history_id   BEX_STORE_USER.STU_ID%TYPE;
    l_before       TIMESTAMP(6);
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

    start_test('Excecoes publicas possuem codigos Oracle estaveis');
    assert_exception_code(1, -20860);
    assert_exception_code(2, -20840);
    FOR i IN 3..8 LOOP
      assert_exception_code(i, -20877 - i);
    END LOOP;
    pass;

    start_test('CREATE_MEMBER cria vinculo ACTIVE');
    l_member := stu_service_pkg.create_member(
      l_store_public_id_one,
      l_account_public_id_one,
      ' admin ',
      l_owner_public_id
    );
    assert_true(
      l_member.store_user_public_id IS NOT NULL
      AND TRIM(l_member.store_public_id) = TRIM(l_store_public_id_one)
      AND TRIM(l_member.account_public_id) =
          TRIM(l_account_public_id_one)
      AND l_member.role_code = 'ADMIN'
      AND l_member.status = 'ACTIVE',
      'Membro criado incorretamente.'
    );
    pass;

    start_test('CREATE_MEMBER gera Public ID hexadecimal minusculo');
    assert_true(
      LENGTH(TRIM(l_member.store_user_public_id)) = 32
      AND REGEXP_LIKE(
            TRIM(l_member.store_user_public_id),
            '^[0-9a-f]{32}$',
            'c'
          ),
      'Public ID deve ser hexadecimal minusculo.'
    );
    pass;

    start_test('CREATE_MEMBER persiste timestamps e auditoria');
    l_internal := stu_repository_pkg.get_by_public_id(
      l_member.store_user_public_id
    );
    assert_true(
      l_member.joined_at IS NOT NULL
      AND l_member.created_at IS NOT NULL
      AND l_member.updated_at IS NOT NULL
      AND l_internal.stu_created_by = l_owner_id,
      'Timestamps ou auditoria inicial incorretos.'
    );
    pass;

    start_test('CREATE_MEMBER rejeita papel invalido');
    l_raised := FALSE;
    BEGIN
      l_other_member := stu_service_pkg.create_member(
        l_store_public_id_one,
        l_account_public_id_two,
        'OWNER',
        l_owner_public_id
      );
    EXCEPTION
      WHEN stu_service_pkg.e_invalid_role THEN
        l_raised := SQLCODE = -20881;
    END;
    assert_true(l_raised, 'Papel invalido deveria gerar erro de dominio.');
    pass;

    start_test('CREATE_MEMBER rejeita conta inexistente');
    l_raised := FALSE;
    BEGIN
      l_other_member := stu_service_pkg.create_member(
        l_store_public_id_one,
        LOWER(RAWTOHEX(SYS_GUID())),
        'MANAGER',
        l_owner_public_id
      );
    EXCEPTION
      WHEN stu_service_pkg.e_account_not_found THEN
        l_raised := SQLCODE = -20840;
    END;
    assert_true(l_raised, 'Conta inexistente deveria falhar.');
    pass;

    start_test('CREATE_MEMBER rejeita loja inexistente');
    l_raised := FALSE;
    BEGIN
      l_other_member := stu_service_pkg.create_member(
        LOWER(RAWTOHEX(SYS_GUID())),
        l_account_public_id_two,
        'MANAGER',
        l_owner_public_id
      );
    EXCEPTION
      WHEN stu_service_pkg.e_store_not_found THEN
        l_raised := SQLCODE = -20860;
    END;
    assert_true(l_raised, 'Loja inexistente deveria falhar.');
    pass;

    start_test('CREATE_MEMBER rejeita vinculo ACTIVE duplicado');
    l_raised := FALSE;
    BEGIN
      l_other_member := stu_service_pkg.create_member(
        l_store_public_id_one,
        l_account_public_id_one,
        'COLLABORATOR',
        l_owner_public_id
      );
    EXCEPTION
      WHEN stu_service_pkg.e_active_link_exists THEN
        l_raised := SQLCODE = -20884;
    END;
    assert_true(l_raised, 'Vinculo ACTIVE duplicado deveria falhar.');
    pass;

    start_test('CREATE_MEMBER rejeita actor inexistente');
    l_raised := FALSE;
    BEGIN
      l_other_member := stu_service_pkg.create_member(
        l_store_public_id_one,
        l_account_public_id_two,
        'MANAGER',
        LOWER(RAWTOHEX(SYS_GUID()))
      );
    EXCEPTION
      WHEN stu_service_pkg.e_actor_not_found THEN
        l_raised := SQLCODE = -20885;
    END;
    assert_true(l_raised, 'Actor inexistente deveria gerar erro de dominio.');
    pass;

    start_test('GET_MEMBER retorna membro existente');
    l_other_member := stu_service_pkg.get_member(
      l_member.store_user_public_id
    );
    assert_true(
      TRIM(l_other_member.store_public_id) = TRIM(l_store_public_id_one)
      AND TRIM(l_other_member.account_public_id) =
          TRIM(l_account_public_id_one),
      'GET_MEMBER retornou membro incorreto.'
    );
    pass;

    start_test('GET_MEMBER traduz NO_DATA_FOUND');
    l_raised := FALSE;
    BEGIN
      l_other_member := stu_service_pkg.get_member(
        LOWER(RAWTOHEX(SYS_GUID()))
      );
    EXCEPTION
      WHEN stu_service_pkg.e_member_not_found THEN
        l_raised := SQLCODE = -20880;
    END;
    assert_true(l_raised, 'Membro inexistente deveria gerar erro de dominio.');
    pass;

    start_test('CHANGE_ROLE normaliza e atualiza papel');
    l_before := l_member.updated_at;
    l_member := stu_service_pkg.change_role(
      l_member.store_user_public_id,
      ' manager ',
      l_account_public_id_two
    );
    assert_true(
      l_member.role_code = 'MANAGER'
      AND l_member.updated_at >= l_before,
      'Papel ou auditoria nao foram atualizados.'
    );
    l_internal := stu_repository_pkg.get_by_public_id(
      l_member.store_user_public_id
    );
    assert_true(
      l_internal.stu_updated_by = l_account_id_two,
      'Actor de auditoria do papel esta incorreto.'
    );
    pass;

    start_test('CHANGE_ROLE rejeita papel invalido');
    l_raised := FALSE;
    BEGIN
      l_other_member := stu_service_pkg.change_role(
        l_member.store_user_public_id,
        'OWNER',
        l_owner_public_id
      );
    EXCEPTION
      WHEN stu_service_pkg.e_invalid_role THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'CHANGE_ROLE deveria rejeitar papel invalido.');
    pass;

    start_test('CHANGE_ROLE rejeita membro inexistente');
    l_raised := FALSE;
    BEGIN
      l_other_member := stu_service_pkg.change_role(
        LOWER(RAWTOHEX(SYS_GUID())),
        'ADMIN',
        l_owner_public_id
      );
    EXCEPTION
      WHEN stu_service_pkg.e_member_not_found THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'CHANGE_ROLE deveria rejeitar membro inexistente.');
    pass;

    start_test('DEACTIVATE_MEMBER inativa e preenche LEFT_AT');
    l_before := l_member.updated_at;
    l_member := stu_service_pkg.deactivate_member(
      l_member.store_user_public_id,
      l_owner_public_id
    );
    assert_true(
      l_member.status = 'INACTIVE'
      AND l_member.left_at IS NOT NULL
      AND l_member.updated_at >= l_before,
      'Inativacao ou auditoria incorreta.'
    );
    l_internal := stu_repository_pkg.get_by_public_id(
      l_member.store_user_public_id
    );
    assert_true(
      l_internal.stu_updated_by = l_owner_id,
      'Actor de auditoria da inativacao esta incorreto.'
    );
    pass;

    start_test('ACTIVATE_MEMBER reativa e limpa LEFT_AT');
    l_member := stu_service_pkg.activate_member(
      l_member.store_user_public_id,
      l_account_public_id_two
    );
    assert_true(
      l_member.status = 'ACTIVE'
      AND l_member.left_at IS NULL,
      'Reativacao ou auditoria incorreta.'
    );
    l_internal := stu_repository_pkg.get_by_public_id(
      l_member.store_user_public_id
    );
    assert_true(
      l_internal.stu_updated_by = l_account_id_two,
      'Actor de auditoria da reativacao esta incorreto.'
    );
    pass;

    start_test('Operacoes de status rejeitam membro inexistente');
    l_raised := FALSE;
    BEGIN
      l_other_member := stu_service_pkg.activate_member(
        LOWER(RAWTOHEX(SYS_GUID())),
        l_owner_public_id
      );
    EXCEPTION
      WHEN stu_service_pkg.e_member_not_found THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'Ativacao inexistente deveria falhar.');
    l_raised := FALSE;
    BEGIN
      l_other_member := stu_service_pkg.deactivate_member(
        LOWER(RAWTOHEX(SYS_GUID())),
        l_owner_public_id
      );
    EXCEPTION
      WHEN stu_service_pkg.e_member_not_found THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'Inativacao inexistente deveria falhar.');
    pass;

    start_test('Reativacao duplicada gera erro de dominio');
    stu_repository_pkg.insert_store_user(
      RAWTOHEX(SYS_GUID()),
      l_store_id_one,
      l_account_id_one,
      'ATTENDANT',
      'INACTIVE',
      TIMESTAMP '2025-01-01 10:00:00',
      l_owner_id,
      l_history_id
    );
    l_internal := stu_repository_pkg.get_by_id(l_history_id);
    l_raised := FALSE;
    BEGIN
      l_other_member := stu_service_pkg.activate_member(
        l_internal.stu_public_id,
        l_owner_public_id
      );
    EXCEPTION
      WHEN stu_service_pkg.e_active_link_exists THEN
        l_raised := SQLCODE = -20884;
    END;
    assert_true(l_raised, 'Reativacao duplicada deveria falhar.');
    pass;

    start_test('LIST_MEMBERS_BY_STORE retorna membros da loja');
    l_other_member := stu_service_pkg.create_member(
      l_store_public_id_one,
      l_account_public_id_two,
      'ATTENDANT',
      l_owner_public_id
    );
    l_members := stu_service_pkg.list_members_by_store(
      l_store_public_id_one
    );
    assert_true(
      l_members.COUNT = 3,
      'Lista da loja deveria incluir ativo e historico.'
    );
    assert_true(
      TRIM(l_members(1).store_public_id) = TRIM(l_store_public_id_one)
      AND l_members(1).account_public_id IS NOT NULL,
      'Lista da loja deve retornar Public IDs.'
    );
    pass;

    start_test('LIST_MEMBERS_BY_STORE filtra status normalizado');
    l_members := stu_service_pkg.list_members_by_store(
      l_store_public_id_one,
      ' active '
    );
    assert_true(
      l_members.COUNT = 2
      AND l_members(1).status = 'ACTIVE'
      AND l_members(2).status = 'ACTIVE',
      'Filtro por status esta incorreto.'
    );
    pass;

    start_test('LIST_MEMBERS_BY_STORE filtra papel normalizado');
    l_members := stu_service_pkg.list_members_by_store(
      p_store_public_id => l_store_public_id_one,
      p_role_code       => ' attendant '
    );
    assert_true(
      l_members.COUNT = 2,
      'Filtro por papel deveria incluir ativo e historico.'
    );
    pass;

    start_test('LIST_MEMBERS_BY_STORE rejeita status invalido');
    l_raised := FALSE;
    BEGIN
      l_members := stu_service_pkg.list_members_by_store(
        l_store_public_id_one,
        'BLOCKED'
      );
    EXCEPTION
      WHEN stu_service_pkg.e_invalid_status THEN
        l_raised := SQLCODE = -20882;
    END;
    assert_true(l_raised, 'Status invalido deveria gerar erro de dominio.');
    pass;

    start_test('LIST_MEMBERS_BY_STORE rejeita papel invalido');
    l_raised := FALSE;
    BEGIN
      l_members := stu_service_pkg.list_members_by_store(
        p_store_public_id => l_store_public_id_one,
        p_role_code       => 'OWNER'
      );
    EXCEPTION
      WHEN stu_service_pkg.e_invalid_role THEN
        l_raised := SQLCODE = -20881;
    END;
    assert_true(l_raised, 'Papel invalido deveria gerar erro de dominio.');
    pass;

    start_test('LIST_MEMBERS_BY_STORE exige loja existente');
    l_raised := FALSE;
    BEGIN
      l_members := stu_service_pkg.list_members_by_store(
        LOWER(RAWTOHEX(SYS_GUID()))
      );
    EXCEPTION
      WHEN stu_service_pkg.e_store_not_found THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'Lista deveria exigir loja existente.');
    pass;

    start_test('LIST_STORES_BY_ACCOUNT retorna vinculos da conta');
    l_other_member := stu_service_pkg.create_member(
      l_store_public_id_two,
      l_account_public_id_two,
      'COLLABORATOR',
      l_owner_public_id
    );
    l_members := stu_service_pkg.list_stores_by_account(
      l_account_public_id_two
    );
    assert_true(
      l_members.COUNT = 2,
      'Conta deveria possuir vinculos em duas lojas.'
    );
    assert_true(
      l_members(1).store_public_id IS NOT NULL
      AND TRIM(l_members(1).account_public_id) =
          TRIM(l_account_public_id_two),
      'Lista da conta deve retornar Public IDs.'
    );
    pass;

    start_test('LIST_STORES_BY_ACCOUNT filtra status');
    l_other_member := stu_service_pkg.deactivate_member(
      l_other_member.store_user_public_id,
      l_owner_public_id
    );
    l_members := stu_service_pkg.list_stores_by_account(
      l_account_public_id_two,
      'INACTIVE'
    );
    assert_true(
      l_members.COUNT = 1
      AND l_members(1).status = 'INACTIVE',
      'Filtro de status por conta esta incorreto.'
    );
    pass;

    start_test('LIST_STORES_BY_ACCOUNT vazia retorna colecao vazia');
    l_members := stu_service_pkg.list_stores_by_account(
      l_empty_account_public_id
    );
    assert_true(l_members.COUNT = 0, 'Conta vazia deveria retornar zero.');
    pass;

    start_test('LIST_STORES_BY_ACCOUNT exige conta existente');
    l_raised := FALSE;
    BEGIN
      l_members := stu_service_pkg.list_stores_by_account(
        LOWER(RAWTOHEX(SYS_GUID()))
      );
    EXCEPTION
      WHEN stu_service_pkg.e_account_not_found THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'Lista deveria exigir conta existente.');
    pass;

    start_test('LIST_STORES_BY_ACCOUNT rejeita status invalido');
    l_raised := FALSE;
    BEGIN
      l_members := stu_service_pkg.list_stores_by_account(
        l_account_public_id_one,
        'PENDING'
      );
    EXCEPTION
      WHEN stu_service_pkg.e_invalid_status THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'Filtro invalido deveria falhar.');
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
    assert_true(l_source_count = 0, 'Service possui elemento proibido.');
    pass;

    start_test('Service usa dependencias de camada aprovadas');
    SELECT COUNT(*) INTO l_source_count FROM USER_SOURCE
     WHERE NAME = 'STU_SERVICE_PKG' AND TYPE = 'PACKAGE BODY'
       AND REGEXP_LIKE(
         UPPER(TEXT),
         'ACC_(RULE|REPOSITORY)_PKG|BEX_PROFILE|PFL_|CORE_RESPONSE_PKG'
       );
    assert_true(l_source_count = 0, 'Service possui dependencia proibida.');

    SELECT COUNT(*) INTO l_source_count FROM USER_SOURCE
     WHERE NAME = 'STU_SERVICE_PKG'
       AND TYPE = 'PACKAGE BODY'
       AND INSTR(UPPER(TEXT), 'STR_REPOSITORY_PKG') > 0;
    assert_true(
      l_source_count = 0,
      'STU_SERVICE_PKG nao pode depender de STR_REPOSITORY_PKG.'
    );

    SELECT COUNT(*) INTO l_source_count FROM USER_SOURCE
     WHERE NAME = 'STU_SERVICE_PKG' AND TYPE = 'PACKAGE'
       AND REGEXP_LIKE(
         UPPER(TEXT),
         'P_AUDIT_ACTOR_ID|P_ACTOR_PUBLIC_ID[[:space:]]+IN[[:space:]]+NUMBER|' ||
         '(^|[^A-Z_])(STORE_ID|ACCOUNT_ID|CREATED_BY|UPDATED_BY)' ||
         '([^A-Z_]|$)'
       );
    assert_true(
      l_source_count = 0,
      'Contrato publico nao deve expor IDs internos.'
    );

    SELECT COUNT(*) INTO l_source_count FROM USER_DEPENDENCIES
     WHERE NAME = 'STU_SERVICE_PKG'
       AND TYPE IN ('PACKAGE', 'PACKAGE BODY')
       AND REFERENCED_TYPE IN ('PACKAGE', 'PACKAGE BODY')
       AND REFERENCED_OWNER = USER
       AND REFERENCED_NAME NOT IN (
             'STU_SERVICE_PKG',
             'STU_RULE_PKG',
             'STU_REPOSITORY_PKG',
             'STR_SERVICE_PKG',
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
  create_account_fixture(l_account_id_one, l_account_public_id_one);
  create_account_fixture(l_account_id_two, l_account_public_id_two);
  create_account_fixture(l_empty_account_id, l_empty_account_public_id);
  create_store_fixture('one', l_store_id_one, l_store_public_id_one);
  create_store_fixture('two', l_store_id_two, l_store_public_id_two);

  run_tests;

  IF g_test_count <> c_expected_test_count THEN
    fail(
      'Quantidade de testes invalida. Esperado=' || c_expected_test_count ||
      ', executado=' || g_test_count
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
