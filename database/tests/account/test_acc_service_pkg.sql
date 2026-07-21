SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  g_test_count   PLS_INTEGER := 0;
  g_current_test VARCHAR2(200);

  c_expected_test_count CONSTANT PLS_INTEGER := 30;
  c_email                CONSTANT VARCHAR2(255) :=
    'service.test.create@example.invalid';
  c_second_email         CONSTANT VARCHAR2(255) :=
    'service.test.second@example.invalid';
  c_password             CONSTANT VARCHAR2(128) :=
    'ValidPassword123';
  c_new_password         CONSTANT VARCHAR2(128) :=
    'NewValidPassword456';

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

  PROCEDURE cleanup IS
  BEGIN
    DELETE FROM BEX_ACCOUNT
     WHERE ACC_EMAIL IN
           (
             c_email,
             c_second_email,
             'service.test.free@example.invalid'
           );
  END cleanup;

  PROCEDURE run_tests IS
    l_account          BEX_ACCOUNT%ROWTYPE;
    l_second_account   BEX_ACCOUNT%ROWTYPE;
    l_old_credential   VARCHAR2(255);
    l_available        BOOLEAN;
    l_raised           BOOLEAN;
    l_source_count     PLS_INTEGER;
  BEGIN
    start_test('CREATE_ACCOUNT cria conta com sucesso');
    l_account := acc_service_pkg.create_account(
      p_email      => '  SERVICE.TEST.CREATE@EXAMPLE.INVALID  ',
      p_password   => c_password,
      p_created_by => 3001
    );
    assert_true(l_account.ACC_ID IS NOT NULL, 'Conta nao foi criada.');
    pass;

    start_test('CREATE_ACCOUNT retorna ACC_ID preenchido');
    assert_true(l_account.ACC_ID IS NOT NULL, 'ACC_ID deveria estar preenchido.');
    pass;

    start_test('CREATE_ACCOUNT normaliza email');
    assert_true(l_account.ACC_EMAIL = c_email, 'Email nao foi normalizado.');
    pass;

    start_test('CREATE_ACCOUNT gera public ID hexadecimal');
    assert_true(
      LENGTH(TRIM(l_account.ACC_PUBLIC_ID)) = 32
      AND REGEXP_LIKE(TRIM(l_account.ACC_PUBLIC_ID), '^[0-9a-f]{32}$', 'c'),
      'Public ID deveria possuir 32 caracteres hexadecimais minusculos.'
    );
    pass;

    start_test('CREATE_ACCOUNT persiste status inicial');
    assert_true(
      l_account.ACC_STATUS = 'PENDING_EMAIL_VERIFICATION',
      'Status inicial incorreto.'
    );
    pass;

    start_test('CREATE_ACCOUNT mantem email nao verificado');
    assert_true(
      l_account.ACC_EMAIL_VERIFIED_AT IS NULL,
      'Email deveria iniciar nao verificado.'
    );
    pass;

    start_test('CREATE_ACCOUNT mantem ultimo login nulo');
    assert_true(
      l_account.ACC_LAST_LOGIN_AT IS NULL,
      'Ultimo login deveria iniciar nulo.'
    );
    pass;

    start_test('CREATE_ACCOUNT gera credencial');
    assert_true(
      l_account.ACC_PASSWORD_HASH IS NOT NULL,
      'Credencial deveria estar preenchida.'
    );
    pass;

    start_test('credencial aceita senha correta');
    assert_true(
      acc_password_pkg.verify_password(c_password, l_account.ACC_PASSWORD_HASH),
      'Credencial deveria aceitar a senha correta.'
    );
    pass;

    start_test('credencial rejeita senha incorreta');
    assert_false(
      acc_password_pkg.verify_password(
        'DifferentPassword789',
        l_account.ACC_PASSWORD_HASH
      ),
      'Credencial deveria rejeitar senha incorreta.'
    );
    pass;

    start_test('senhas iguais geram credenciais diferentes');
    l_second_account := acc_service_pkg.create_account(
      p_email    => c_second_email,
      p_password => c_password
    );
    assert_true(
      l_account.ACC_PASSWORD_HASH <> l_second_account.ACC_PASSWORD_HASH,
      'Contas diferentes deveriam receber credenciais diferentes.'
    );
    pass;

    start_test('CREATE_ACCOUNT rejeita email invalido');
    l_raised := FALSE;
    BEGIN
      l_second_account := acc_service_pkg.create_account(
        p_email    => 'invalid-email',
        p_password => c_password
      );
    EXCEPTION
      WHEN acc_rule_pkg.e_invalid_email THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'Email invalido deveria ser rejeitado.');
    pass;

    start_test('CREATE_ACCOUNT rejeita senha invalida');
    l_raised := FALSE;
    BEGIN
      l_second_account := acc_service_pkg.create_account(
        p_email    => 'service.test.invalid.password@example.invalid',
        p_password => 'short'
      );
    EXCEPTION
      WHEN acc_rule_pkg.e_invalid_password THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'Senha invalida deveria ser rejeitada.');
    pass;

    start_test('CREATE_ACCOUNT rejeita email duplicado');
    l_raised := FALSE;
    BEGIN
      l_second_account := acc_service_pkg.create_account(
        p_email    => c_email,
        p_password => c_password
      );
    EXCEPTION
      WHEN acc_rule_pkg.e_email_already_used THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'Email duplicado deveria ser rejeitado.');
    pass;

    start_test('EMAIL_AVAILABLE retorna verdadeiro para email livre');
    assert_true(
      acc_service_pkg.email_available('service.test.free@example.invalid'),
      'Email livre deveria estar disponivel.'
    );
    pass;

    start_test('EMAIL_AVAILABLE retorna falso para email existente');
    assert_false(
      acc_service_pkg.email_available(c_email),
      'Email existente nao deveria estar disponivel.'
    );
    pass;

    start_test('EMAIL_AVAILABLE normaliza email');
    assert_false(
      acc_service_pkg.email_available(
        '  SERVICE.TEST.CREATE@EXAMPLE.INVALID  '
      ),
      'EMAIL_AVAILABLE deveria normalizar o email.'
    );
    pass;

    start_test('EMAIL_AVAILABLE rejeita email invalido');
    l_raised := FALSE;
    BEGIN
      l_available := acc_service_pkg.email_available('invalid-email');
    EXCEPTION
      WHEN acc_rule_pkg.e_invalid_email THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'Email invalido deveria lancar excecao nominal.');
    pass;

    start_test('GET_ACCOUNT retorna conta existente');
    l_second_account := acc_service_pkg.get_account(l_account.ACC_ID);
    assert_true(
      l_second_account.ACC_ID = l_account.ACC_ID,
      'GET_ACCOUNT nao retornou a conta esperada.'
    );
    pass;

    start_test('GET_ACCOUNT rejeita conta inexistente');
    l_raised := FALSE;
    BEGIN
      l_second_account := acc_service_pkg.get_account(-999999999);
    EXCEPTION
      WHEN acc_rule_pkg.e_account_not_found THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'Conta inexistente deveria ser rejeitada.');
    pass;

    start_test('CHANGE_PASSWORD atualiza credencial');
    l_old_credential := l_account.ACC_PASSWORD_HASH;
    acc_service_pkg.change_password(l_account.ACC_ID, c_new_password);
    l_account := acc_service_pkg.get_account(l_account.ACC_ID);
    assert_true(
      l_account.ACC_PASSWORD_HASH <> l_old_credential,
      'Credencial deveria ser atualizada.'
    );
    pass;

    start_test('nova senha e aceita apos alteracao');
    assert_true(
      acc_password_pkg.verify_password(
        c_new_password,
        l_account.ACC_PASSWORD_HASH
      ),
      'Nova senha deveria verificar.'
    );
    pass;

    start_test('senha anterior e rejeitada apos alteracao');
    assert_false(
      acc_password_pkg.verify_password(
        c_password,
        l_account.ACC_PASSWORD_HASH
      ),
      'Senha anterior nao deveria verificar.'
    );
    pass;

    start_test('CHANGE_PASSWORD rejeita senha invalida');
    l_raised := FALSE;
    BEGIN
      acc_service_pkg.change_password(l_account.ACC_ID, 'short');
    EXCEPTION
      WHEN acc_rule_pkg.e_invalid_password THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'Senha invalida deveria ser rejeitada.');
    pass;

    start_test('CHANGE_PASSWORD rejeita conta inexistente');
    l_raised := FALSE;
    BEGIN
      acc_service_pkg.change_password(-999999999, c_new_password);
    EXCEPTION
      WHEN acc_rule_pkg.e_account_not_found THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'Conta inexistente deveria ser rejeitada.');
    pass;

    start_test('Service nao contem SQL DML direto');
    SELECT COUNT(*)
      INTO l_source_count
      FROM USER_SOURCE
     WHERE NAME = 'ACC_SERVICE_PKG'
       AND TYPE = 'PACKAGE BODY'
       AND REGEXP_LIKE(
             UPPER(TEXT),
             '(^|[^A-Z_])(SELECT|INSERT|UPDATE|DELETE|MERGE|EXECUTE[[:space:]]+IMMEDIATE)([^A-Z_]|$)'
           );
    assert_true(l_source_count = 0, 'Service nao pode conter SQL DML direto.');
    pass;

    start_test('Service nao contem COMMIT');
    SELECT COUNT(*)
      INTO l_source_count
      FROM USER_SOURCE
     WHERE NAME = 'ACC_SERVICE_PKG'
       AND TYPE = 'PACKAGE BODY'
       AND REGEXP_LIKE(UPPER(TEXT), '(^|[^A-Z_])COMMIT([^A-Z_]|$)');
    assert_true(l_source_count = 0, 'Service nao pode conter COMMIT.');
    pass;

    start_test('Service nao contem ROLLBACK');
    SELECT COUNT(*)
      INTO l_source_count
      FROM USER_SOURCE
     WHERE NAME = 'ACC_SERVICE_PKG'
       AND TYPE = 'PACKAGE BODY'
       AND REGEXP_LIKE(UPPER(TEXT), '(^|[^A-Z_])ROLLBACK([^A-Z_]|$)');
    assert_true(l_source_count = 0, 'Service nao pode conter ROLLBACK.');
    pass;

    start_test('Service nao contem WHEN OTHERS');
    SELECT COUNT(*)
      INTO l_source_count
      FROM USER_SOURCE
     WHERE NAME = 'ACC_SERVICE_PKG'
       AND TYPE = 'PACKAGE BODY'
       AND REGEXP_LIKE(
             UPPER(TEXT),
             'WHEN[[:space:]]+OTHERS'
           );
    assert_true(l_source_count = 0, 'Service nao pode conter WHEN OTHERS.');
    pass;

    start_test('Service nao chama DBMS_CRYPTO');
    SELECT COUNT(*)
      INTO l_source_count
      FROM USER_SOURCE
     WHERE NAME = 'ACC_SERVICE_PKG'
       AND TYPE = 'PACKAGE BODY'
       AND INSTR(UPPER(TEXT), 'DBMS_CRYPTO') > 0;
    assert_true(l_source_count = 0, 'Service nao pode chamar DBMS_CRYPTO.');
    pass;
  END run_tests;
BEGIN
  cleanup;
  run_tests;
  cleanup;

  IF g_test_count <> c_expected_test_count THEN
    fail(
      'Quantidade de testes invalida. Esperado=' || c_expected_test_count ||
      ', executado=' || g_test_count
    );
  END IF;

  DBMS_OUTPUT.PUT_LINE('ACC_SERVICE_PKG: PASSED');
EXCEPTION
  WHEN OTHERS THEN
    cleanup;
    DBMS_OUTPUT.PUT_LINE(
      'FAIL - ' || NVL(g_current_test, 'initialization')
    );
    RAISE;
END;
/
