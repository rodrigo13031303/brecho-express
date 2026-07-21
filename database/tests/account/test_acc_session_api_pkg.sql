SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  g_test_count   PLS_INTEGER := 0;
  g_current_test VARCHAR2(200);

  c_expected_test_count CONSTANT PLS_INTEGER := 6;

  l_account_id       BEX_ACCOUNT.ACC_ID%TYPE;
  l_account_public_id BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE;
  l_account_email    BEX_ACCOUNT.ACC_EMAIL%TYPE;
  l_session_public_id VARCHAR2(32);
  l_session_token    VARCHAR2(64);
  l_expires_at       TIMESTAMP;
  l_session          BEX_SESSION%ROWTYPE;
  l_second_public_id VARCHAR2(32);
  l_second_token     VARCHAR2(64);
  l_second_expires   TIMESTAMP;

  PROCEDURE fail(
    p_message IN VARCHAR2
  ) IS
  BEGIN
    RAISE_APPLICATION_ERROR(-20900, p_message);
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

  PROCEDURE cleanup IS
  BEGIN
    IF l_account_id IS NOT NULL THEN
      DELETE FROM BEX_SESSION
       WHERE ACC_ID = l_account_id;

      DELETE FROM BEX_ACCOUNT
       WHERE ACC_ID = l_account_id;
    ELSIF l_account_email IS NOT NULL THEN
      DELETE FROM BEX_ACCOUNT
       WHERE ACC_EMAIL = l_account_email;
    END IF;

    COMMIT;
  END cleanup;

  PROCEDURE create_account_fixture IS
    l_value VARCHAR2(32);
  BEGIN
    l_value := LOWER(RAWTOHEX(SYS_GUID()));
    l_account_public_id := l_value;
    l_account_email := 'session.api.' || SUBSTR(l_value, 1, 20)
                       || '@example.invalid';

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
      l_account_public_id,
      l_account_email,
      'session-api-test-credential',
      SYSTIMESTAMP,
      'ACTIVE'
    )
    RETURNING ACC_ID INTO l_account_id;
  END create_account_fixture;

  PROCEDURE create_session_fixture(
    p_public_id OUT VARCHAR2,
    p_token     OUT VARCHAR2,
    p_expires   OUT TIMESTAMP
  ) IS
  BEGIN
    acc_session_api_pkg.create_session(
      p_acc_id            => l_account_id,
      p_duration_minutes  => 60,
      p_created_by        => l_account_id,
      p_ip                => '127.0.0.1',
      p_user_agent        => 'ACC_SESSION_API_PKG test',
      p_session_public_id => p_public_id,
      p_session_token     => p_token,
      p_expires_at        => p_expires
    );
  END create_session_fixture;

  PROCEDURE run_tests IS
  BEGIN
    start_test('CREATE_SESSION cria e confirma a sessao');
    create_session_fixture(
      l_session_public_id,
      l_session_token,
      l_expires_at
    );
    l_session := acc_session_repository_pkg.get_by_public_id(
      l_session_public_id
    );
    assert_true(
      l_session.SESSION_ID IS NOT NULL
      AND l_session.SESSION_STATUS = 'ACTIVE'
      AND l_session_token IS NOT NULL,
      'CREATE_SESSION nao criou a sessao esperada.'
    );
    pass;

    start_test('VALIDATE_SESSION valida e confirma LAST_USED_AT');
    l_session := acc_session_api_pkg.validate_session(
      l_session_token,
      l_account_id
    );
    l_session := acc_session_repository_pkg.get_by_id(l_session.SESSION_ID);
    assert_true(
      l_session.SESSION_LAST_USED_AT IS NOT NULL
      AND l_session.SESSION_UPDATED_BY = l_account_id,
      'VALIDATE_SESSION nao confirmou a atualizacao.'
    );
    pass;

    start_test('GET_SESSION_BY_PUBLIC_ID retorna a sessao');
    l_session := acc_session_api_pkg.get_session_by_public_id(
      l_session_public_id
    );
    assert_true(
      l_session.SESSION_PUBLIC_ID = l_session_public_id,
      'GET_SESSION_BY_PUBLIC_ID retornou sessao incorreta.'
    );
    pass;

    start_test('REVOKE_SESSION revoga e confirma a sessao');
    acc_session_api_pkg.revoke_session(l_session_public_id, l_account_id);
    l_session := acc_session_repository_pkg.get_by_public_id(
      l_session_public_id
    );
    assert_true(
      l_session.SESSION_STATUS = 'REVOKED'
      AND l_session.SESSION_REVOKED_AT IS NOT NULL,
      'REVOKE_SESSION nao confirmou a revogacao.'
    );
    pass;

    start_test('REVOKE_ALL_BY_ACCOUNT revoga sessoes ACTIVE');
    create_session_fixture(l_second_public_id, l_second_token, l_second_expires);
    acc_session_api_pkg.revoke_all_by_account(l_account_id, l_account_id);
    l_session := acc_session_repository_pkg.get_by_public_id(
      l_second_public_id
    );
    assert_true(
      l_session.SESSION_STATUS = 'REVOKED',
      'REVOKE_ALL_BY_ACCOUNT nao revogou a sessao.'
    );
    pass;

    start_test('EXPIRE_SESSIONS expira sessoes vencidas');
    create_session_fixture(l_second_public_id, l_second_token, l_second_expires);
    UPDATE BEX_SESSION
       SET SESSION_EXPIRES_AT = SYSTIMESTAMP - INTERVAL '1' MINUTE
     WHERE SESSION_PUBLIC_ID = l_second_public_id;
    acc_session_api_pkg.expire_sessions(SYSTIMESTAMP, l_account_id);
    l_session := acc_session_repository_pkg.get_by_public_id(
      l_second_public_id
    );
    assert_true(
      l_session.SESSION_STATUS = 'EXPIRED',
      'EXPIRE_SESSIONS nao expirou a sessao.'
    );
    pass;
  END run_tests;
BEGIN
  create_account_fixture;
  run_tests;

  IF g_test_count <> c_expected_test_count THEN
    fail(
      'Quantidade de testes invalida. Esperado=' || c_expected_test_count
      || ', executado=' || g_test_count
    );
  END IF;

  cleanup;
  ROLLBACK;
  DBMS_OUTPUT.PUT_LINE('ACC_SESSION_API_PKG: PASSED');
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    cleanup;
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ACC_SESSION_API_PKG: FAILED');
    RAISE_APPLICATION_ERROR(
      -20900,
      NVL(g_current_test, 'initialization') || ': ' || SQLERRM
    );
END;
/
