CREATE OR REPLACE PACKAGE BODY acc_service_pkg AS
  ------------------------------------------------------------------------------
  -- Constantes privadas
  ------------------------------------------------------------------------------

  c_initial_status CONSTANT VARCHAR2(30) :=
    'PENDING_EMAIL_VERIFICATION';

  ------------------------------------------------------------------------------
  -- Helpers privados
  ------------------------------------------------------------------------------

  FUNCTION generate_public_id
    RETURN VARCHAR2 IS
  BEGIN
    RETURN LOWER(RAWTOHEX(SYS_GUID()));
  END generate_public_id;

  ------------------------------------------------------------------------------
  -- Casos de uso
  ------------------------------------------------------------------------------

  FUNCTION create_account(
    p_email      IN VARCHAR2,
    p_password   IN VARCHAR2,
    p_created_by IN NUMBER DEFAULT NULL
  ) RETURN BEX_ACCOUNT%ROWTYPE IS
    l_email      VARCHAR2(255);
    l_public_id  VARCHAR2(32);
    l_credential VARCHAR2(255);
    l_account    BEX_ACCOUNT%ROWTYPE;
    l_exists     BOOLEAN;
  BEGIN
    l_email := acc_rule_pkg.normalize_email(p_email);
    acc_rule_pkg.validate_email(l_email);
    acc_rule_pkg.validate_password(p_password);

    l_exists := acc_repository_pkg.email_exists(l_email);
    acc_rule_pkg.assert_email_available(l_exists);

    l_public_id := generate_public_id;
    acc_rule_pkg.validate_public_id(l_public_id);
    acc_rule_pkg.validate_status(c_initial_status);

    l_credential := acc_password_pkg.hash_password(p_password);

    acc_repository_pkg.insert_account(
      p_public_id           => l_public_id,
      p_email               => l_email,
      p_email_verified_at   => NULL,
      p_credential          => l_credential,
      p_password_changed_at => SYSTIMESTAMP,
      p_status              => c_initial_status,
      p_last_login_at       => NULL,
      p_created_by          => p_created_by,
      p_updated_by          => p_created_by
    );

    l_account := acc_repository_pkg.get_by_email(l_email);
    acc_rule_pkg.assert_account_exists(l_account.ACC_ID IS NOT NULL);

    RETURN l_account;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      acc_rule_pkg.assert_email_available(TRUE);
      RAISE;
  END create_account;

  FUNCTION create_social_account(
    p_email      IN VARCHAR2,
    p_created_by IN NUMBER DEFAULT NULL
  ) RETURN BEX_ACCOUNT%ROWTYPE IS
    l_email     VARCHAR2(255);
    l_public_id VARCHAR2(32);
    l_account   BEX_ACCOUNT%ROWTYPE;
  BEGIN
    l_email := acc_rule_pkg.normalize_email(p_email);
    acc_rule_pkg.validate_email(l_email);
    acc_rule_pkg.assert_email_available(
      acc_repository_pkg.email_exists(l_email)
    );

    l_public_id := generate_public_id;
    acc_rule_pkg.validate_public_id(l_public_id);
    acc_rule_pkg.validate_status('ACTIVE');

    acc_repository_pkg.insert_account(
      p_public_id           => l_public_id,
      p_email               => l_email,
      p_email_verified_at   => SYSTIMESTAMP,
      p_credential          => NULL,
      p_password_changed_at => NULL,
      p_status              => 'ACTIVE',
      p_last_login_at       => SYSTIMESTAMP,
      p_created_by          => p_created_by,
      p_updated_by          => p_created_by
    );

    l_account := acc_repository_pkg.get_by_email(l_email);
    acc_rule_pkg.assert_account_exists(l_account.ACC_ID IS NOT NULL);
    RETURN l_account;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      acc_rule_pkg.assert_email_available(TRUE);
      RAISE;
  END create_social_account;

  PROCEDURE register_login(
    p_account_id IN NUMBER,
    p_updated_by IN NUMBER DEFAULT NULL
  ) IS
    l_account BEX_ACCOUNT%ROWTYPE;
  BEGIN
    l_account := acc_repository_pkg.get_by_id(p_account_id);
    acc_rule_pkg.assert_account_exists(l_account.ACC_ID IS NOT NULL);
    acc_repository_pkg.touch_last_login(p_account_id, p_updated_by);
  END register_login;

  PROCEDURE change_password(
    p_account_id IN NUMBER,
    p_password   IN VARCHAR2
  ) IS
    l_account    BEX_ACCOUNT%ROWTYPE;
    l_credential VARCHAR2(255);
  BEGIN
    acc_rule_pkg.validate_password(p_password);

    l_account := acc_repository_pkg.get_by_id(p_account_id);
    acc_rule_pkg.assert_account_exists(l_account.ACC_ID IS NOT NULL);

    l_credential := acc_password_pkg.hash_password(p_password);
    acc_repository_pkg.update_password(p_account_id, l_credential);
  END change_password;

  FUNCTION get_account(
    p_account_id IN NUMBER
  ) RETURN BEX_ACCOUNT%ROWTYPE IS
    l_account BEX_ACCOUNT%ROWTYPE;
  BEGIN
    l_account := acc_repository_pkg.get_by_id(p_account_id);
    acc_rule_pkg.assert_account_exists(l_account.ACC_ID IS NOT NULL);

    RETURN l_account;
  END get_account;

  FUNCTION get_by_public_id(
    p_public_id IN BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE
  ) RETURN BEX_ACCOUNT%ROWTYPE IS
  BEGIN
    RETURN acc_repository_pkg.get_by_public_id(
      p_public_id => p_public_id
    );
  END get_by_public_id;

  FUNCTION require_by_public_id(
    p_public_id IN BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE
  ) RETURN BEX_ACCOUNT%ROWTYPE IS
    l_account BEX_ACCOUNT%ROWTYPE;
  BEGIN
    l_account := get_by_public_id(
      p_public_id => p_public_id
    );

    IF l_account.ACC_ID IS NULL THEN
      RAISE e_account_not_found;
    END IF;

    RETURN l_account;
  END require_by_public_id;

  FUNCTION email_available(
    p_email IN VARCHAR2
  ) RETURN BOOLEAN IS
    l_email  VARCHAR2(255);
    l_exists BOOLEAN;
  BEGIN
    l_email := acc_rule_pkg.normalize_email(p_email);
    acc_rule_pkg.validate_email(l_email);

    l_exists := acc_repository_pkg.email_exists(l_email);

    RETURN NOT l_exists;
  END email_available;

  FUNCTION authenticate(
    p_email    IN VARCHAR2,
    p_password IN VARCHAR2
  ) RETURN BEX_ACCOUNT%ROWTYPE IS
    l_account BEX_ACCOUNT%ROWTYPE;
    l_email   VARCHAR2(255);
  BEGIN
    l_email := acc_rule_pkg.normalize_email(p_email);
    l_account := acc_repository_pkg.get_by_email(l_email);

    IF l_account.ACC_ID IS NULL
       OR l_account.ACC_STATUS <> 'ACTIVE'
       OR NOT acc_password_pkg.verify_password(p_password, l_account.ACC_PASSWORD_HASH) THEN
      RAISE e_invalid_credentials;
    END IF;

    RETURN l_account;
  END authenticate;
END acc_service_pkg;
/
