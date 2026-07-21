SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  g_test_count   PLS_INTEGER := 0;
  g_current_test VARCHAR2(200);

  c_expected_test_count CONSTANT PLS_INTEGER := 33;
  c_separator           CONSTANT VARCHAR2(1) := '$';

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

  FUNCTION component(
    p_credential IN VARCHAR2,
    p_position   IN PLS_INTEGER
  ) RETURN VARCHAR2 IS
    l_start PLS_INTEGER := 1;
    l_end   PLS_INTEGER;
  BEGIN
    FOR l_index IN 1 .. p_position LOOP
      l_end := INSTR(p_credential, c_separator, l_start);

      IF l_index = p_position THEN
        IF l_end = 0 THEN
          RETURN SUBSTR(p_credential, l_start);
        END IF;

        RETURN SUBSTR(p_credential, l_start, l_end - l_start);
      END IF;

      IF l_end = 0 THEN
        RETURN NULL;
      END IF;

      l_start := l_end + 1;
    END LOOP;

    RETURN NULL;
  END component;

  FUNCTION replace_component(
    p_credential IN VARCHAR2,
    p_position   IN PLS_INTEGER,
    p_value      IN VARCHAR2
  ) RETURN VARCHAR2 IS
    l_result VARCHAR2(32767);
  BEGIN
    FOR l_index IN 1 .. 4 LOOP
      IF l_index > 1 THEN
        l_result := l_result || c_separator;
      END IF;

      IF l_index = p_position THEN
        l_result := l_result || p_value;
      ELSE
        l_result := l_result || component(p_credential, l_index);
      END IF;
    END LOOP;

    RETURN l_result;
  END replace_component;

  FUNCTION alter_first_hex(
    p_hex IN VARCHAR2
  ) RETURN VARCHAR2 IS
  BEGIN
    RETURN CASE SUBSTR(p_hex, 1, 1)
      WHEN '0' THEN '1'
      ELSE '0'
    END || SUBSTR(p_hex, 2);
  END alter_first_hex;

  FUNCTION alter_last_hex(
    p_hex IN VARCHAR2
  ) RETURN VARCHAR2 IS
  BEGIN
    RETURN SUBSTR(p_hex, 1, LENGTH(p_hex) - 1)
      || CASE SUBSTR(p_hex, -1)
           WHEN '0' THEN '1'
           ELSE '0'
         END;
  END alter_last_hex;

  PROCEDURE run_tests IS
    l_credential_one VARCHAR2(255);
    l_credential_two VARCHAR2(255);
    l_salt_one       VARCHAR2(32767);
    l_salt_two       VARCHAR2(32767);
    l_hash_one       VARCHAR2(32767);
    l_hash_two       VARCHAR2(32767);
    l_altered        VARCHAR2(32767);
    l_raised         BOOLEAN;
    l_count          PLS_INTEGER;
  BEGIN
    l_credential_one := acc_password_pkg.hash_password(
      'Correct horse battery staple'
    );
    l_credential_two := acc_password_pkg.hash_password(
      'Correct horse battery staple'
    );
    l_salt_one := component(l_credential_one, 3);
    l_salt_two := component(l_credential_two, 3);
    l_hash_one := component(l_credential_one, 4);
    l_hash_two := component(l_credential_two, 4);

    start_test('formato v1 SHA512 completo');
    assert_true(
      REGEXP_LIKE(
        l_credential_one,
        '^v1\$SHA512\$[0-9A-F]{32}\$[0-9A-F]{128}$',
        'c'
      ),
      'Credencial fora do formato v1$SHA512$<salt>$<hash>.'
    );
    pass;

    start_test('formato possui exatamente quatro componentes');
    assert_true(
      component(l_credential_one, 1) IS NOT NULL
      AND component(l_credential_one, 2) IS NOT NULL
      AND component(l_credential_one, 3) IS NOT NULL
      AND component(l_credential_one, 4) IS NOT NULL
      AND INSTR(l_credential_one, c_separator, 1, 4) = 0,
      'Credencial deveria possuir exatamente quatro componentes.'
    );
    pass;

    start_test('versao correta e serializada como v1');
    assert_true(
      component(l_credential_one, 1) = 'v1'
      AND SUBSTR(l_credential_one, 1, 3) = 'v1$',
      'Versao serializada deveria ser v1.'
    );
    pass;

    start_test('versao desconhecida e rejeitada');
    l_altered := replace_component(l_credential_one, 1, 'v2');
    assert_false(
      acc_password_pkg.verify_password(
        'Correct horse battery staple',
        l_altered
      ),
      'Versao desconhecida nao deveria ser aceita.'
    );
    pass;

    start_test('algoritmo correto e SHA512');
    assert_true(
      component(l_credential_one, 2) = 'SHA512',
      'Algoritmo serializado deveria ser SHA512.'
    );
    pass;

    start_test('algoritmo desconhecido e rejeitado');
    l_altered := replace_component(l_credential_one, 2, 'SHA256');
    assert_false(
      acc_password_pkg.verify_password(
        'Correct horse battery staple',
        l_altered
      ),
      'Algoritmo desconhecido nao deveria ser aceito.'
    );
    pass;

    start_test('salt utiliza hexadecimal');
    assert_true(
      REGEXP_LIKE(l_salt_one, '^[0-9A-F]+$', 'c'),
      'Salt deveria ser hexadecimal.'
    );
    pass;

    start_test('salt possui tamanho aprovado');
    assert_true(
      LENGTH(l_salt_one) = 32,
      'Salt deveria representar 16 bytes.'
    );
    pass;

    start_test('salt nao hexadecimal e rejeitado');
    l_altered := replace_component(
      l_credential_one,
      3,
      'G' || SUBSTR(l_salt_one, 2)
    );
    assert_false(
      acc_password_pkg.verify_password(
        'Correct horse battery staple',
        l_altered
      ),
      'Salt nao hexadecimal nao deveria ser aceito.'
    );
    pass;

    start_test('salt com tamanho invalido e rejeitado');
    l_altered := replace_component(
      l_credential_one,
      3,
      SUBSTR(l_salt_one, 3)
    );
    assert_false(
      acc_password_pkg.verify_password(
        'Correct horse battery staple',
        l_altered
      ),
      'Salt com tamanho invalido nao deveria ser aceito.'
    );
    pass;

    start_test('hash utiliza hexadecimal');
    assert_true(
      REGEXP_LIKE(l_hash_one, '^[0-9A-F]+$', 'c'),
      'Hash deveria ser hexadecimal.'
    );
    pass;

    start_test('hash possui tamanho SHA512');
    assert_true(
      LENGTH(l_hash_one) = 128,
      'Hash SHA512 deveria representar 64 bytes.'
    );
    pass;

    start_test('hash nao hexadecimal e rejeitado');
    l_altered := replace_component(
      l_credential_one,
      4,
      'G' || SUBSTR(l_hash_one, 2)
    );
    assert_false(
      acc_password_pkg.verify_password(
        'Correct horse battery staple',
        l_altered
      ),
      'Hash nao hexadecimal nao deveria ser aceito.'
    );
    pass;

    start_test('hash com tamanho invalido e rejeitado');
    l_altered := replace_component(
      l_credential_one,
      4,
      SUBSTR(l_hash_one, 3)
    );
    assert_false(
      acc_password_pkg.verify_password(
        'Correct horse battery staple',
        l_altered
      ),
      'Hash com tamanho invalido nao deveria ser aceito.'
    );
    pass;

    start_test('mesma senha gera salts diferentes');
    assert_true(
      l_salt_one <> l_salt_two,
      'Duas geracoes produziram o mesmo salt.'
    );
    pass;

    start_test('mesma senha gera credenciais diferentes');
    assert_true(
      l_credential_one <> l_credential_two
      AND l_hash_one <> l_hash_two,
      'Duas geracoes produziram a mesma credencial.'
    );
    pass;

    start_test('senha correta verifica');
    assert_true(
      acc_password_pkg.verify_password(
        'Correct horse battery staple',
        l_credential_one
      ),
      'Senha correta deveria verificar.'
    );
    pass;

    start_test('senha incorreta nao verifica');
    assert_false(
      acc_password_pkg.verify_password('Wrong password', l_credential_one),
      'Senha incorreta nao deveria verificar.'
    );
    pass;

    start_test('credencial adulterada e rejeitada');
    l_altered := replace_component(
      l_credential_one,
      4,
      alter_last_hex(l_hash_one)
    );
    assert_false(
      acc_password_pkg.verify_password(
        'Correct horse battery staple',
        l_altered
      ),
      'Credencial adulterada nao deveria verificar.'
    );
    pass;

    start_test('componente ausente e rejeitado');
    assert_false(
      acc_password_pkg.verify_password(
        'Correct horse battery staple',
        'v1$SHA512$' || l_salt_one
      ),
      'Credencial com componente ausente nao deveria ser aceita.'
    );
    pass;

    start_test('componente extra e rejeitado');
    assert_false(
      acc_password_pkg.verify_password(
        'Correct horse battery staple',
        l_credential_one || c_separator || 'EXTRA'
      ),
      'Credencial com componente extra nao deveria ser aceita.'
    );
    pass;

    start_test('senha NULL e rejeitada no hash');
    l_raised := FALSE;
    BEGIN
      l_altered := acc_password_pkg.hash_password(NULL);
    EXCEPTION
      WHEN VALUE_ERROR THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'HASH_PASSWORD deveria rejeitar senha NULL.');
    pass;

    start_test('senha vazia e rejeitada no hash');
    l_raised := FALSE;
    BEGIN
      l_altered := acc_password_pkg.hash_password('');
    EXCEPTION
      WHEN VALUE_ERROR THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'HASH_PASSWORD deveria rejeitar senha vazia.');
    pass;

    start_test('senha NULL retorna falso na verificacao');
    assert_false(
      acc_password_pkg.verify_password(NULL, l_credential_one),
      'VERIFY_PASSWORD deveria rejeitar senha NULL.'
    );
    pass;

    start_test('senha vazia retorna falso na verificacao');
    assert_false(
      acc_password_pkg.verify_password('', l_credential_one),
      'VERIFY_PASSWORD deveria rejeitar senha vazia.'
    );
    pass;

    start_test('credencial NULL retorna falso');
    assert_false(
      acc_password_pkg.verify_password('Correct horse battery staple', NULL),
      'VERIFY_PASSWORD deveria rejeitar credencial NULL.'
    );
    pass;

    start_test('credencial vazia retorna falso');
    assert_false(
      acc_password_pkg.verify_password('Correct horse battery staple', ''),
      'VERIFY_PASSWORD deveria rejeitar credencial vazia.'
    );
    pass;

    start_test('credencial PBKDF2 antiga e rejeitada');
    assert_false(
      acc_password_pkg.verify_password(
        'Correct horse battery staple',
        'v1$PBKDF2-SHA512$210000$'
          || RPAD('A', 32, 'A') || '$' || RPAD('B', 128, 'B')
      ),
      'Credencial PBKDF2 antiga nao deveria ser aceita por esta versao.'
    );
    pass;

    start_test('parser permanece estavel em verificacoes repetidas');
    assert_true(
      acc_password_pkg.verify_password(
        'Correct horse battery staple',
        l_credential_one
      )
      AND acc_password_pkg.verify_password(
        'Correct horse battery staple',
        l_credential_one
      ),
      'Parser nao permaneceu estavel.'
    );
    pass;

    start_test('comparacao percorre divergencias nas extremidades');
    l_altered := replace_component(
      l_credential_one,
      4,
      alter_first_hex(l_hash_one)
    );
    assert_false(
      acc_password_pkg.verify_password(
        'Correct horse battery staple',
        l_altered
      ),
      'Divergencia no primeiro byte deveria ser rejeitada.'
    );

    l_altered := replace_component(
      l_credential_one,
      4,
      alter_last_hex(l_hash_one)
    );
    assert_false(
      acc_password_pkg.verify_password(
        'Correct horse battery staple',
        l_altered
      ),
      'Divergencia no ultimo byte deveria ser rejeitada.'
    );
    pass;

    start_test('body nao contem SQL permanente');
    SELECT COUNT(*)
      INTO l_count
      FROM USER_SOURCE
     WHERE NAME = 'ACC_PASSWORD_PKG'
       AND TYPE = 'PACKAGE BODY'
       AND REGEXP_LIKE(
             UPPER(TEXT),
             '(^|[^A-Z_])(SELECT|INSERT|UPDATE|DELETE|MERGE|EXECUTE[[:space:]]+IMMEDIATE)([^A-Z_]|$)'
           );
    assert_true(l_count = 0, 'Body nao deveria conter SQL permanente.');
    pass;

    start_test('body nao contem COMMIT');
    SELECT COUNT(*)
      INTO l_count
      FROM USER_SOURCE
     WHERE NAME = 'ACC_PASSWORD_PKG'
       AND TYPE = 'PACKAGE BODY'
       AND REGEXP_LIKE(UPPER(TEXT), '(^|[^A-Z_])COMMIT([^A-Z_]|$)');
    assert_true(l_count = 0, 'Body nao deveria conter COMMIT.');
    pass;

    start_test('body nao contem ROLLBACK');
    SELECT COUNT(*)
      INTO l_count
      FROM USER_SOURCE
     WHERE NAME = 'ACC_PASSWORD_PKG'
       AND TYPE = 'PACKAGE BODY'
       AND REGEXP_LIKE(UPPER(TEXT), '(^|[^A-Z_])ROLLBACK([^A-Z_]|$)');
    assert_true(l_count = 0, 'Body nao deveria conter ROLLBACK.');
    pass;
  END run_tests;
BEGIN
  run_tests;

  IF g_test_count <> c_expected_test_count THEN
    fail(
      'Quantidade de testes invalida. Esperado=' || c_expected_test_count ||
      ', executado=' || g_test_count
    );
  END IF;

  DBMS_OUTPUT.PUT_LINE('ACC_PASSWORD_PKG: PASSED');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE(
      'FAIL - ' || NVL(g_current_test, 'initialization')
    );
    RAISE;
END;
/
