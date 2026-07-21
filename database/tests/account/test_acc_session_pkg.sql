SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  g_test_count   PLS_INTEGER := 0;
  g_current_test VARCHAR2(200);

  c_expected_test_count CONSTANT PLS_INTEGER := 41;

  l_account_id        BEX_ACCOUNT.ACC_ID%TYPE;
  l_public_id         BEX_SESSION.SESSION_PUBLIC_ID%TYPE;
  l_token             VARCHAR2(128);
  l_expires_at        BEX_SESSION.SESSION_EXPIRES_AT%TYPE;
  l_session           BEX_SESSION%ROWTYPE;
  l_aux_session       BEX_SESSION%ROWTYPE;
  l_aux_public_id     BEX_SESSION.SESSION_PUBLIC_ID%TYPE;
  l_aux_token         VARCHAR2(128);
  l_aux_expires_at    BEX_SESSION.SESSION_EXPIRES_AT%TYPE;
  l_revoked_session   BEX_SESSION%ROWTYPE;
  l_expired_session   BEX_SESSION%ROWTYPE;
  l_overdue_session   BEX_SESSION%ROWTYPE;
  l_active_one        BEX_SESSION%ROWTYPE;
  l_active_two        BEX_SESSION%ROWTYPE;
  l_expired_one       BEX_SESSION%ROWTYPE;
  l_revoked_one       BEX_SESSION%ROWTYPE;
  l_future_session    BEX_SESSION%ROWTYPE;
  l_raised            BOOLEAN;
  l_original_time     BEX_SESSION.SESSION_REVOKED_AT%TYPE;
  l_duration_seconds  NUMBER;

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

  PROCEDURE create_account_fixture IS
    l_value VARCHAR2(32);
  BEGIN
    l_value := LOWER(RAWTOHEX(SYS_GUID()));

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
      l_value,
      'session.service.' || SUBSTR(l_value, 1, 20) || '@example.invalid',
      'session-service-test-credential',
      SYSTIMESTAMP,
      'ACTIVE'
    )
    RETURNING ACC_ID INTO l_account_id;
  END create_account_fixture;

  PROCEDURE create_session_fixture(
    p_session IN OUT BEX_SESSION%ROWTYPE,
    p_token   OUT VARCHAR2
  ) IS
    l_fixture_public_id BEX_SESSION.SESSION_PUBLIC_ID%TYPE;
    l_fixture_expires   BEX_SESSION.SESSION_EXPIRES_AT%TYPE;
  BEGIN
    acc_session_pkg.create_session(
      p_acc_id            => l_account_id,
      p_duration_minutes  => 60,
      p_created_by        => l_account_id,
      p_ip                => '127.0.0.1',
      p_user_agent        => 'ACC_SESSION_PKG test',
      p_session_public_id => l_fixture_public_id,
      p_session_token     => p_token,
      p_expires_at        => l_fixture_expires
    );

    p_session := acc_session_repository_pkg.get_by_public_id(
      l_fixture_public_id
    );
  END create_session_fixture;

  PROCEDURE expect_error(
    p_expected_code IN PLS_INTEGER,
    p_actual_code   IN PLS_INTEGER,
    p_raised        IN BOOLEAN
  ) IS
  BEGIN
    assert_true(p_raised, 'A excecao esperada nao foi lancada.');
    assert_true(
      p_actual_code = p_expected_code,
      'Codigo esperado=' || p_expected_code || ', recebido=' || p_actual_code
    );
  END expect_error;

  PROCEDURE run_tests IS
    l_error_code       PLS_INTEGER;
    l_fixture_token    VARCHAR2(128);
    l_second_token     VARCHAR2(128);
    l_third_token      VARCHAR2(128);
    l_fourth_token     VARCHAR2(128);
  BEGIN
    start_test('CREATE_SESSION cria uma sessao');
    acc_session_pkg.create_session(
      p_acc_id            => l_account_id,
      p_duration_minutes  => 10,
      p_created_by        => l_account_id,
      p_ip                => '192.0.2.10',
      p_user_agent        => 'Session service test agent',
      p_session_public_id => l_public_id,
      p_session_token     => l_token,
      p_expires_at        => l_expires_at
    );
    l_session := acc_session_repository_pkg.get_by_public_id(l_public_id);
    assert_true(l_session.SESSION_ID IS NOT NULL, 'A sessao nao foi criada.');
    pass;

    start_test('CREATE_SESSION retorna SESSION_PUBLIC_ID');
    assert_true(l_public_id IS NOT NULL, 'SESSION_PUBLIC_ID nao foi retornado.');
    pass;

    start_test('SESSION_PUBLIC_ID possui 32 caracteres hexadecimais');
    assert_true(
      REGEXP_LIKE(l_public_id, '^[0-9a-f]{32}$'),
      'SESSION_PUBLIC_ID possui formato invalido.'
    );
    pass;

    start_test('CREATE_SESSION retorna token');
    assert_true(l_token IS NOT NULL, 'O token nao foi retornado.');
    pass;

    start_test('Token possui 64 caracteres hexadecimais');
    assert_true(
      REGEXP_LIKE(l_token, '^[0-9a-f]{64}$'),
      'O token possui formato invalido.'
    );
    pass;

    start_test('Token original nao e persistido como hash');
    assert_true(
      l_session.SESSION_TOKEN_HASH <> l_token,
      'O token original foi persistido.'
    );
    pass;

    start_test('SESSION_TOKEN_HASH possui 128 caracteres hexadecimais');
    assert_true(
      REGEXP_LIKE(l_session.SESSION_TOKEN_HASH, '^[0-9a-f]{128}$'),
      'SESSION_TOKEN_HASH possui formato invalido.'
    );
    pass;

    start_test('Sessao criada possui status ACTIVE');
    assert_true(l_session.SESSION_STATUS = 'ACTIVE', 'Status inicial invalido.');
    pass;

    start_test('SESSION_CREATED_AT foi preenchido');
    assert_true(l_session.SESSION_CREATED_AT IS NOT NULL, 'CREATED_AT nulo.');
    pass;

    start_test('SESSION_EXPIRES_AT foi preenchido');
    assert_true(l_session.SESSION_EXPIRES_AT IS NOT NULL, 'EXPIRES_AT nulo.');
    pass;

    start_test('SESSION_EXPIRES_AT e posterior a SESSION_CREATED_AT');
    assert_true(
      l_session.SESSION_EXPIRES_AT > l_session.SESSION_CREATED_AT,
      'A expiracao nao e posterior a criacao.'
    );
    pass;

    start_test('Duracao corresponde a p_duration_minutes');
    l_duration_seconds :=
      (CAST(l_session.SESSION_EXPIRES_AT AS DATE)
       - CAST(l_session.SESSION_CREATED_AT AS DATE)) * 86400;
    assert_true(
      l_duration_seconds BETWEEN 599 AND 601,
      'Duracao inesperada: ' || TO_CHAR(l_duration_seconds)
    );
    pass;

    start_test('Conta inexistente gera c_err_account_not_found');
    l_raised := FALSE;
    l_error_code := NULL;
    BEGIN
      acc_session_pkg.create_session(
        -1, 10, NULL, NULL, NULL,
        l_aux_public_id, l_aux_token, l_aux_expires_at
      );
    EXCEPTION
      WHEN OTHERS THEN
        l_error_code := SQLCODE;
        IF l_error_code = acc_session_pkg.c_err_account_not_found THEN
          l_raised := TRUE;
        ELSE
          RAISE;
        END IF;
    END;
    expect_error(acc_session_pkg.c_err_account_not_found, l_error_code, l_raised);
    pass;

    start_test('Duracao zero gera c_err_invalid_duration');
    l_raised := FALSE;
    l_error_code := NULL;
    BEGIN
      acc_session_pkg.create_session(
        l_account_id, 0, NULL, NULL, NULL,
        l_aux_public_id, l_aux_token, l_aux_expires_at
      );
    EXCEPTION
      WHEN OTHERS THEN
        l_error_code := SQLCODE;
        IF l_error_code = acc_session_pkg.c_err_invalid_duration THEN
          l_raised := TRUE;
        ELSE
          RAISE;
        END IF;
    END;
    expect_error(acc_session_pkg.c_err_invalid_duration, l_error_code, l_raised);
    pass;

    start_test('Duracao negativa gera c_err_invalid_duration');
    l_raised := FALSE;
    l_error_code := NULL;
    BEGIN
      acc_session_pkg.create_session(
        l_account_id, -1, NULL, NULL, NULL,
        l_aux_public_id, l_aux_token, l_aux_expires_at
      );
    EXCEPTION
      WHEN OTHERS THEN
        l_error_code := SQLCODE;
        IF l_error_code = acc_session_pkg.c_err_invalid_duration THEN
          l_raised := TRUE;
        ELSE
          RAISE;
        END IF;
    END;
    expect_error(acc_session_pkg.c_err_invalid_duration, l_error_code, l_raised);
    pass;

    start_test('VALIDATE_SESSION retorna a sessao correta');
    l_aux_session := acc_session_pkg.validate_session(l_token, l_account_id);
    l_session := acc_session_repository_pkg.get_by_id(
      l_aux_session.SESSION_ID
    );
    assert_true(
      l_aux_session.SESSION_ID = l_session.SESSION_ID,
      'VALIDATE_SESSION retornou sessao incorreta.'
    );
    pass;

    start_test('VALIDATE_SESSION atualiza SESSION_LAST_USED_AT');
    assert_true(
      l_session.SESSION_LAST_USED_AT IS NOT NULL
      AND l_session.SESSION_LAST_USED_AT >= l_session.SESSION_CREATED_AT,
      'SESSION_LAST_USED_AT nao foi persistido.'
    );
    pass;

    start_test('VALIDATE_SESSION atualiza SESSION_UPDATED_BY');
    assert_true(
      l_session.SESSION_UPDATED_BY = l_account_id,
      'SESSION_UPDATED_BY nao foi persistido.'
    );
    pass;

    start_test('Token NULL gera c_err_invalid_token');
    l_raised := FALSE;
    l_error_code := NULL;
    BEGIN
      l_aux_session := acc_session_pkg.validate_session(NULL);
    EXCEPTION
      WHEN OTHERS THEN
        l_error_code := SQLCODE;
        IF l_error_code = acc_session_pkg.c_err_invalid_token THEN
          l_raised := TRUE;
        ELSE
          RAISE;
        END IF;
    END;
    expect_error(acc_session_pkg.c_err_invalid_token, l_error_code, l_raised);
    pass;

    start_test('Token curto gera c_err_invalid_token');
    l_raised := FALSE;
    l_error_code := NULL;
    BEGIN
      l_aux_session := acc_session_pkg.validate_session('abcd');
    EXCEPTION
      WHEN OTHERS THEN
        l_error_code := SQLCODE;
        IF l_error_code = acc_session_pkg.c_err_invalid_token THEN
          l_raised := TRUE;
        ELSE
          RAISE;
        END IF;
    END;
    expect_error(acc_session_pkg.c_err_invalid_token, l_error_code, l_raised);
    pass;

    start_test('Token nao hexadecimal gera c_err_invalid_token');
    l_raised := FALSE;
    l_error_code := NULL;
    BEGIN
      l_aux_session := acc_session_pkg.validate_session(RPAD('g', 64, 'g'));
    EXCEPTION
      WHEN OTHERS THEN
        l_error_code := SQLCODE;
        IF l_error_code = acc_session_pkg.c_err_invalid_token THEN
          l_raised := TRUE;
        ELSE
          RAISE;
        END IF;
    END;
    expect_error(acc_session_pkg.c_err_invalid_token, l_error_code, l_raised);
    pass;

    start_test('Token inexistente gera c_err_session_not_found');
    l_raised := FALSE;
    l_error_code := NULL;
    BEGIN
      l_aux_session := acc_session_pkg.validate_session(
        LOWER(RAWTOHEX(SYS_GUID())) || LOWER(RAWTOHEX(SYS_GUID()))
      );
    EXCEPTION
      WHEN OTHERS THEN
        l_error_code := SQLCODE;
        IF l_error_code = acc_session_pkg.c_err_session_not_found THEN
          l_raised := TRUE;
        ELSE
          RAISE;
        END IF;
    END;
    expect_error(acc_session_pkg.c_err_session_not_found, l_error_code, l_raised);
    pass;

    create_session_fixture(l_revoked_session, l_fixture_token);
    acc_session_pkg.revoke_session(
      l_revoked_session.SESSION_PUBLIC_ID,
      l_account_id
    );
    start_test('Sessao REVOKED gera c_err_session_inactive');
    l_raised := FALSE;
    l_error_code := NULL;
    BEGIN
      l_aux_session := acc_session_pkg.validate_session(l_fixture_token);
    EXCEPTION
      WHEN OTHERS THEN
        l_error_code := SQLCODE;
        IF l_error_code = acc_session_pkg.c_err_session_inactive THEN
          l_raised := TRUE;
        ELSE
          RAISE;
        END IF;
    END;
    expect_error(acc_session_pkg.c_err_session_inactive, l_error_code, l_raised);
    pass;

    create_session_fixture(l_expired_session, l_second_token);
    acc_session_repository_pkg.update_status(
      l_expired_session.SESSION_ID, 'EXPIRED', NULL, 2400
    );
    start_test('Sessao EXPIRED gera c_err_session_inactive');
    l_raised := FALSE;
    l_error_code := NULL;
    BEGIN
      l_aux_session := acc_session_pkg.validate_session(l_second_token);
    EXCEPTION
      WHEN OTHERS THEN
        l_error_code := SQLCODE;
        IF l_error_code = acc_session_pkg.c_err_session_inactive THEN
          l_raised := TRUE;
        ELSE
          RAISE;
        END IF;
    END;
    expect_error(acc_session_pkg.c_err_session_inactive, l_error_code, l_raised);
    pass;

    create_session_fixture(l_overdue_session, l_third_token);
    UPDATE BEX_SESSION
       SET SESSION_EXPIRES_AT = SYSTIMESTAMP - INTERVAL '1' MINUTE
     WHERE SESSION_ID = l_overdue_session.SESSION_ID;
    start_test('Sessao ACTIVE vencida e atualizada para EXPIRED');
    l_raised := FALSE;
    l_error_code := NULL;
    BEGIN
      l_aux_session := acc_session_pkg.validate_session(l_third_token, 2500);
    EXCEPTION
      WHEN OTHERS THEN
        l_error_code := SQLCODE;
        IF l_error_code = acc_session_pkg.c_err_session_expired THEN
          l_raised := TRUE;
        ELSE
          RAISE;
        END IF;
    END;
    l_overdue_session := acc_session_repository_pkg.get_by_id(
      l_overdue_session.SESSION_ID
    );
    assert_true(l_overdue_session.SESSION_STATUS = 'EXPIRED', 'Status nao expirou.');
    pass;

    start_test('Sessao ACTIVE vencida gera c_err_session_expired');
    expect_error(acc_session_pkg.c_err_session_expired, l_error_code, l_raised);
    pass;

    start_test('Expiracao automatica nao preenche SESSION_REVOKED_AT');
    assert_true(
      l_overdue_session.SESSION_REVOKED_AT IS NULL,
      'Expiracao preencheu SESSION_REVOKED_AT.'
    );
    pass;

    start_test('GET_SESSION_BY_PUBLIC_ID retorna a sessao correta');
    l_aux_session := acc_session_pkg.get_session_by_public_id(l_public_id);
    assert_true(l_aux_session.SESSION_ID = l_session.SESSION_ID, 'Sessao incorreta.');
    pass;

    start_test('Public id inexistente gera c_err_session_not_found');
    l_raised := FALSE;
    l_error_code := NULL;
    BEGIN
      l_aux_session := acc_session_pkg.get_session_by_public_id(
        LOWER(RAWTOHEX(SYS_GUID()))
      );
    EXCEPTION
      WHEN OTHERS THEN
        l_error_code := SQLCODE;
        IF l_error_code = acc_session_pkg.c_err_session_not_found THEN
          l_raised := TRUE;
        ELSE
          RAISE;
        END IF;
    END;
    expect_error(acc_session_pkg.c_err_session_not_found, l_error_code, l_raised);
    pass;

    create_session_fixture(l_aux_session, l_fourth_token);
    start_test('REVOKE_SESSION altera ACTIVE para REVOKED');
    acc_session_pkg.revoke_session(l_aux_session.SESSION_PUBLIC_ID, 3000);
    l_aux_session := acc_session_repository_pkg.get_by_id(l_aux_session.SESSION_ID);
    assert_true(l_aux_session.SESSION_STATUS = 'REVOKED', 'Sessao nao revogada.');
    pass;

    start_test('REVOKE_SESSION preenche SESSION_REVOKED_AT');
    assert_true(l_aux_session.SESSION_REVOKED_AT IS NOT NULL, 'REVOKED_AT nulo.');
    pass;

    start_test('REVOKE_SESSION atualiza SESSION_UPDATED_BY');
    assert_true(l_aux_session.SESSION_UPDATED_BY = 3000, 'UPDATED_BY incorreto.');
    pass;

    start_test('REVOKE_SESSION e idempotente para sessao REVOKED');
    l_original_time := l_aux_session.SESSION_REVOKED_AT;
    acc_session_pkg.revoke_session(l_aux_session.SESSION_PUBLIC_ID, 3001);
    l_aux_session := acc_session_repository_pkg.get_by_id(l_aux_session.SESSION_ID);
    assert_true(
      l_aux_session.SESSION_REVOKED_AT = l_original_time
      AND l_aux_session.SESSION_UPDATED_BY = 3000,
      'Segunda revogacao alterou a sessao.'
    );
    pass;

    start_test('REVOKE_SESSION nao altera sessao EXPIRED');
    acc_session_pkg.revoke_session(l_expired_session.SESSION_PUBLIC_ID, 3400);
    l_expired_session := acc_session_repository_pkg.get_by_id(
      l_expired_session.SESSION_ID
    );
    assert_true(
      l_expired_session.SESSION_STATUS = 'EXPIRED'
      AND l_expired_session.SESSION_REVOKED_AT IS NULL
      AND l_expired_session.SESSION_UPDATED_BY = 2400,
      'Sessao EXPIRED foi alterada.'
    );
    pass;

    create_session_fixture(l_active_one, l_fixture_token);
    create_session_fixture(l_active_two, l_second_token);
    create_session_fixture(l_expired_one, l_third_token);
    acc_session_repository_pkg.update_status(
      l_expired_one.SESSION_ID, 'EXPIRED', NULL, 3500
    );
    create_session_fixture(l_revoked_one, l_fourth_token);
    acc_session_repository_pkg.update_status(
      l_revoked_one.SESSION_ID, 'REVOKED', SYSTIMESTAMP, 3501
    );
    start_test('REVOKE_ALL_BY_ACCOUNT revoga todas as sessoes ACTIVE');
    acc_session_pkg.revoke_all_by_account(l_account_id, 3502);

    l_active_one := acc_session_repository_pkg.get_by_id(l_active_one.SESSION_ID);
    l_active_two := acc_session_repository_pkg.get_by_id(l_active_two.SESSION_ID);
    assert_true(
      l_active_one.SESSION_STATUS = 'REVOKED'
      AND l_active_two.SESSION_STATUS = 'REVOKED',
      'Sessoes ACTIVE nao foram revogadas.'
    );
    pass;

    start_test('REVOKE_ALL_BY_ACCOUNT nao altera sessoes EXPIRED');
    l_expired_one := acc_session_repository_pkg.get_by_id(l_expired_one.SESSION_ID);
    assert_true(
      l_expired_one.SESSION_STATUS = 'EXPIRED'
      AND l_expired_one.SESSION_UPDATED_BY = 3500,
      'Sessao EXPIRED foi alterada.'
    );
    pass;

    start_test('REVOKE_ALL_BY_ACCOUNT nao altera sessoes REVOKED');
    l_revoked_one := acc_session_repository_pkg.get_by_id(l_revoked_one.SESSION_ID);
    assert_true(
      l_revoked_one.SESSION_STATUS = 'REVOKED'
      AND l_revoked_one.SESSION_UPDATED_BY = 3501,
      'Sessao REVOKED foi alterada.'
    );
    pass;

    start_test('REVOKE_ALL com conta inexistente gera erro nominal');
    l_raised := FALSE;
    l_error_code := NULL;
    BEGIN
      acc_session_pkg.revoke_all_by_account(-1, NULL);
    EXCEPTION
      WHEN OTHERS THEN
        l_error_code := SQLCODE;
        IF l_error_code = acc_session_pkg.c_err_account_not_found THEN
          l_raised := TRUE;
        ELSE
          RAISE;
        END IF;
    END;
    expect_error(acc_session_pkg.c_err_account_not_found, l_error_code, l_raised);
    pass;

    create_session_fixture(l_overdue_session, l_fixture_token);
    UPDATE BEX_SESSION
       SET SESSION_EXPIRES_AT = SYSTIMESTAMP - INTERVAL '1' MINUTE
     WHERE SESSION_ID = l_overdue_session.SESSION_ID;
    create_session_fixture(l_future_session, l_second_token);
    UPDATE BEX_SESSION
       SET SESSION_EXPIRES_AT = SYSTIMESTAMP + INTERVAL '1' DAY
     WHERE SESSION_ID = l_future_session.SESSION_ID;
    create_session_fixture(l_revoked_session, l_third_token);
    UPDATE BEX_SESSION
       SET SESSION_EXPIRES_AT = SYSTIMESTAMP - INTERVAL '1' MINUTE
     WHERE SESSION_ID = l_revoked_session.SESSION_ID;
    acc_session_repository_pkg.update_status(
      l_revoked_session.SESSION_ID, 'REVOKED', SYSTIMESTAMP, 4000
    );
    start_test('EXPIRE_SESSIONS expira sessoes ACTIVE vencidas');
    acc_session_pkg.expire_sessions(SYSTIMESTAMP, 4001);

    l_overdue_session := acc_session_repository_pkg.get_by_id(
      l_overdue_session.SESSION_ID
    );
    assert_true(l_overdue_session.SESSION_STATUS = 'EXPIRED', 'Sessao nao expirou.');
    pass;

    start_test('EXPIRE_SESSIONS nao expira sessoes futuras');
    l_future_session := acc_session_repository_pkg.get_by_id(
      l_future_session.SESSION_ID
    );
    assert_true(l_future_session.SESSION_STATUS = 'ACTIVE', 'Sessao futura expirou.');
    pass;

    start_test('EXPIRE_SESSIONS nao altera sessoes REVOKED');
    l_revoked_session := acc_session_repository_pkg.get_by_id(
      l_revoked_session.SESSION_ID
    );
    assert_true(
      l_revoked_session.SESSION_STATUS = 'REVOKED'
      AND l_revoked_session.SESSION_UPDATED_BY = 4000,
      'Sessao REVOKED foi alterada.'
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

  ROLLBACK;
  DBMS_OUTPUT.PUT_LINE('ACC_SESSION_PKG: PASSED');
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE('ACC_SESSION_PKG: FAILED');
    RAISE_APPLICATION_ERROR(
      -20900,
      NVL(g_current_test, 'initialization') || ': ' || SQLERRM
    );
END;
/
