SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  g_test_count   PLS_INTEGER := 0;
  g_current_test VARCHAR2(200);

  c_expected_test_count CONSTANT PLS_INTEGER := 62;
  c_audit_actor_id       CONSTANT NUMBER := 4101;
  c_update_actor_id      CONSTANT NUMBER := 4102;

  l_account_id        BEX_ACCOUNT.ACC_ID%TYPE;
  l_second_account_id BEX_ACCOUNT.ACC_ID%TYPE;
  l_third_account_id  BEX_ACCOUNT.ACC_ID%TYPE;
  l_fourth_account_id BEX_ACCOUNT.ACC_ID%TYPE;
  l_account_public_id        BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE;
  l_second_account_public_id BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE;
  l_third_account_public_id  BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE;
  l_fourth_account_public_id BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE;
  l_profile           BEX_PROFILE%ROWTYPE;
  l_aux_profile       BEX_PROFILE%ROWTYPE;
  l_original_profile  BEX_PROFILE%ROWTYPE;
  l_raised            BOOLEAN;
  l_source_count      PLS_INTEGER;

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
    o_account_id        OUT BEX_ACCOUNT.ACC_ID%TYPE,
    o_account_public_id OUT BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE
  ) IS
    l_value   VARCHAR2(32);
    l_email   VARCHAR2(255);
    l_account BEX_ACCOUNT%ROWTYPE;
  BEGIN
    l_value := LOWER(RAWTOHEX(SYS_GUID()));
    l_email := 'profile.service.' || SUBSTR(l_value, 1, 20)
               || '@example.invalid';

    acc_repository_pkg.insert_account(
      p_public_id           => l_value,
      p_email               => l_email,
      p_email_verified_at   => NULL,
      p_credential          => 'profile-service-test-credential',
      p_password_changed_at => SYSTIMESTAMP,
      p_status              => 'ACTIVE',
      p_last_login_at       => NULL,
      p_created_by          => NULL,
      p_updated_by          => NULL
    );

    l_account := acc_repository_pkg.get_by_email(l_email);
    o_account_id := l_account.ACC_ID;
    o_account_public_id := l_account.ACC_PUBLIC_ID;
  END create_account_fixture;

  FUNCTION create_valid_profile(
    p_account_id     IN BEX_PROFILE.ACC_ID%TYPE,
    p_audit_actor_id IN BEX_PROFILE.PFL_CREATED_BY%TYPE
  ) RETURN BEX_PROFILE%ROWTYPE IS
  BEGIN
    RETURN pfl_service_pkg.create_profile(
      p_account_id     => p_account_id,
      p_display_name   => '  Profile    Service  ',
      p_full_name      => '  Profile    Service Full Name  ',
      p_birth_date     => DATE '1990-05-10',
      p_bio            => 'Profile service biography',
      p_avatar_url     => 'https://example.invalid/profile-service.png',
      p_locale_code    => 'pt-BR',
      p_timezone_name  => 'America/Sao_Paulo',
      p_audit_actor_id => p_audit_actor_id
    );
  END create_valid_profile;

  PROCEDURE assert_rule_failure(
    p_rule_name  IN VARCHAR2,
    p_account_id IN BEX_PROFILE.ACC_ID%TYPE
  ) IS
    l_result BEX_PROFILE%ROWTYPE;
  BEGIN
    l_raised := FALSE;
    BEGIN
      l_result := pfl_service_pkg.create_profile(
        p_account_id     => p_account_id,
        p_display_name   => CASE WHEN p_rule_name = 'DISPLAY' THEN 'x' ELSE 'Valid Name' END,
        p_full_name      => CASE WHEN p_rule_name = 'FULL' THEN 'x' ELSE NULL END,
        p_birth_date     => CASE WHEN p_rule_name = 'BIRTH' THEN TRUNC(SYSDATE) + 1 ELSE NULL END,
        p_bio            => NULL,
        p_avatar_url     => NULL,
        p_locale_code    => CASE WHEN p_rule_name = 'LOCALE' THEN 'en-US' ELSE 'pt-BR' END,
        p_timezone_name  => CASE WHEN p_rule_name = 'TIMEZONE' THEN 'UTC' ELSE 'America/Sao_Paulo' END,
        p_audit_actor_id => c_audit_actor_id
      );
    EXCEPTION
      WHEN pfl_rule_pkg.e_invalid_display_name THEN
        l_raised := p_rule_name = 'DISPLAY';
      WHEN pfl_rule_pkg.e_invalid_full_name THEN
        l_raised := p_rule_name = 'FULL';
      WHEN pfl_rule_pkg.e_invalid_birth_date THEN
        l_raised := p_rule_name = 'BIRTH';
      WHEN pfl_rule_pkg.e_invalid_locale_code THEN
        l_raised := p_rule_name = 'LOCALE';
      WHEN pfl_rule_pkg.e_invalid_timezone_name THEN
        l_raised := p_rule_name = 'TIMEZONE';
    END;

    assert_true(l_raised, 'Excecao nominal incorreta para ' || p_rule_name || '.');
  END assert_rule_failure;

  PROCEDURE run_tests IS
    l_savepoint_profile_id BEX_PROFILE.PFL_ID%TYPE;
  BEGIN
    start_test('CREATE_PROFILE cria perfil valido');
    l_profile := create_valid_profile(l_account_id, c_audit_actor_id);
    assert_true(l_profile.PFL_ID IS NOT NULL, 'Perfil nao foi criado.');
    pass;

    start_test('CREATE_PROFILE retorna registro persistido');
    l_aux_profile := pfl_repository_pkg.get_by_id(l_profile.PFL_ID);
    assert_true(l_aux_profile.PFL_ID = l_profile.PFL_ID, 'Registro retornado nao foi persistido.');
    pass;

    start_test('CREATE_PROFILE gera identificador interno');
    assert_true(l_profile.PFL_ID IS NOT NULL, 'PFL_ID nao foi gerado.');
    pass;

    start_test('CREATE_PROFILE gera public ID');
    assert_true(TRIM(l_profile.PFL_PUBLIC_ID) IS NOT NULL, 'PFL_PUBLIC_ID nao foi gerado.');
    pass;

    start_test('CREATE_PROFILE gera public ID hexadecimal minusculo');
    assert_true(
      LENGTH(TRIM(l_profile.PFL_PUBLIC_ID)) = 32
      AND REGEXP_LIKE(TRIM(l_profile.PFL_PUBLIC_ID), '^[0-9a-f]{32}$', 'c'),
      'PFL_PUBLIC_ID deveria ter 32 caracteres hexadecimais minusculos.'
    );
    pass;

    start_test('CREATE_PROFILE vincula ACCOUNT');
    assert_true(l_profile.ACC_ID = l_account_id, 'ACC_ID nao foi preservado.');
    pass;

    start_test('CREATE_PROFILE normaliza display name');
    assert_true(l_profile.PFL_DISPLAY_NAME = 'Profile Service', 'Display name nao foi normalizado.');
    pass;

    start_test('CREATE_PROFILE normaliza full name');
    assert_true(l_profile.PFL_FULL_NAME = 'Profile Service Full Name', 'Full name nao foi normalizado.');
    pass;

    start_test('CREATE_PROFILE persiste campos de apresentacao');
    assert_true(
      l_profile.PFL_BIO = 'Profile service biography'
      AND l_profile.PFL_AVATAR_URL = 'https://example.invalid/profile-service.png',
      'Campos de apresentacao nao foram persistidos.'
    );
    pass;

    start_test('CREATE_PROFILE persiste dados regionais e nascimento');
    assert_true(
      l_profile.PFL_BIRTH_DATE = DATE '1990-05-10'
      AND l_profile.PFL_LOCALE_CODE = 'pt-BR'
      AND l_profile.PFL_TIMEZONE_NAME = 'America/Sao_Paulo',
      'Dados regionais ou nascimento nao foram persistidos.'
    );
    pass;

    start_test('CREATE_PROFILE persiste auditoria tecnica');
    assert_true(
      l_profile.PFL_CREATED_BY = c_audit_actor_id
      AND l_profile.PFL_UPDATED_BY = c_audit_actor_id,
      'Ator tecnico nao foi persistido na criacao.'
    );
    pass;

    start_test('CREATE_PROFILE preenche timestamps de auditoria');
    assert_true(
      l_profile.PFL_CREATED_AT IS NOT NULL
      AND l_profile.PFL_UPDATED_AT IS NOT NULL,
      'Timestamps de auditoria nao foram preenchidos.'
    );
    pass;

    start_test('CREATE_PROFILE propaga display name invalido');
    assert_rule_failure('DISPLAY', l_second_account_id);
    pass;

    start_test('CREATE_PROFILE propaga full name invalido');
    assert_rule_failure('FULL', l_second_account_id);
    pass;

    start_test('CREATE_PROFILE propaga data futura');
    assert_rule_failure('BIRTH', l_second_account_id);
    pass;

    start_test('CREATE_PROFILE propaga locale invalido');
    assert_rule_failure('LOCALE', l_second_account_id);
    pass;

    start_test('CREATE_PROFILE propaga timezone invalida');
    assert_rule_failure('TIMEZONE', l_second_account_id);
    pass;

    start_test('validacao falha antes da persistencia');
    assert_false(
      pfl_repository_pkg.account_has_profile(l_second_account_id),
      'Validacao invalida deixou alteracao parcial.'
    );
    pass;

    start_test('primeira criacao para ACCOUNT e aceita');
    assert_true(l_profile.ACC_ID = l_account_id, 'Primeira criacao deveria ser aceita.');
    pass;

    start_test('segunda criacao para ACCOUNT e rejeitada');
    l_raised := FALSE;
    BEGIN
      l_aux_profile := create_valid_profile(l_account_id, c_audit_actor_id);
    EXCEPTION
      WHEN pfl_service_pkg.e_account_already_has_profile THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'Segunda criacao deveria ser rejeitada.');
    pass;

    start_test('duplicidade levanta excecao nominal da Service');
    assert_true(l_raised, 'Excecao e_account_already_has_profile nao foi propagada.');
    pass;

    start_test('ACCOUNT permanece com apenas um PROFILE');
    l_aux_profile := pfl_repository_pkg.get_by_account_id(l_account_id);
    assert_true(l_aux_profile.PFL_ID = l_profile.PFL_ID, 'Perfil original nao foi preservado.');
    pass;

    start_test('GET_BY_ID retorna perfil existente');
    l_aux_profile := pfl_service_pkg.get_by_id(l_profile.PFL_ID);
    assert_true(l_aux_profile.PFL_ID = l_profile.PFL_ID, 'GET_BY_ID retornou perfil incorreto.');
    pass;

    start_test('GET_BY_ID rejeita perfil inexistente');
    l_raised := FALSE;
    BEGIN
      l_aux_profile := pfl_service_pkg.get_by_id(-1);
    EXCEPTION
      WHEN pfl_service_pkg.e_profile_not_found THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'GET_BY_ID deveria levantar e_profile_not_found.');
    pass;

    start_test('GET_BY_PUBLIC_ID retorna perfil existente');
    l_aux_profile := pfl_service_pkg.get_by_public_id(l_profile.PFL_PUBLIC_ID);
    assert_true(l_aux_profile.PFL_ID = l_profile.PFL_ID, 'GET_BY_PUBLIC_ID retornou perfil incorreto.');
    pass;

    start_test('GET_BY_PUBLIC_ID rejeita perfil inexistente');
    l_raised := FALSE;
    BEGIN
      l_aux_profile := pfl_service_pkg.get_by_public_id(LOWER(RAWTOHEX(SYS_GUID())));
    EXCEPTION
      WHEN pfl_service_pkg.e_profile_not_found THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'GET_BY_PUBLIC_ID deveria levantar e_profile_not_found.');
    pass;

    start_test('GET_BY_ACCOUNT_ID retorna perfil existente');
    l_aux_profile := pfl_service_pkg.get_by_account_id(l_account_id);
    assert_true(l_aux_profile.PFL_ID = l_profile.PFL_ID, 'GET_BY_ACCOUNT_ID retornou perfil incorreto.');
    pass;

    start_test('GET_BY_ACCOUNT_ID rejeita perfil inexistente');
    l_raised := FALSE;
    BEGIN
      l_aux_profile := pfl_service_pkg.get_by_account_id(l_second_account_id);
    EXCEPTION
      WHEN pfl_service_pkg.e_profile_not_found THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'GET_BY_ACCOUNT_ID deveria levantar e_profile_not_found.');
    pass;

    start_test('GET_BY_ACCOUNT_PUBLIC_ID retorna perfil existente');
    l_aux_profile := pfl_service_pkg.get_by_account_public_id(
      l_account_public_id
    );
    assert_true(
      l_aux_profile.PFL_ID = l_profile.PFL_ID,
      'GET_BY_ACCOUNT_PUBLIC_ID retornou perfil incorreto.'
    );
    pass;

    start_test('GET_BY_ACCOUNT_PUBLIC_ID resolve ACC_ID correto');
    assert_true(
      l_aux_profile.ACC_ID = l_account_id,
      'ACC_PUBLIC_ID nao foi resolvido para o ACC_ID correto.'
    );
    pass;

    start_test('GET_BY_ACCOUNT_PUBLIC_ID propaga conta inexistente');
    l_raised := FALSE;
    BEGIN
      l_aux_profile := pfl_service_pkg.get_by_account_public_id(
        LOWER(RAWTOHEX(SYS_GUID()))
      );
    EXCEPTION
      WHEN acc_service_pkg.e_account_not_found THEN
        l_raised := SQLCODE = -20840;
    END;
    assert_true(
      l_raised,
      'Conta inexistente deveria propagar codigo Oracle -20840.'
    );
    pass;

    start_test('GET_BY_ACCOUNT_PUBLIC_ID rejeita profile inexistente');
    l_raised := FALSE;
    BEGIN
      l_aux_profile := pfl_service_pkg.get_by_account_public_id(
        l_second_account_public_id
      );
    EXCEPTION
      WHEN pfl_service_pkg.e_profile_not_found THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'Conta sem PROFILE deveria ser rejeitada.');
    pass;

    start_test('CREATE_BY_ACCOUNT_PUBLIC_ID cria perfil valido');
    l_aux_profile := pfl_service_pkg.create_by_account_public_id(
      p_account_public_id => l_fourth_account_public_id,
      p_display_name      => '  Public    Account Profile  ',
      p_full_name         => '  Public    Account Full Name  ',
      p_birth_date        => DATE '1992-07-12',
      p_bio               => 'Public account profile biography',
      p_avatar_url        => 'https://example.invalid/public-account.png',
      p_locale_code       => 'pt-BR',
      p_timezone_name     => 'America/Sao_Paulo',
      p_audit_actor_id    => c_audit_actor_id
    );
    assert_true(l_aux_profile.PFL_ID IS NOT NULL, 'Perfil nao foi criado.');
    pass;

    start_test('CREATE_BY_ACCOUNT_PUBLIC_ID resolve ACC_ID correto');
    assert_true(
      l_aux_profile.ACC_ID = l_fourth_account_id,
      'Perfil foi associado a conta incorreta.'
    );
    pass;

    start_test('CREATE_BY_ACCOUNT_PUBLIC_ID preserva PFL_PUBLIC_ID');
    l_original_profile := pfl_repository_pkg.get_by_id(l_aux_profile.PFL_ID);
    assert_true(
      l_original_profile.PFL_PUBLIC_ID = l_aux_profile.PFL_PUBLIC_ID,
      'PFL_PUBLIC_ID retornado diverge do valor persistido.'
    );
    pass;

    start_test('CREATE_BY_ACCOUNT_PUBLIC_ID rejeita segunda criacao');
    l_raised := FALSE;
    BEGIN
      l_aux_profile := pfl_service_pkg.create_by_account_public_id(
        l_fourth_account_public_id,
        'Duplicate Profile', NULL, NULL, NULL, NULL,
        'pt-BR', 'America/Sao_Paulo', c_audit_actor_id
      );
    EXCEPTION
      WHEN pfl_service_pkg.e_account_already_has_profile THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'Segunda criacao deveria ser rejeitada.');
    pass;

    l_original_profile := l_profile;

    start_test('UPDATE_PROFILE atualiza perfil valido');
    l_profile := pfl_service_pkg.update_profile(
      p_profile_id     => l_profile.PFL_ID,
      p_display_name   => '  Updated    Profile  ',
      p_full_name      => '  Updated    Full Name  ',
      p_birth_date     => DATE '1991-06-11',
      p_bio            => 'Updated service biography',
      p_avatar_url     => 'https://example.invalid/updated-service.png',
      p_locale_code    => 'pt-BR',
      p_timezone_name  => 'America/Sao_Paulo',
      p_audit_actor_id => c_update_actor_id
    );
    assert_true(l_profile.PFL_DISPLAY_NAME = 'Updated Profile', 'Perfil nao foi atualizado.');
    pass;

    start_test('UPDATE_PROFILE normaliza nomes');
    assert_true(
      l_profile.PFL_DISPLAY_NAME = 'Updated Profile'
      AND l_profile.PFL_FULL_NAME = 'Updated Full Name',
      'Nomes atualizados nao foram normalizados.'
    );
    pass;

    start_test('UPDATE_PROFILE persiste campos editaveis');
    l_aux_profile := pfl_repository_pkg.get_by_id(l_profile.PFL_ID);
    assert_true(
      l_aux_profile.PFL_BIRTH_DATE = DATE '1991-06-11'
      AND l_aux_profile.PFL_BIO = 'Updated service biography'
      AND l_aux_profile.PFL_AVATAR_URL = 'https://example.invalid/updated-service.png',
      'Campos atualizados nao foram persistidos.'
    );
    pass;

    start_test('UPDATE_PROFILE persiste auditoria de atualizacao');
    assert_true(l_aux_profile.PFL_UPDATED_BY = c_update_actor_id, 'Ator de atualizacao nao foi persistido.');
    pass;

    start_test('UPDATE_PROFILE preserva identificadores');
    assert_true(
      l_profile.PFL_ID = l_original_profile.PFL_ID
      AND l_profile.ACC_ID = l_original_profile.ACC_ID
      AND l_profile.PFL_PUBLIC_ID = l_original_profile.PFL_PUBLIC_ID,
      'Identificadores imutaveis foram alterados.'
    );
    pass;

    start_test('UPDATE_PROFILE preserva auditoria de criacao');
    assert_true(
      l_profile.PFL_CREATED_AT = l_original_profile.PFL_CREATED_AT
      AND l_profile.PFL_CREATED_BY = l_original_profile.PFL_CREATED_BY,
      'Auditoria de criacao foi alterada.'
    );
    pass;

    start_test('UPDATE_PROFILE rejeita perfil inexistente');
    l_raised := FALSE;
    BEGIN
      l_aux_profile := pfl_service_pkg.update_profile(
        -1, 'Missing Profile', NULL, NULL, NULL, NULL,
        'pt-BR', 'America/Sao_Paulo', c_update_actor_id
      );
    EXCEPTION
      WHEN pfl_service_pkg.e_profile_not_found THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'UPDATE_PROFILE deveria levantar e_profile_not_found.');
    pass;

    start_test('UPDATE_PROFILE propaga validacao do Rule');
    l_raised := FALSE;
    BEGIN
      l_aux_profile := pfl_service_pkg.update_profile(
        l_profile.PFL_ID, 'x', NULL, NULL, NULL, NULL,
        'pt-BR', 'America/Sao_Paulo', c_update_actor_id
      );
    EXCEPTION
      WHEN pfl_rule_pkg.e_invalid_display_name THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'UPDATE_PROFILE nao propagou a excecao do Rule.');
    pass;

    l_original_profile := l_profile;

    start_test('UPDATE_BY_PUBLIC_ID atualiza perfil valido');
    l_profile := pfl_service_pkg.update_by_public_id(
      p_profile_public_id => l_profile.PFL_PUBLIC_ID,
      p_display_name      => '  Public    Update  ',
      p_full_name         => '  Public    Updated Name  ',
      p_birth_date        => DATE '1993-08-13',
      p_bio               => 'Updated by public ID',
      p_avatar_url        => 'https://example.invalid/public-update.png',
      p_locale_code       => 'pt-BR',
      p_timezone_name     => 'America/Sao_Paulo',
      p_audit_actor_id    => c_update_actor_id
    );
    assert_true(
      l_profile.PFL_DISPLAY_NAME = 'Public Update',
      'Perfil nao foi atualizado por PFL_PUBLIC_ID.'
    );
    pass;

    start_test('UPDATE_BY_PUBLIC_ID preserva identificadores');
    assert_true(
      l_profile.PFL_ID = l_original_profile.PFL_ID
      AND l_profile.ACC_ID = l_original_profile.ACC_ID
      AND l_profile.PFL_PUBLIC_ID = l_original_profile.PFL_PUBLIC_ID,
      'Atualizacao por public ID alterou identificadores.'
    );
    pass;

    start_test('UPDATE_BY_PUBLIC_ID rejeita profile inexistente');
    l_raised := FALSE;
    BEGIN
      l_aux_profile := pfl_service_pkg.update_by_public_id(
        LOWER(RAWTOHEX(SYS_GUID())),
        'Missing Profile', NULL, NULL, NULL, NULL,
        'pt-BR', 'America/Sao_Paulo', c_update_actor_id
      );
    EXCEPTION
      WHEN pfl_service_pkg.e_profile_not_found THEN
        l_raised := TRUE;
    END;
    assert_true(l_raised, 'PFL_PUBLIC_ID inexistente deveria ser rejeitado.');
    pass;

    start_test('CREATE_PROFILE nao executa COMMIT');
    SAVEPOINT before_service_create;
    l_aux_profile := create_valid_profile(l_third_account_id, c_audit_actor_id);
    l_savepoint_profile_id := l_aux_profile.PFL_ID;
    ROLLBACK TO before_service_create;
    assert_false(
      pfl_repository_pkg.profile_exists(l_savepoint_profile_id),
      'ROLLBACK TO SAVEPOINT nao reverteu a criacao da Service.'
    );
    pass;

    start_test('UPDATE_PROFILE nao executa COMMIT');
    l_aux_profile := pfl_repository_pkg.get_by_id(l_profile.PFL_ID);
    SAVEPOINT before_service_update;
    l_profile := pfl_service_pkg.update_profile(
      l_profile.PFL_ID, 'Temporary Name', NULL, NULL, NULL, NULL,
      'pt-BR', 'America/Sao_Paulo', c_update_actor_id
    );
    ROLLBACK TO before_service_update;
    l_profile := pfl_repository_pkg.get_by_id(l_profile.PFL_ID);
    assert_true(
      l_profile.PFL_DISPLAY_NAME = l_aux_profile.PFL_DISPLAY_NAME,
      'ROLLBACK TO SAVEPOINT nao reverteu a atualizacao da Service.'
    );
    pass;

    start_test('Service nao contem SQL DML direto');
    SELECT COUNT(*)
      INTO l_source_count
      FROM USER_SOURCE
     WHERE NAME = 'PFL_SERVICE_PKG'
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
     WHERE NAME = 'PFL_SERVICE_PKG'
       AND TYPE = 'PACKAGE BODY'
       AND REGEXP_LIKE(UPPER(TEXT), '(^|[^A-Z_])COMMIT([^A-Z_]|$)');
    assert_true(l_source_count = 0, 'Service nao pode conter COMMIT.');
    pass;

    start_test('Service nao contem ROLLBACK');
    SELECT COUNT(*)
      INTO l_source_count
      FROM USER_SOURCE
     WHERE NAME = 'PFL_SERVICE_PKG'
       AND TYPE = 'PACKAGE BODY'
       AND REGEXP_LIKE(UPPER(TEXT), '(^|[^A-Z_])ROLLBACK([^A-Z_]|$)');
    assert_true(l_source_count = 0, 'Service nao pode conter ROLLBACK.');
    pass;

    start_test('Service nao captura DUP_VAL_ON_INDEX');
    SELECT COUNT(*)
      INTO l_source_count
      FROM USER_SOURCE
     WHERE NAME = 'PFL_SERVICE_PKG'
       AND TYPE = 'PACKAGE BODY'
       AND INSTR(UPPER(TEXT), 'DUP_VAL_ON_INDEX') > 0;
    assert_true(l_source_count = 0, 'DUP_VAL_ON_INDEX nao pode ser traduzido genericamente.');
    pass;

    start_test('Service nao contem WHEN OTHERS');
    SELECT COUNT(*)
      INTO l_source_count
      FROM USER_SOURCE
     WHERE NAME = 'PFL_SERVICE_PKG'
       AND TYPE = 'PACKAGE BODY'
       AND REGEXP_LIKE(UPPER(TEXT), 'WHEN[[:space:]]+OTHERS');
    assert_true(l_source_count = 0, 'Service nao pode ocultar falhas inesperadas.');
    pass;

    start_test('Service nao depende de componentes de apresentacao');
    SELECT COUNT(*)
      INTO l_source_count
      FROM USER_SOURCE
     WHERE NAME = 'PFL_SERVICE_PKG'
       AND TYPE = 'PACKAGE BODY'
       AND REGEXP_LIKE(
             UPPER(TEXT),
             'CORE_(RESPONSE|JSON)_PKG|PFL_API_PKG|ORDS|APEX'
           );
    assert_true(l_source_count = 0, 'Service possui dependencia de apresentacao.');
    pass;

    start_test('CREATE_BY_ACCOUNT_PUBLIC_ID existe no contrato publico');
    SELECT COUNT(*)
      INTO l_source_count
      FROM USER_PROCEDURES
     WHERE OBJECT_NAME = 'PFL_SERVICE_PKG'
       AND PROCEDURE_NAME = 'CREATE_BY_ACCOUNT_PUBLIC_ID';
    assert_true(l_source_count = 1, 'Operacao de criacao publica ausente.');
    pass;

    start_test('GET_BY_ACCOUNT_PUBLIC_ID existe no contrato publico');
    SELECT COUNT(*)
      INTO l_source_count
      FROM USER_PROCEDURES
     WHERE OBJECT_NAME = 'PFL_SERVICE_PKG'
       AND PROCEDURE_NAME = 'GET_BY_ACCOUNT_PUBLIC_ID';
    assert_true(l_source_count = 1, 'Operacao de consulta publica ausente.');
    pass;

    start_test('UPDATE_BY_PUBLIC_ID existe no contrato publico');
    SELECT COUNT(*)
      INTO l_source_count
      FROM USER_PROCEDURES
     WHERE OBJECT_NAME = 'PFL_SERVICE_PKG'
       AND PROCEDURE_NAME = 'UPDATE_BY_PUBLIC_ID';
    assert_true(l_source_count = 1, 'Operacao de atualizacao publica ausente.');
    pass;

    start_test('Service nao acessa Repository de ACCOUNT');
    SELECT COUNT(*)
      INTO l_source_count
      FROM USER_SOURCE
     WHERE NAME = 'PFL_SERVICE_PKG'
       AND TYPE = 'PACKAGE BODY'
       AND INSTR(UPPER(TEXT), 'ACC_REPOSITORY_PKG') > 0;
    assert_true(l_source_count = 0, 'Service acessa Repository de ACCOUNT.');
    pass;

    start_test('Service nao acessa Rule de ACCOUNT');
    SELECT COUNT(*)
      INTO l_source_count
      FROM USER_SOURCE
     WHERE NAME = 'PFL_SERVICE_PKG'
       AND TYPE = 'PACKAGE BODY'
       AND INSTR(UPPER(TEXT), 'ACC_RULE_PKG') > 0;
    assert_true(l_source_count = 0, 'Service acessa Rule de ACCOUNT.');
    pass;

    start_test('Service nao executa SQL sobre BEX_ACCOUNT');
    SELECT COUNT(*)
      INTO l_source_count
      FROM USER_SOURCE
     WHERE NAME = 'PFL_SERVICE_PKG'
       AND TYPE = 'PACKAGE BODY'
       AND REGEXP_LIKE(
             UPPER(TEXT),
             '(FROM|JOIN|INTO|UPDATE|INSERT[[:space:]]+INTO|DELETE[[:space:]]+FROM)[[:space:]]+BEX_ACCOUNT'
           );
    assert_true(l_source_count = 0, 'Service executa SQL sobre BEX_ACCOUNT.');
    pass;

    start_test('Service nao utiliza SQLERRM');
    SELECT COUNT(*)
      INTO l_source_count
      FROM USER_SOURCE
     WHERE NAME = 'PFL_SERVICE_PKG'
       AND TYPE = 'PACKAGE BODY'
       AND INSTR(UPPER(TEXT), 'SQLERRM') > 0;
    assert_true(l_source_count = 0, 'Service nao pode utilizar SQLERRM.');
    pass;
  END run_tests;
BEGIN
  create_account_fixture(l_account_id, l_account_public_id);
  create_account_fixture(l_second_account_id, l_second_account_public_id);
  create_account_fixture(l_third_account_id, l_third_account_public_id);
  create_account_fixture(l_fourth_account_id, l_fourth_account_public_id);
  run_tests;

  IF g_test_count <> c_expected_test_count THEN
    fail(
      'Quantidade de testes invalida. Esperado=' || c_expected_test_count
      || ', executado=' || g_test_count
    );
  END IF;

  ROLLBACK;
  DBMS_OUTPUT.PUT_LINE('PFL_SERVICE_PKG: PASSED');
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    DBMS_OUTPUT.PUT_LINE(
      'FAIL - ' || NVL(g_current_test, 'initialization')
    );
    RAISE;
END;
/
