SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  g_test_count   PLS_INTEGER := 0;
  g_current_test VARCHAR2(200);

  c_expected_test_count CONSTANT PLS_INTEGER := 11;
  c_credential_one      CONSTANT VARCHAR2(255) :=
    'v1$SHA512$AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA$'
    || 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB'
    || 'BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB';
  c_credential_two      CONSTANT VARCHAR2(255) :=
    'v1$SHA512$CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC$'
    || 'DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD'
    || 'DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD';

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

  PROCEDURE cleanup(
    p_email IN VARCHAR2
  ) IS
  BEGIN
    DELETE FROM BEX_ACCOUNT
     WHERE ACC_EMAIL = p_email;
  END cleanup;

  PROCEDURE cleanup_all IS
  BEGIN
    cleanup('repo.test.insert@example.invalid');
    cleanup('repo.test.id@example.invalid');
    cleanup('repo.test.email@example.invalid');
    cleanup('repo.test.exists@example.invalid');
    cleanup('repo.test.update.old@example.invalid');
    cleanup('repo.test.update.new@example.invalid');
    cleanup('repo.test.password@example.invalid');
  END cleanup_all;

  PROCEDURE insert_fixture(
    p_public_id  IN VARCHAR2,
    p_email      IN VARCHAR2,
    p_credential IN VARCHAR2
  ) IS
  BEGIN
    acc_repository_pkg.insert_account(
      p_public_id           => p_public_id,
      p_email               => p_email,
      p_email_verified_at   => NULL,
      p_credential          => p_credential,
      p_password_changed_at => SYSTIMESTAMP - INTERVAL '1' DAY,
      p_status              => 'ACTIVE',
      p_last_login_at       => NULL,
      p_created_by          => 1001,
      p_updated_by          => 1001
    );
  END insert_fixture;

  PROCEDURE run_tests IS
    l_account        BEX_ACCOUNT%ROWTYPE;
    l_original_time  TIMESTAMP(6);
    l_source_count   PLS_INTEGER;
  BEGIN
    start_test('INSERT_ACCOUNT persiste valores preparados');
    cleanup('repo.test.insert@example.invalid');
    insert_fixture(
      'F1000000000000000000000000000001',
      'repo.test.insert@example.invalid',
      c_credential_one
    );
    l_account := acc_repository_pkg.get_by_email(
      'repo.test.insert@example.invalid'
    );
    assert_true(
      l_account.ACC_ID IS NOT NULL
      AND TRIM(l_account.ACC_PUBLIC_ID) =
        'F1000000000000000000000000000001'
      AND l_account.ACC_EMAIL = 'repo.test.insert@example.invalid'
      AND l_account.ACC_PASSWORD_HASH = c_credential_one
      AND l_account.ACC_STATUS = 'ACTIVE'
      AND l_account.ACC_CREATED_AT IS NOT NULL
      AND l_account.ACC_UPDATED_AT IS NOT NULL,
      'INSERT_ACCOUNT nao preservou os valores preparados.'
    );
    cleanup('repo.test.insert@example.invalid');
    pass;

    start_test('GET_BY_ID retorna registro existente');
    cleanup('repo.test.id@example.invalid');
    insert_fixture(
      'F1000000000000000000000000000002',
      'repo.test.id@example.invalid',
      c_credential_one
    );
    l_account := acc_repository_pkg.get_by_email(
      'repo.test.id@example.invalid'
    );
    l_account := acc_repository_pkg.get_by_id(l_account.ACC_ID);
    assert_true(
      l_account.ACC_ID IS NOT NULL
      AND l_account.ACC_EMAIL = 'repo.test.id@example.invalid',
      'GET_BY_ID nao retornou o registro esperado.'
    );
    cleanup('repo.test.id@example.invalid');
    pass;

    start_test('GET_BY_EMAIL retorna registro existente');
    cleanup('repo.test.email@example.invalid');
    insert_fixture(
      'F1000000000000000000000000000003',
      'repo.test.email@example.invalid',
      c_credential_one
    );
    l_account := acc_repository_pkg.get_by_email(
      'repo.test.email@example.invalid'
    );
    assert_true(
      l_account.ACC_ID IS NOT NULL
      AND l_account.ACC_EMAIL = 'repo.test.email@example.invalid',
      'GET_BY_EMAIL nao retornou o registro esperado.'
    );
    cleanup('repo.test.email@example.invalid');
    pass;

    start_test('EMAIL_EXISTS retorna verdadeiro');
    cleanup('repo.test.exists@example.invalid');
    insert_fixture(
      'F1000000000000000000000000000004',
      'repo.test.exists@example.invalid',
      c_credential_one
    );
    assert_true(
      acc_repository_pkg.email_exists('repo.test.exists@example.invalid'),
      'EMAIL_EXISTS deveria retornar TRUE.'
    );
    cleanup('repo.test.exists@example.invalid');
    pass;

    start_test('EMAIL_EXISTS retorna falso');
    cleanup('repo.test.missing@example.invalid');
    assert_false(
      acc_repository_pkg.email_exists('repo.test.missing@example.invalid'),
      'EMAIL_EXISTS deveria retornar FALSE.'
    );
    pass;

    start_test('UPDATE_ACCOUNT altera apenas dados cadastrais');
    cleanup('repo.test.update.old@example.invalid');
    cleanup('repo.test.update.new@example.invalid');
    insert_fixture(
      'F1000000000000000000000000000005',
      'repo.test.update.old@example.invalid',
      c_credential_one
    );
    l_account := acc_repository_pkg.get_by_email(
      'repo.test.update.old@example.invalid'
    );
    acc_repository_pkg.update_account(
      p_account_id        => l_account.ACC_ID,
      p_email             => 'repo.test.update.new@example.invalid',
      p_email_verified_at => NULL,
      p_status            => 'BLOCKED',
      p_updated_by        => 2002
    );
    l_account := acc_repository_pkg.get_by_id(l_account.ACC_ID);
    assert_true(
      l_account.ACC_EMAIL = 'repo.test.update.new@example.invalid'
      AND l_account.ACC_EMAIL_VERIFIED_AT IS NULL
      AND l_account.ACC_STATUS = 'BLOCKED'
      AND l_account.ACC_UPDATED_BY = 2002
      AND l_account.ACC_PASSWORD_HASH = c_credential_one,
      'UPDATE_ACCOUNT alterou valores incorretos.'
    );
    cleanup('repo.test.update.new@example.invalid');
    pass;

    start_test('UPDATE_PASSWORD persiste credencial pronta');
    cleanup('repo.test.password@example.invalid');
    insert_fixture(
      'F1000000000000000000000000000006',
      'repo.test.password@example.invalid',
      c_credential_one
    );
    l_account := acc_repository_pkg.get_by_email(
      'repo.test.password@example.invalid'
    );
    l_original_time := l_account.ACC_PASSWORD_CHANGED_AT;
    acc_repository_pkg.update_password(l_account.ACC_ID, c_credential_two);
    l_account := acc_repository_pkg.get_by_id(l_account.ACC_ID);
    assert_true(
      l_account.ACC_PASSWORD_HASH = c_credential_two
      AND l_account.ACC_PASSWORD_CHANGED_AT IS NOT NULL
      AND l_account.ACC_PASSWORD_CHANGED_AT >= l_original_time,
      'UPDATE_PASSWORD nao persistiu a credencial preparada.'
    );
    cleanup('repo.test.password@example.invalid');
    pass;

    start_test('GET_BY_ID inexistente retorna registro nulo');
    l_account := acc_repository_pkg.get_by_id(-999999999);
    assert_true(
      l_account.ACC_ID IS NULL,
      'GET_BY_ID inexistente deveria retornar registro nulo.'
    );
    pass;

    start_test('GET_BY_EMAIL inexistente retorna registro nulo');
    cleanup('repo.test.not.found@example.invalid');
    l_account := acc_repository_pkg.get_by_email(
      'repo.test.not.found@example.invalid'
    );
    assert_true(
      l_account.ACC_ID IS NULL,
      'GET_BY_EMAIL inexistente deveria retornar registro nulo.'
    );
    pass;

    start_test('Repository nao contem COMMIT');
    SELECT COUNT(*)
      INTO l_source_count
      FROM USER_SOURCE
     WHERE NAME = 'ACC_REPOSITORY_PKG'
       AND TYPE = 'PACKAGE BODY'
       AND REGEXP_LIKE(UPPER(TEXT), '(^|[^A-Z_])COMMIT([^A-Z_]|$)');
    assert_true(l_source_count = 0, 'Repository nao pode conter COMMIT.');
    pass;

    start_test('Repository nao contem ROLLBACK');
    SELECT COUNT(*)
      INTO l_source_count
      FROM USER_SOURCE
     WHERE NAME = 'ACC_REPOSITORY_PKG'
       AND TYPE = 'PACKAGE BODY'
       AND REGEXP_LIKE(UPPER(TEXT), '(^|[^A-Z_])ROLLBACK([^A-Z_]|$)');
    assert_true(l_source_count = 0, 'Repository nao pode conter ROLLBACK.');
    pass;
  END run_tests;
BEGIN
  cleanup_all;
  run_tests;
  cleanup_all;

  IF g_test_count <> c_expected_test_count THEN
    fail(
      'Quantidade de testes invalida. Esperado=' || c_expected_test_count ||
      ', executado=' || g_test_count
    );
  END IF;

  DBMS_OUTPUT.PUT_LINE('ACC_REPOSITORY_PKG: PASSED');
EXCEPTION
  WHEN OTHERS THEN
    cleanup_all;
    DBMS_OUTPUT.PUT_LINE(
      'FAIL - ' || NVL(g_current_test, 'initialization')
    );
    RAISE;
END;
/
