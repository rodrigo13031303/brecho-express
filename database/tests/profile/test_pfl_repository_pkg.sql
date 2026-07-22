SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  g_test_count   PLS_INTEGER := 0;
  g_current_test VARCHAR2(200);

  c_expected_test_count CONSTANT PLS_INTEGER := 30;

  l_account_id_one   BEX_ACCOUNT.ACC_ID%TYPE;
  l_account_id_two   BEX_ACCOUNT.ACC_ID%TYPE;
  l_account_id_three BEX_ACCOUNT.ACC_ID%TYPE;
  l_profile_id       BEX_PROFILE.PFL_ID%TYPE;
  l_public_id        BEX_PROFILE.PFL_PUBLIC_ID%TYPE;
  l_profile          BEX_PROFILE%ROWTYPE;
  l_original_profile BEX_PROFILE%ROWTYPE;
  l_updated          BOOLEAN;
  l_raised           BOOLEAN;

  PROCEDURE fail(
    p_message IN VARCHAR2
  ) IS
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

  PROCEDURE start_test(
    p_test_name IN VARCHAR2
  ) IS
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
    l_value   VARCHAR2(32);
    l_email   VARCHAR2(255);
    l_account BEX_ACCOUNT%ROWTYPE;
  BEGIN
    l_value := LOWER(RAWTOHEX(SYS_GUID()));
    l_email := 'profile.repo.' || SUBSTR(l_value, 1, 20)
               || '@example.invalid';

    acc_repository_pkg.insert_account(
      p_public_id           => l_value,
      p_email               => l_email,
      p_email_verified_at   => NULL,
      p_credential          => 'profile-repository-test-credential',
      p_password_changed_at => SYSTIMESTAMP,
      p_status              => 'ACTIVE',
      p_last_login_at       => NULL,
      p_created_by          => NULL,
      p_updated_by          => NULL
    );

    l_account := acc_repository_pkg.get_by_email(l_email);
    o_account_id := l_account.ACC_ID;
  END create_account_fixture;

  PROCEDURE insert_profile_fixture(
    p_account_id IN BEX_PROFILE.ACC_ID%TYPE,
    p_public_id  IN BEX_PROFILE.PFL_PUBLIC_ID%TYPE,
    o_profile_id OUT BEX_PROFILE.PFL_ID%TYPE
  ) IS
  BEGIN
    pfl_repository_pkg.insert_profile(
      p_account_id    => p_account_id,
      p_public_id     => p_public_id,
      p_display_name  => 'Repository Profile',
      p_full_name     => 'Repository Profile Full Name',
      p_birth_date    => DATE '1990-05-10',
      p_bio           => 'Profile repository test biography',
      p_avatar_url    => 'https://example.invalid/avatar.png',
      p_locale_code   => 'pt-BR',
      p_timezone_name => 'America/Sao_Paulo',
      p_created_by    => 1001,
      p_updated_by    => 1001,
      o_profile_id    => o_profile_id
    );
  END insert_profile_fixture;

  PROCEDURE run_tests IS
    l_savepoint_profile_id BEX_PROFILE.PFL_ID%TYPE;
    l_duplicate_profile_id BEX_PROFILE.PFL_ID%TYPE;
  BEGIN
    l_public_id := LOWER(RAWTOHEX(SYS_GUID()));

    start_test('INSERT_PROFILE persiste perfil valido');
    insert_profile_fixture(l_account_id_one, l_public_id, l_profile_id);
    l_profile := pfl_repository_pkg.get_by_id(l_profile_id);
    assert_true(l_profile.PFL_ID IS NOT NULL, 'Perfil nao foi persistido.');
    pass;

    start_test('INSERT_PROFILE retorna PFL_ID');
    assert_true(l_profile_id IS NOT NULL, 'PFL_ID nao foi retornado.');
    pass;

    start_test('INSERT_PROFILE preserva PFL_PUBLIC_ID recebido');
    assert_true(
      TRIM(l_profile.PFL_PUBLIC_ID) = TRIM(l_public_id),
      'PFL_PUBLIC_ID nao foi preservado.'
    );
    pass;

    start_test('INSERT_PROFILE persiste ACC_ID');
    assert_true(
      l_profile.ACC_ID = l_account_id_one,
      'ACC_ID nao foi persistido.'
    );
    pass;

    start_test('INSERT_PROFILE persiste campos opcionais');
    assert_true(
      l_profile.PFL_FULL_NAME = 'Repository Profile Full Name'
      AND l_profile.PFL_BIRTH_DATE = DATE '1990-05-10'
      AND l_profile.PFL_BIO = 'Profile repository test biography'
      AND l_profile.PFL_AVATAR_URL = 'https://example.invalid/avatar.png',
      'Campos opcionais nao foram persistidos.'
    );
    pass;

    start_test('INSERT_PROFILE persiste auditoria');
    assert_true(
      l_profile.PFL_CREATED_AT IS NOT NULL
      AND l_profile.PFL_UPDATED_AT IS NOT NULL
      AND l_profile.PFL_CREATED_BY = 1001
      AND l_profile.PFL_UPDATED_BY = 1001,
      'Auditoria nao foi persistida.'
    );
    pass;

    start_test('GET_BY_ID retorna registro existente');
    l_profile := pfl_repository_pkg.get_by_id(l_profile_id);
    assert_true(l_profile.PFL_ID = l_profile_id, 'GET_BY_ID nao encontrou o perfil.');
    pass;

    start_test('GET_BY_ID retorna dados corretos');
    assert_true(
      l_profile.PFL_DISPLAY_NAME = 'Repository Profile'
      AND l_profile.ACC_ID = l_account_id_one,
      'GET_BY_ID retornou dados incorretos.'
    );
    pass;

    start_test('GET_BY_ID inexistente retorna registro vazio');
    l_profile := pfl_repository_pkg.get_by_id(-1);
    assert_true(l_profile.PFL_ID IS NULL, 'GET_BY_ID deveria retornar vazio.');
    pass;

    start_test('GET_BY_PUBLIC_ID retorna registro existente');
    l_profile := pfl_repository_pkg.get_by_public_id(l_public_id);
    assert_true(l_profile.PFL_ID = l_profile_id, 'GET_BY_PUBLIC_ID nao encontrou o perfil.');
    pass;

    start_test('GET_BY_PUBLIC_ID retorna dados corretos');
    assert_true(
      TRIM(l_profile.PFL_PUBLIC_ID) = TRIM(l_public_id)
      AND l_profile.ACC_ID = l_account_id_one,
      'GET_BY_PUBLIC_ID retornou dados incorretos.'
    );
    pass;

    start_test('GET_BY_PUBLIC_ID inexistente retorna registro vazio');
    l_profile := pfl_repository_pkg.get_by_public_id(
      LOWER(RAWTOHEX(SYS_GUID()))
    );
    assert_true(l_profile.PFL_ID IS NULL, 'GET_BY_PUBLIC_ID deveria retornar vazio.');
    pass;

    start_test('GET_BY_ACCOUNT_ID retorna registro existente');
    l_profile := pfl_repository_pkg.get_by_account_id(l_account_id_one);
    assert_true(l_profile.PFL_ID = l_profile_id, 'GET_BY_ACCOUNT_ID nao encontrou o perfil.');
    pass;

    start_test('GET_BY_ACCOUNT_ID retorna dados corretos');
    assert_true(
      l_profile.ACC_ID = l_account_id_one
      AND TRIM(l_profile.PFL_PUBLIC_ID) = TRIM(l_public_id),
      'GET_BY_ACCOUNT_ID retornou dados incorretos.'
    );
    pass;

    start_test('GET_BY_ACCOUNT_ID sem perfil retorna registro vazio');
    l_profile := pfl_repository_pkg.get_by_account_id(l_account_id_two);
    assert_true(l_profile.PFL_ID IS NULL, 'Conta sem perfil deveria retornar vazio.');
    pass;

    start_test('PROFILE_EXISTS retorna verdadeiro');
    assert_true(
      pfl_repository_pkg.profile_exists(l_profile_id),
      'PROFILE_EXISTS deveria retornar TRUE.'
    );
    pass;

    start_test('PROFILE_EXISTS retorna falso');
    assert_false(
      pfl_repository_pkg.profile_exists(-1),
      'PROFILE_EXISTS deveria retornar FALSE.'
    );
    pass;

    start_test('PUBLIC_ID_EXISTS retorna verdadeiro');
    assert_true(
      pfl_repository_pkg.public_id_exists(l_public_id),
      'PUBLIC_ID_EXISTS deveria retornar TRUE.'
    );
    pass;

    start_test('PUBLIC_ID_EXISTS retorna falso');
    assert_false(
      pfl_repository_pkg.public_id_exists(LOWER(RAWTOHEX(SYS_GUID()))),
      'PUBLIC_ID_EXISTS deveria retornar FALSE.'
    );
    pass;

    start_test('ACCOUNT_HAS_PROFILE retorna verdadeiro');
    assert_true(
      pfl_repository_pkg.account_has_profile(l_account_id_one),
      'ACCOUNT_HAS_PROFILE deveria retornar TRUE.'
    );
    pass;

    start_test('ACCOUNT_HAS_PROFILE retorna falso');
    assert_false(
      pfl_repository_pkg.account_has_profile(l_account_id_two),
      'ACCOUNT_HAS_PROFILE deveria retornar FALSE.'
    );
    pass;

    l_original_profile := pfl_repository_pkg.get_by_id(l_profile_id);
    start_test('UPDATE_PROFILE atualiza campos editaveis');
    pfl_repository_pkg.update_profile(
      p_profile_id    => l_profile_id,
      p_display_name  => 'Updated Profile',
      p_full_name     => 'Updated Full Name',
      p_birth_date    => DATE '1991-06-11',
      p_bio           => 'Updated biography',
      p_avatar_url    => 'https://example.invalid/updated.png',
      p_locale_code   => 'pt-BR',
      p_timezone_name => 'America/Sao_Paulo',
      p_updated_by    => 2002,
      o_updated       => l_updated
    );
    l_profile := pfl_repository_pkg.get_by_id(l_profile_id);
    assert_true(
      l_profile.PFL_DISPLAY_NAME = 'Updated Profile'
      AND l_profile.PFL_FULL_NAME = 'Updated Full Name'
      AND l_profile.PFL_BIRTH_DATE = DATE '1991-06-11'
      AND l_profile.PFL_BIO = 'Updated biography'
      AND l_profile.PFL_AVATAR_URL = 'https://example.invalid/updated.png',
      'Campos editaveis nao foram atualizados.'
    );
    pass;

    start_test('UPDATE_PROFILE preserva identificadores imutaveis');
    assert_true(
      l_profile.PFL_ID = l_original_profile.PFL_ID
      AND l_profile.ACC_ID = l_original_profile.ACC_ID
      AND l_profile.PFL_PUBLIC_ID = l_original_profile.PFL_PUBLIC_ID,
      'Identificadores imutaveis foram alterados.'
    );
    pass;

    start_test('UPDATE_PROFILE informa registro atualizado');
    assert_true(l_updated, 'UPDATE_PROFILE deveria informar TRUE.');
    pass;

    start_test('UPDATE_PROFILE inexistente informa falso');
    pfl_repository_pkg.update_profile(
      -1, 'Missing', NULL, NULL, NULL, NULL,
      'pt-BR', 'America/Sao_Paulo', NULL, l_updated
    );
    assert_false(l_updated, 'UPDATE_PROFILE inexistente deveria informar FALSE.');
    pass;

    start_test('UPDATE_PROFILE persiste novos valores');
    l_profile := pfl_repository_pkg.get_by_id(l_profile_id);
    assert_true(
      l_profile.PFL_DISPLAY_NAME = 'Updated Profile'
      AND l_profile.PFL_UPDATED_BY = 2002
      AND l_profile.PFL_UPDATED_AT >= l_original_profile.PFL_UPDATED_AT,
      'Novos valores nao foram persistidos.'
    );
    pass;

    start_test('UPDATE_PROFILE preserva campos de criacao');
    assert_true(
      l_profile.PFL_CREATED_AT = l_original_profile.PFL_CREATED_AT
      AND l_profile.PFL_CREATED_BY = l_original_profile.PFL_CREATED_BY,
      'Campos de criacao foram alterados.'
    );
    pass;

    start_test('UK_PFL_ACCOUNT impede dois perfis por conta');
    l_raised := FALSE;
    BEGIN
      insert_profile_fixture(
        l_account_id_one,
        LOWER(RAWTOHEX(SYS_GUID())),
        l_duplicate_profile_id
      );
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        l_raised := TRUE;
      WHEN OTHERS THEN
        fail('Duplicidade de ACC_ID levantou excecao diferente.');
    END;
    assert_true(l_raised, 'UK_PFL_ACCOUNT deveria impedir duplicidade.');
    pass;

    start_test('UK_PFL_PUBLIC_ID impede public ID duplicado');
    l_raised := FALSE;
    BEGIN
      insert_profile_fixture(
        l_account_id_two,
        l_public_id,
        l_duplicate_profile_id
      );
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        l_raised := TRUE;
      WHEN OTHERS THEN
        fail('Duplicidade de public ID levantou excecao diferente.');
    END;
    assert_true(l_raised, 'UK_PFL_PUBLIC_ID deveria impedir duplicidade.');
    pass;

    start_test('Repository nao executa COMMIT');
    SAVEPOINT before_repository_insert;
    insert_profile_fixture(
      l_account_id_three,
      LOWER(RAWTOHEX(SYS_GUID())),
      l_savepoint_profile_id
    );
    ROLLBACK TO before_repository_insert;
    assert_false(
      pfl_repository_pkg.profile_exists(l_savepoint_profile_id),
      'ROLLBACK TO SAVEPOINT nao reverteu a insercao.'
    );
    pass;
  END run_tests;
BEGIN
  create_account_fixture(l_account_id_one);
  create_account_fixture(l_account_id_two);
  create_account_fixture(l_account_id_three);
  run_tests;

  IF g_test_count <> c_expected_test_count THEN
    fail(
      'Quantidade de testes invalida. Esperado=' || c_expected_test_count
      || ', executado=' || g_test_count
    );
  END IF;

  ROLLBACK;
  DBMS_OUTPUT.PUT_LINE('PFL_REPOSITORY_PKG: PASSED');
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE(
      'FAIL - ' || NVL(g_current_test, 'initialization')
    );
    RAISE;
END;
/
