SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  g_test_count   PLS_INTEGER := 0;
  g_current_test VARCHAR2(200);

  c_expected_test_count CONSTANT PLS_INTEGER := 26;

  l_suffix             VARCHAR2(32);
  l_account_id         BEX_ACCOUNT.ACC_ID%TYPE;
  l_session_id         BEX_SESSION.SESSION_ID%TYPE;
  l_session_public_id  BEX_SESSION.SESSION_PUBLIC_ID%TYPE;
  l_token_hash         BEX_SESSION.SESSION_TOKEN_HASH%TYPE;
  l_created_at         BEX_SESSION.SESSION_CREATED_AT%TYPE;
  l_expires_at         BEX_SESSION.SESSION_EXPIRES_AT%TYPE;
  l_last_used_at       BEX_SESSION.SESSION_LAST_USED_AT%TYPE;
  l_session            BEX_SESSION%ROWTYPE;
  l_second_session     BEX_SESSION%ROWTYPE;
  l_third_session      BEX_SESSION%ROWTYPE;
  l_fourth_session     BEX_SESSION%ROWTYPE;
  l_fifth_session      BEX_SESSION%ROWTYPE;
  l_sixth_session      BEX_SESSION%ROWTYPE;
  l_seventh_session    BEX_SESSION%ROWTYPE;
  l_constraint_raised  BOOLEAN;

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

  FUNCTION unique_public_id
    RETURN VARCHAR2 IS
  BEGIN
    RETURN LOWER(RAWTOHEX(SYS_GUID()));
  END unique_public_id;

  FUNCTION unique_token_hash
    RETURN VARCHAR2 IS
    l_value VARCHAR2(32);
  BEGIN
    l_value := UPPER(RAWTOHEX(SYS_GUID()));
    RETURN l_value || l_value || l_value || l_value;
  END unique_token_hash;

  PROCEDURE insert_session_fixture(
    p_status       IN VARCHAR2,
    p_expires_at   IN TIMESTAMP,
    p_session      OUT BEX_SESSION%ROWTYPE
  ) IS
    l_fixture_id BEX_SESSION.SESSION_ID%TYPE;
  BEGIN
    acc_session_repository_pkg.insert_session(
      p_session_public_id => unique_public_id,
      p_acc_id            => l_account_id,
      p_token_hash        => unique_token_hash,
      p_status            => p_status,
      p_created_at        => SYSTIMESTAMP,
      p_expires_at        => p_expires_at,
      p_created_by        => l_account_id,
      p_ip                => '127.0.0.1',
      p_user_agent        => 'ACC_SESSION_REPOSITORY_PKG test',
      p_session_id        => l_fixture_id
    );

    p_session := acc_session_repository_pkg.get_by_id(l_fixture_id);
  END insert_session_fixture;

  PROCEDURE create_account_fixture IS
    l_email VARCHAR2(255);
  BEGIN
    l_suffix := LOWER(RAWTOHEX(SYS_GUID()));
    l_email := 'session.repo.' || SUBSTR(l_suffix, 1, 20)
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
      l_suffix,
      l_email,
      'repository-test-credential',
      SYSTIMESTAMP,
      'ACTIVE'
    )
    RETURNING ACC_ID INTO l_account_id;
  END create_account_fixture;

  PROCEDURE run_tests IS
    l_count PLS_INTEGER;
  BEGIN
    l_session_public_id := unique_public_id;
    l_token_hash := unique_token_hash;
    l_created_at := SYSTIMESTAMP;
    l_expires_at := SYSTIMESTAMP + INTERVAL '1' DAY;

    start_test('INSERT_SESSION cria uma sessao');
    acc_session_repository_pkg.insert_session(
      p_session_public_id => l_session_public_id,
      p_acc_id            => l_account_id,
      p_token_hash        => l_token_hash,
      p_status            => 'ACTIVE',
      p_created_at        => l_created_at,
      p_expires_at        => l_expires_at,
      p_created_by        => l_account_id,
      p_ip                => '192.0.2.1',
      p_user_agent        => 'Repository test agent',
      p_session_id        => l_session_id
    );
    SELECT COUNT(*)
      INTO l_count
      FROM BEX_SESSION
     WHERE SESSION_ID = l_session_id;
    assert_true(l_count = 1, 'INSERT_SESSION nao criou a sessao.');
    pass;

    start_test('INSERT_SESSION retorna SESSION_ID');
    assert_true(l_session_id IS NOT NULL, 'SESSION_ID nao foi retornado.');
    pass;

    start_test('GET_BY_ID retorna a sessao correta');
    l_session := acc_session_repository_pkg.get_by_id(l_session_id);
    assert_true(
      l_session.SESSION_ID = l_session_id
      AND l_session.ACC_ID = l_account_id,
      'GET_BY_ID retornou sessao incorreta.'
    );
    pass;

    start_test('GET_BY_PUBLIC_ID retorna a sessao correta');
    l_session := acc_session_repository_pkg.get_by_public_id(
      l_session_public_id
    );
    assert_true(
      l_session.SESSION_ID = l_session_id,
      'GET_BY_PUBLIC_ID retornou sessao incorreta.'
    );
    pass;

    start_test('GET_BY_TOKEN_HASH retorna a sessao correta');
    l_session := acc_session_repository_pkg.get_by_token_hash(l_token_hash);
    assert_true(
      l_session.SESSION_ID = l_session_id,
      'GET_BY_TOKEN_HASH retornou sessao incorreta.'
    );
    pass;

    start_test('GET_BY_ID inexistente retorna registro vazio');
    l_session := acc_session_repository_pkg.get_by_id(-1);
    assert_true(l_session.SESSION_ID IS NULL, 'GET_BY_ID deveria retornar vazio.');
    pass;

    start_test('GET_BY_PUBLIC_ID inexistente retorna registro vazio');
    l_session := acc_session_repository_pkg.get_by_public_id(unique_public_id);
    assert_true(
      l_session.SESSION_ID IS NULL,
      'GET_BY_PUBLIC_ID deveria retornar vazio.'
    );
    pass;

    start_test('GET_BY_TOKEN_HASH inexistente retorna registro vazio');
    l_session := acc_session_repository_pkg.get_by_token_hash(
      unique_token_hash
    );
    assert_true(
      l_session.SESSION_ID IS NULL,
      'GET_BY_TOKEN_HASH deveria retornar vazio.'
    );
    pass;

    start_test('SESSION_EXISTS retorna TRUE para sessao existente');
    assert_true(
      acc_session_repository_pkg.session_exists(l_session_id),
      'SESSION_EXISTS deveria retornar TRUE.'
    );
    pass;

    start_test('SESSION_EXISTS retorna FALSE para sessao inexistente');
    assert_false(
      acc_session_repository_pkg.session_exists(-1),
      'SESSION_EXISTS deveria retornar FALSE.'
    );
    pass;

    start_test('TOKEN_HASH_EXISTS retorna TRUE para hash existente');
    assert_true(
      acc_session_repository_pkg.token_hash_exists(l_token_hash),
      'TOKEN_HASH_EXISTS deveria retornar TRUE.'
    );
    pass;

    start_test('TOKEN_HASH_EXISTS retorna FALSE para hash inexistente');
    assert_false(
      acc_session_repository_pkg.token_hash_exists(unique_token_hash),
      'TOKEN_HASH_EXISTS deveria retornar FALSE.'
    );
    pass;

    l_last_used_at := SYSTIMESTAMP;
    acc_session_repository_pkg.update_last_used(
      p_session_id   => l_session_id,
      p_last_used_at => l_last_used_at,
      p_updated_by   => l_account_id
    );
    l_session := acc_session_repository_pkg.get_by_id(l_session_id);

    start_test('UPDATE_LAST_USED atualiza SESSION_LAST_USED_AT');
    assert_true(
      l_session.SESSION_LAST_USED_AT = l_last_used_at,
      'SESSION_LAST_USED_AT nao foi atualizado.'
    );
    pass;

    start_test('UPDATE_LAST_USED atualiza SESSION_UPDATED_BY');
    assert_true(
      l_session.SESSION_UPDATED_BY = l_account_id,
      'SESSION_UPDATED_BY nao foi atualizado.'
    );
    pass;

    start_test('UPDATE_LAST_USED nao altera SESSION_STATUS');
    assert_true(
      l_session.SESSION_STATUS = 'ACTIVE',
      'UPDATE_LAST_USED alterou SESSION_STATUS.'
    );
    pass;

    acc_session_repository_pkg.update_status(
      p_session_id => l_session_id,
      p_status     => 'REVOKED',
      p_revoked_at => l_last_used_at,
      p_updated_by => l_account_id + 1
    );
    l_session := acc_session_repository_pkg.get_by_id(l_session_id);

    start_test('UPDATE_STATUS altera status para REVOKED');
    assert_true(l_session.SESSION_STATUS = 'REVOKED', 'Status nao foi alterado.');
    pass;

    start_test('UPDATE_STATUS preenche SESSION_REVOKED_AT');
    assert_true(
      l_session.SESSION_REVOKED_AT = l_last_used_at,
      'SESSION_REVOKED_AT nao foi preenchido.'
    );
    pass;

    start_test('UPDATE_STATUS atualiza SESSION_UPDATED_BY');
    assert_true(
      l_session.SESSION_UPDATED_BY = l_account_id + 1,
      'UPDATE_STATUS nao atualizou SESSION_UPDATED_BY.'
    );
    pass;

    insert_session_fixture('ACTIVE', SYSTIMESTAMP + INTERVAL '1' DAY, l_second_session);
    insert_session_fixture('ACTIVE', SYSTIMESTAMP + INTERVAL '2' DAY, l_third_session);
    insert_session_fixture('EXPIRED', SYSTIMESTAMP - INTERVAL '1' DAY, l_fourth_session);
    acc_session_repository_pkg.revoke_all_by_account(
      p_acc_id     => l_account_id,
      p_revoked_at => l_last_used_at,
      p_updated_by => l_account_id
    );

    start_test('REVOKE_ALL_BY_ACCOUNT revoga sessoes ACTIVE');
    l_second_session := acc_session_repository_pkg.get_by_id(l_second_session.SESSION_ID);
    l_third_session := acc_session_repository_pkg.get_by_id(l_third_session.SESSION_ID);
    assert_true(
      l_second_session.SESSION_STATUS = 'REVOKED'
      AND l_third_session.SESSION_STATUS = 'REVOKED',
      'Nem todas as sessoes ACTIVE foram revogadas.'
    );
    pass;

    start_test('REVOKE_ALL_BY_ACCOUNT preserva sessoes EXPIRED');
    l_fourth_session := acc_session_repository_pkg.get_by_id(l_fourth_session.SESSION_ID);
    assert_true(
      l_fourth_session.SESSION_STATUS = 'EXPIRED',
      'Sessao EXPIRED foi alterada.'
    );
    pass;

    insert_session_fixture('ACTIVE', SYSTIMESTAMP - INTERVAL '1' HOUR, l_fifth_session);
    insert_session_fixture('ACTIVE', SYSTIMESTAMP + INTERVAL '1' HOUR, l_sixth_session);
    insert_session_fixture('REVOKED', SYSTIMESTAMP - INTERVAL '1' HOUR, l_seventh_session);
    acc_session_repository_pkg.expire_sessions(
      p_reference_date => SYSTIMESTAMP,
      p_updated_by     => l_account_id
    );

    start_test('EXPIRE_SESSIONS expira sessoes vencidas');
    l_fifth_session := acc_session_repository_pkg.get_by_id(l_fifth_session.SESSION_ID);
    assert_true(l_fifth_session.SESSION_STATUS = 'EXPIRED', 'Sessao vencida nao expirou.');
    pass;

    start_test('EXPIRE_SESSIONS preserva validade futura');
    l_sixth_session := acc_session_repository_pkg.get_by_id(l_sixth_session.SESSION_ID);
    assert_true(l_sixth_session.SESSION_STATUS = 'ACTIVE', 'Sessao futura foi expirada.');
    pass;

    start_test('EXPIRE_SESSIONS preserva sessoes REVOKED');
    l_seventh_session := acc_session_repository_pkg.get_by_id(l_seventh_session.SESSION_ID);
    assert_true(l_seventh_session.SESSION_STATUS = 'REVOKED', 'Sessao REVOKED foi alterada.');
    pass;

    start_test('SESSION_PUBLIC_ID duplicado gera erro de constraint');
    l_constraint_raised := FALSE;
    BEGIN
      acc_session_repository_pkg.insert_session(
        l_session_public_id, l_account_id, unique_token_hash, 'ACTIVE',
        SYSTIMESTAMP, SYSTIMESTAMP + INTERVAL '1' DAY, NULL, NULL, NULL,
        l_session_id
      );
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        l_constraint_raised := TRUE;
    END;
    assert_true(l_constraint_raised, 'Public ID duplicado deveria falhar.');
    pass;

    start_test('SESSION_TOKEN_HASH duplicado gera erro de constraint');
    l_constraint_raised := FALSE;
    BEGIN
      acc_session_repository_pkg.insert_session(
        unique_public_id, l_account_id, l_token_hash, 'ACTIVE',
        SYSTIMESTAMP, SYSTIMESTAMP + INTERVAL '1' DAY, NULL, NULL, NULL,
        l_session_id
      );
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        l_constraint_raised := TRUE;
    END;
    assert_true(l_constraint_raised, 'Token hash duplicado deveria falhar.');
    pass;

    start_test('ACC_ID inexistente gera erro de FK');
    l_constraint_raised := FALSE;
    BEGIN
      acc_session_repository_pkg.insert_session(
        unique_public_id, -1, unique_token_hash, 'ACTIVE', SYSTIMESTAMP,
        SYSTIMESTAMP + INTERVAL '1' DAY, NULL, NULL, NULL, l_session_id
      );
    EXCEPTION
      WHEN OTHERS THEN
        IF SQLCODE = -2291 THEN
          l_constraint_raised := TRUE;
        ELSE
          RAISE;
        END IF;
    END;
    assert_true(l_constraint_raised, 'ACC_ID inexistente deveria violar a FK.');
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

  ROLLBACK;
  DBMS_OUTPUT.PUT_LINE('ACC_SESSION_REPOSITORY_PKG: PASSED');
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ACC_SESSION_REPOSITORY_PKG: FAILED');
    RAISE_APPLICATION_ERROR(
      -20900,
      NVL(g_current_test, 'initialization') || ': ' || SQLERRM
    );
END;
/
