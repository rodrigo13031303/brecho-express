SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  g_test_count   PLS_INTEGER := 0;
  g_current_test VARCHAR2(200);

  c_expected_test_count CONSTANT PLS_INTEGER := 43;

  l_account_id_one   BEX_ACCOUNT.ACC_ID%TYPE;
  l_account_id_two   BEX_ACCOUNT.ACC_ID%TYPE;
  l_account_id_empty BEX_ACCOUNT.ACC_ID%TYPE;
  l_store_id_one     BEX_STORE.STR_ID%TYPE;
  l_store_id_two     BEX_STORE.STR_ID%TYPE;
  l_public_id_one    BEX_STORE.STR_PUBLIC_ID%TYPE;
  l_public_id_two    BEX_STORE.STR_PUBLIC_ID%TYPE;
  l_slug_one         BEX_STORE.STR_SLUG%TYPE;
  l_slug_two         BEX_STORE.STR_SLUG%TYPE;
  l_run_token        VARCHAR2(16);
  l_store            str_repository_pkg.t_store_record;
  l_original_store   str_repository_pkg.t_store_record;
  l_stores           str_repository_pkg.t_store_table;
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
    l_public_id BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE;
    l_email     BEX_ACCOUNT.ACC_EMAIL%TYPE;
  BEGIN
    l_public_id := RAWTOHEX(SYS_GUID());
    l_email := 'store.repo.' || LOWER(RAWTOHEX(SYS_GUID())) ||
               '@example.invalid';

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
      l_public_id,
      l_email,
      'store-repository-test-credential',
      SYSTIMESTAMP,
      'ACTIVE'
    )
    RETURNING ACC_ID INTO o_account_id;
  END create_account_fixture;

  PROCEDURE insert_store_fixture(
    p_account_id  IN BEX_STORE.ACC_ID%TYPE,
    p_public_id   IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_slug        IN BEX_STORE.STR_SLUG%TYPE,
    p_name        IN BEX_STORE.STR_NAME%TYPE,
    p_status      IN BEX_STORE.STR_STATUS%TYPE,
    p_description IN BEX_STORE.STR_DESCRIPTION%TYPE,
    o_store_id    OUT BEX_STORE.STR_ID%TYPE
  ) IS
  BEGIN
    str_repository_pkg.insert_store(
      p_public_id     => p_public_id,
      p_account_id    => p_account_id,
      p_name          => p_name,
      p_slug          => p_slug,
      p_description   => p_description,
      p_status        => p_status,
      p_logo_url      => NULL,
      p_cover_url     => NULL,
      p_locale_code   => 'pt-BR',
      p_timezone_name => 'America/Sao_Paulo',
      p_created_by    => 1001,
      p_updated_by    => 1001,
      o_store_id      => o_store_id
    );
  END insert_store_fixture;

  PROCEDURE update_store_fixture(
    p_set_name          IN BOOLEAN := FALSE,
    p_name              IN BEX_STORE.STR_NAME%TYPE := NULL,
    p_set_slug          IN BOOLEAN := FALSE,
    p_slug              IN BEX_STORE.STR_SLUG%TYPE := NULL,
    p_set_description   IN BOOLEAN := FALSE,
    p_description       IN BEX_STORE.STR_DESCRIPTION%TYPE := NULL,
    p_set_logo_url      IN BOOLEAN := FALSE,
    p_logo_url          IN BEX_STORE.STR_LOGO_URL%TYPE := NULL,
    p_set_cover_url     IN BOOLEAN := FALSE,
    p_cover_url         IN BEX_STORE.STR_COVER_URL%TYPE := NULL,
    p_set_locale_code   IN BOOLEAN := FALSE,
    p_locale_code       IN BEX_STORE.STR_LOCALE_CODE%TYPE := NULL,
    p_set_timezone_name IN BOOLEAN := FALSE,
    p_timezone_name     IN BEX_STORE.STR_TIMEZONE_NAME%TYPE := NULL
  ) IS
  BEGIN
    str_repository_pkg.update_store(
      p_store_id          => l_store_id_one,
      p_set_name          => p_set_name,
      p_name              => p_name,
      p_set_slug          => p_set_slug,
      p_slug              => p_slug,
      p_set_description   => p_set_description,
      p_description       => p_description,
      p_set_logo_url      => p_set_logo_url,
      p_logo_url          => p_logo_url,
      p_set_cover_url     => p_set_cover_url,
      p_cover_url         => p_cover_url,
      p_set_locale_code   => p_set_locale_code,
      p_locale_code       => p_locale_code,
      p_set_timezone_name => p_set_timezone_name,
      p_timezone_name     => p_timezone_name,
      p_updated_at        => SYSTIMESTAMP,
      p_updated_by        => 2002,
      o_updated           => l_updated
    );
  END update_store_fixture;

  PROCEDURE run_tests IS
    l_count              PLS_INTEGER;
    l_source_count       PLS_INTEGER;
    l_savepoint_store_id BEX_STORE.STR_ID%TYPE;
    l_error_public_id    BEX_STORE.STR_PUBLIC_ID%TYPE;
    l_error_slug         BEX_STORE.STR_SLUG%TYPE;
  BEGIN
    start_test('Specification esta valida');
    SELECT COUNT(*)
      INTO l_count
      FROM USER_OBJECTS
     WHERE OBJECT_NAME = 'STR_REPOSITORY_PKG'
       AND OBJECT_TYPE = 'PACKAGE'
       AND STATUS = 'VALID';
    assert_true(l_count = 1, 'Specification deve estar VALID.');
    pass;

    start_test('Body esta valido');
    SELECT COUNT(*)
      INTO l_count
      FROM USER_OBJECTS
     WHERE OBJECT_NAME = 'STR_REPOSITORY_PKG'
       AND OBJECT_TYPE = 'PACKAGE BODY'
       AND STATUS = 'VALID';
    assert_true(l_count = 1, 'Body deve estar VALID.');
    pass;

    start_test('Package nao possui USER_ERRORS');
    SELECT COUNT(*)
      INTO l_count
      FROM USER_ERRORS
     WHERE NAME = 'STR_REPOSITORY_PKG'
       AND TYPE IN ('PACKAGE', 'PACKAGE BODY');
    assert_true(l_count = 0, 'Package nao pode possuir USER_ERRORS.');
    pass;

    start_test('INSERT_STORE persiste STORE valida');
    insert_store_fixture(
      l_account_id_one,
      l_public_id_one,
      l_slug_one,
      'Repository Store One',
      'DRAFT',
      NULL,
      l_store_id_one
    );
    assert_true(l_store_id_one IS NOT NULL, 'INSERT_STORE nao retornou STR_ID.');
    pass;

    start_test('INSERT_STORE preserva todos os valores preparados');
    l_store := str_repository_pkg.get_by_public_id(l_public_id_one);
    assert_true(
      l_store.str_id = l_store_id_one
      AND l_store.acc_id = l_account_id_one
      AND TRIM(l_store.str_public_id) = TRIM(l_public_id_one)
      AND l_store.str_name = 'Repository Store One'
      AND l_store.str_slug = l_slug_one
      AND l_store.str_status = 'DRAFT'
      AND l_store.str_locale_code = 'pt-BR'
      AND l_store.str_timezone_name = 'America/Sao_Paulo'
      AND l_store.str_created_by = 1001
      AND l_store.str_updated_by = 1001,
      'INSERT_STORE nao preservou os valores preparados.'
    );
    pass;

    start_test('INSERT_STORE usa defaults temporais e aceita opcionais NULL');
    assert_true(
      l_store.str_created_at IS NOT NULL
      AND l_store.str_updated_at IS NOT NULL
      AND l_store.str_description IS NULL
      AND l_store.str_logo_url IS NULL
      AND l_store.str_cover_url IS NULL,
      'Defaults temporais ou campos opcionais estao incorretos.'
    );
    pass;

    start_test('ACCOUNT de teste nao possui PROFILE');
    SELECT COUNT(*)
      INTO l_count
      FROM USER_TABLES
     WHERE TABLE_NAME = 'BEX_PROFILE';
    IF l_count = 1 THEN
      EXECUTE IMMEDIATE
        'SELECT COUNT(*) FROM BEX_PROFILE WHERE ACC_ID = :account_id'
        INTO l_count
        USING l_account_id_one;
    ELSE
      l_count := 0;
    END IF;
    assert_true(l_count = 0, 'ACCOUNT de teste nao deveria possuir PROFILE.');
    pass;

    start_test('Mesma ACCOUNT aceita segunda STORE');
    insert_store_fixture(
      l_account_id_one,
      l_public_id_two,
      l_slug_two,
      'Repository Store Two',
      'ACTIVE',
      'Second store',
      l_store_id_two
    );
    assert_true(l_store_id_two IS NOT NULL, 'Segunda STORE nao foi inserida.');
    pass;

    start_test('GET_BY_PUBLIC_ID retorna todas as colunas');
    l_store := str_repository_pkg.get_by_public_id(l_public_id_two);
    assert_true(
      l_store.str_id = l_store_id_two
      AND l_store.acc_id = l_account_id_one
      AND TRIM(l_store.str_public_id) = TRIM(l_public_id_two)
      AND l_store.str_name = 'Repository Store Two'
      AND l_store.str_slug = l_slug_two
      AND l_store.str_description = 'Second store'
      AND l_store.str_status = 'ACTIVE'
      AND l_store.str_logo_url IS NULL
      AND l_store.str_cover_url IS NULL
      AND l_store.str_locale_code = 'pt-BR'
      AND l_store.str_timezone_name = 'America/Sao_Paulo'
      AND l_store.str_created_at IS NOT NULL
      AND l_store.str_created_by = 1001
      AND l_store.str_updated_at IS NOT NULL
      AND l_store.str_updated_by = 1001,
      'GET_BY_PUBLIC_ID retornou colunas incorretas.'
    );
    pass;

    start_test('GET_BY_PUBLIC_ID inexistente retorna registro vazio');
    l_store := str_repository_pkg.get_by_public_id(RAWTOHEX(SYS_GUID()));
    assert_true(l_store.str_id IS NULL, 'Public ID inexistente deveria retornar vazio.');
    pass;

    start_test('GET_BY_SLUG retorna STORE existente');
    l_store := str_repository_pkg.get_by_slug(l_slug_one);
    assert_true(l_store.str_id = l_store_id_one, 'GET_BY_SLUG nao encontrou STORE.');
    pass;

    start_test('GET_BY_SLUG nao normaliza entrada');
    l_store := str_repository_pkg.get_by_slug(UPPER(l_slug_one));
    assert_true(l_store.str_id IS NULL, 'GET_BY_SLUG nao deve normalizar slug.');
    pass;

    start_test('GET_BY_SLUG inexistente retorna registro vazio');
    l_store := str_repository_pkg.get_by_slug('missing-' || l_run_token);
    assert_true(l_store.str_id IS NULL, 'Slug inexistente deveria retornar vazio.');
    pass;

    start_test('PUBLIC_ID_EXISTS retorna verdadeiro');
    assert_true(str_repository_pkg.public_id_exists(l_public_id_one), 'Public ID deveria existir.');
    pass;

    start_test('PUBLIC_ID_EXISTS retorna falso');
    assert_false(str_repository_pkg.public_id_exists(RAWTOHEX(SYS_GUID())), 'Public ID nao deveria existir.');
    pass;

    start_test('SLUG_EXISTS retorna verdadeiro');
    assert_true(str_repository_pkg.slug_exists(l_slug_one), 'Slug deveria existir.');
    pass;

    start_test('SLUG_EXISTS retorna falso');
    assert_false(str_repository_pkg.slug_exists('absent-' || l_run_token), 'Slug nao deveria existir.');
    pass;

    l_original_store := str_repository_pkg.get_by_public_id(l_public_id_one);

    start_test('UPDATE_STORE preserva campos ausentes');
    update_store_fixture;
    l_store := str_repository_pkg.get_by_public_id(l_public_id_one);
    assert_true(
      l_updated
      AND l_store.str_name = l_original_store.str_name
      AND l_store.str_slug = l_original_store.str_slug
      AND l_store.str_description IS NULL,
      'Campos ausentes nao foram preservados.'
    );
    pass;

    start_test('UPDATE_STORE altera STR_NAME individualmente');
    update_store_fixture(p_set_name => TRUE, p_name => 'Updated Store Name');
    l_store := str_repository_pkg.get_by_public_id(l_public_id_one);
    assert_true(l_store.str_name = 'Updated Store Name', 'STR_NAME nao foi atualizado.');
    pass;

    start_test('UPDATE_STORE altera STR_SLUG individualmente');
    l_slug_one := 'updated-store-' || l_run_token;
    update_store_fixture(p_set_slug => TRUE, p_slug => l_slug_one);
    l_store := str_repository_pkg.get_by_public_id(l_public_id_one);
    assert_true(l_store.str_slug = l_slug_one, 'STR_SLUG nao foi atualizado.');
    pass;

    start_test('UPDATE_STORE altera STR_DESCRIPTION individualmente');
    update_store_fixture(p_set_description => TRUE, p_description => 'Updated description');
    l_store := str_repository_pkg.get_by_public_id(l_public_id_one);
    assert_true(l_store.str_description = 'Updated description', 'STR_DESCRIPTION nao foi atualizado.');
    pass;

    start_test('UPDATE_STORE altera STR_LOGO_URL individualmente');
    update_store_fixture(p_set_logo_url => TRUE, p_logo_url => 'https://example.invalid/logo.png');
    l_store := str_repository_pkg.get_by_public_id(l_public_id_one);
    assert_true(l_store.str_logo_url = 'https://example.invalid/logo.png', 'STR_LOGO_URL nao foi atualizado.');
    pass;

    start_test('UPDATE_STORE altera STR_COVER_URL individualmente');
    update_store_fixture(p_set_cover_url => TRUE, p_cover_url => 'https://example.invalid/cover.png');
    l_store := str_repository_pkg.get_by_public_id(l_public_id_one);
    assert_true(l_store.str_cover_url = 'https://example.invalid/cover.png', 'STR_COVER_URL nao foi atualizado.');
    pass;

    start_test('UPDATE_STORE altera STR_LOCALE_CODE individualmente');
    update_store_fixture(p_set_locale_code => TRUE, p_locale_code => 'en-US');
    l_store := str_repository_pkg.get_by_public_id(l_public_id_one);
    assert_true(l_store.str_locale_code = 'en-US', 'STR_LOCALE_CODE nao foi atualizado.');
    pass;

    start_test('UPDATE_STORE altera STR_TIMEZONE_NAME individualmente');
    update_store_fixture(p_set_timezone_name => TRUE, p_timezone_name => 'UTC');
    l_store := str_repository_pkg.get_by_public_id(l_public_id_one);
    assert_true(l_store.str_timezone_name = 'UTC', 'STR_TIMEZONE_NAME nao foi atualizado.');
    pass;

    start_test('UPDATE_STORE altera campos combinados');
    update_store_fixture(
      p_set_name          => TRUE,
      p_name              => 'Combined Store',
      p_set_description   => TRUE,
      p_description       => 'Combined description',
      p_set_logo_url      => TRUE,
      p_logo_url          => 'https://example.invalid/combined-logo.png',
      p_set_cover_url     => TRUE,
      p_cover_url         => 'https://example.invalid/combined-cover.png',
      p_set_locale_code   => TRUE,
      p_locale_code       => 'pt-BR',
      p_set_timezone_name => TRUE,
      p_timezone_name     => 'America/Sao_Paulo'
    );
    l_store := str_repository_pkg.get_by_public_id(l_public_id_one);
    assert_true(
      l_store.str_name = 'Combined Store'
      AND l_store.str_description = 'Combined description'
      AND l_store.str_logo_url = 'https://example.invalid/combined-logo.png'
      AND l_store.str_cover_url = 'https://example.invalid/combined-cover.png'
      AND l_store.str_locale_code = 'pt-BR'
      AND l_store.str_timezone_name = 'America/Sao_Paulo',
      'Update combinado nao persistiu todos os campos.'
    );
    pass;

    start_test('UPDATE_STORE limpa campos anulaveis presentes com NULL');
    update_store_fixture(
      p_set_description => TRUE,
      p_description     => NULL,
      p_set_logo_url    => TRUE,
      p_logo_url        => NULL,
      p_set_cover_url   => TRUE,
      p_cover_url       => NULL
    );
    l_store := str_repository_pkg.get_by_public_id(l_public_id_one);
    assert_true(
      l_store.str_description IS NULL
      AND l_store.str_logo_url IS NULL
      AND l_store.str_cover_url IS NULL,
      'Campos anulaveis presentes com NULL nao foram limpos.'
    );
    pass;

    start_test('UPDATE_STORE preserva campos imutaveis e status');
    assert_true(
      l_store.str_id = l_original_store.str_id
      AND l_store.str_public_id = l_original_store.str_public_id
      AND l_store.acc_id = l_original_store.acc_id
      AND l_store.str_status = l_original_store.str_status
      AND l_store.str_created_at = l_original_store.str_created_at
      AND l_store.str_created_by = l_original_store.str_created_by,
      'Update comum alterou campo imutavel ou status.'
    );
    pass;

    start_test('UPDATE_STORE atualiza auditoria de modificacao');
    assert_true(
      l_store.str_updated_at >= l_original_store.str_updated_at
      AND l_store.str_updated_by = 2002,
      'Update comum nao atualizou auditoria.'
    );
    pass;

    start_test('UPDATE_STORE inexistente informa falso');
    str_repository_pkg.update_store(
      -1, FALSE, NULL, FALSE, NULL, FALSE, NULL, FALSE, NULL,
      FALSE, NULL, FALSE, NULL, FALSE, NULL,
      SYSTIMESTAMP, NULL, l_updated
    );
    assert_false(l_updated, 'Update inexistente deveria informar FALSE.');
    pass;

    l_store := str_repository_pkg.get_by_public_id(l_public_id_one);
    start_test('UPDATE_STATUS altera status separadamente');
    str_repository_pkg.update_status(
      l_store_id_one, 'ACTIVE', SYSTIMESTAMP, 3003, l_updated
    );
    l_store := str_repository_pkg.get_by_public_id(l_public_id_one);
    assert_true(
      l_updated
      AND l_store.str_status = 'ACTIVE'
      AND l_store.str_updated_by = 3003,
      'UPDATE_STATUS nao persistiu status e auditoria.'
    );
    pass;

    start_test('UPDATE_STATUS preserva campos funcionais');
    assert_true(
      l_store.str_name = 'Combined Store'
      AND l_store.str_slug = l_slug_one
      AND l_store.str_description IS NULL
      AND l_store.str_locale_code = 'pt-BR',
      'UPDATE_STATUS alterou campos funcionais.'
    );
    pass;

    start_test('UPDATE_STATUS inexistente informa falso');
    str_repository_pkg.update_status(-1, 'ACTIVE', SYSTIMESTAMP, NULL, l_updated);
    assert_false(l_updated, 'UPDATE_STATUS inexistente deveria informar FALSE.');
    pass;

    start_test('LIST_BY_ACCOUNT retorna somente lojas da ACCOUNT');
    insert_store_fixture(
      l_account_id_two,
      RAWTOHEX(SYS_GUID()),
      'other-account-' || l_run_token,
      'Other Account Store',
      'DRAFT',
      NULL,
      l_savepoint_store_id
    );
    l_stores := str_repository_pkg.list_by_account(l_account_id_one);
    assert_true(
      l_stores.COUNT = 2
      AND l_stores(1).acc_id = l_account_id_one
      AND l_stores(2).acc_id = l_account_id_one,
      'LIST_BY_ACCOUNT retornou conjunto incorreto.'
    );
    pass;

    start_test('LIST_BY_ACCOUNT respeita ordenacao aprovada');
    assert_true(
      l_stores(1).str_created_at > l_stores(2).str_created_at
      OR (
        l_stores(1).str_created_at = l_stores(2).str_created_at
        AND l_stores(1).str_id > l_stores(2).str_id
      ),
      'LIST_BY_ACCOUNT nao respeitou CREATED_AT DESC, STR_ID DESC.'
    );
    pass;

    start_test('LIST_BY_ACCOUNT de ACCOUNT sem STORE retorna vazio');
    l_stores := str_repository_pkg.list_by_account(l_account_id_empty);
    assert_true(l_stores.COUNT = 0, 'ACCOUNT sem STORE deveria retornar colecao vazia.');
    pass;

    start_test('Public ID duplicado propaga DUP_VAL_ON_INDEX');
    l_raised := FALSE;
    BEGIN
      insert_store_fixture(
        l_account_id_two,
        l_public_id_one,
        'duplicate-public-' || l_run_token,
        'Duplicate Public ID',
        'DRAFT',
        NULL,
        l_savepoint_store_id
      );
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        l_raised := TRUE;
      WHEN OTHERS THEN
        fail('Public ID duplicado levantou excecao inesperada.');
    END;
    assert_true(l_raised, 'Public ID duplicado deveria propagar DUP_VAL_ON_INDEX.');
    pass;

    start_test('Slug duplicado propaga DUP_VAL_ON_INDEX');
    l_raised := FALSE;
    BEGIN
      insert_store_fixture(
        l_account_id_two,
        RAWTOHEX(SYS_GUID()),
        l_slug_one,
        'Duplicate Slug',
        'DRAFT',
        NULL,
        l_savepoint_store_id
      );
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        l_raised := TRUE;
      WHEN OTHERS THEN
        fail('Slug duplicado levantou excecao inesperada.');
    END;
    assert_true(l_raised, 'Slug duplicado deveria propagar DUP_VAL_ON_INDEX.');
    pass;

    start_test('ACC_ID inexistente propaga ORA-02291');
    l_raised := FALSE;
    BEGIN
      insert_store_fixture(
        -1,
        RAWTOHEX(SYS_GUID()),
        'missing-account-' || l_run_token,
        'Missing Account',
        'DRAFT',
        NULL,
        l_savepoint_store_id
      );
    EXCEPTION
      WHEN OTHERS THEN
        IF SQLCODE = -2291 THEN
          l_raised := TRUE;
        ELSE
          fail('ACC_ID inexistente levantou SQLCODE inesperado.');
        END IF;
    END;
    assert_true(l_raised, 'ACC_ID inexistente deveria propagar ORA-02291.');
    pass;

    start_test('Status invalido propaga ORA-02290');
    l_raised := FALSE;
    BEGIN
      insert_store_fixture(
        l_account_id_two,
        RAWTOHEX(SYS_GUID()),
        'invalid-status-' || l_run_token,
        'Invalid Status',
        'INVALID',
        NULL,
        l_savepoint_store_id
      );
    EXCEPTION
      WHEN OTHERS THEN
        IF SQLCODE = -2290 THEN
          l_raised := TRUE;
        ELSE
          fail('Status invalido levantou SQLCODE inesperado.');
        END IF;
    END;
    assert_true(l_raised, 'Status invalido deveria propagar ORA-02290.');
    pass;

    start_test('Repository nao executa COMMIT');
    l_error_public_id := RAWTOHEX(SYS_GUID());
    l_error_slug := 'rollback-' || l_run_token;
    SAVEPOINT before_repository_insert;
    insert_store_fixture(
      l_account_id_two,
      l_error_public_id,
      l_error_slug,
      'Rollback Store',
      'DRAFT',
      NULL,
      l_savepoint_store_id
    );
    assert_true(
      str_repository_pkg.public_id_exists(l_error_public_id),
      'STORE deveria estar visivel na mesma transacao.'
    );
    ROLLBACK TO before_repository_insert;
    assert_false(
      str_repository_pkg.public_id_exists(l_error_public_id),
      'ROLLBACK TO SAVEPOINT nao reverteu INSERT_STORE.'
    );
    pass;

    start_test('Repository nao possui transacao, Core, JSON ou SQL dinamico');
    SELECT COUNT(*)
      INTO l_source_count
      FROM USER_SOURCE
     WHERE NAME = 'STR_REPOSITORY_PKG'
       AND TYPE IN ('PACKAGE', 'PACKAGE BODY')
       AND REGEXP_LIKE(
             UPPER(TEXT),
             '(^|[^A-Z_])(COMMIT|ROLLBACK)([^A-Z_]|$)|' ||
             'AUTONOMOUS_TRANSACTION|CORE_[A-Z_]+_PKG|' ||
             'JSON_OBJECT|EXECUTE[[:space:]]+IMMEDIATE|DBMS_SQL'
           );
    assert_true(l_source_count = 0, 'Repository possui dependencia ou operacao proibida.');
    pass;

    start_test('Repository depende somente de BEX_STORE');
    SELECT COUNT(*)
      INTO l_source_count
      FROM USER_DEPENDENCIES
     WHERE NAME = 'STR_REPOSITORY_PKG'
       AND TYPE IN ('PACKAGE', 'PACKAGE BODY')
       AND REFERENCED_TYPE = 'TABLE'
       AND REFERENCED_NAME <> 'BEX_STORE';
    assert_true(l_source_count = 0, 'Repository acessa tabela externa ao modulo STORE.');
    pass;
  END run_tests;
BEGIN
  l_run_token := LOWER(SUBSTR(RAWTOHEX(SYS_GUID()), 1, 16));
  l_public_id_one := RAWTOHEX(SYS_GUID());
  l_public_id_two := RAWTOHEX(SYS_GUID());
  l_slug_one := 'repository-store-one-' || l_run_token;
  l_slug_two := 'repository-store-two-' || l_run_token;

  create_account_fixture(l_account_id_one);
  create_account_fixture(l_account_id_two);
  create_account_fixture(l_account_id_empty);
  run_tests;

  IF g_test_count <> c_expected_test_count THEN
    fail(
      'Quantidade de testes invalida. Esperado=' || c_expected_test_count ||
      ', executado=' || g_test_count
    );
  END IF;

  ROLLBACK;
  DBMS_OUTPUT.PUT_LINE('STR_REPOSITORY_PKG: PASSED');
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE(
      'FAIL - ' || NVL(g_current_test, 'initialization')
    );
    RAISE;
END;
/
