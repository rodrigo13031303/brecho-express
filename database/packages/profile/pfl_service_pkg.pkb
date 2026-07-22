CREATE OR REPLACE PACKAGE BODY pfl_service_pkg AS
  ------------------------------------------------------------------------------
  -- Helpers privados
  ------------------------------------------------------------------------------

  FUNCTION generate_public_id
    RETURN VARCHAR2 IS
  BEGIN
    RETURN LOWER(RAWTOHEX(SYS_GUID()));
  END generate_public_id;

  FUNCTION resolve_account_id(
    p_account_public_id IN BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE
  ) RETURN BEX_ACCOUNT.ACC_ID%TYPE IS
    l_account BEX_ACCOUNT%ROWTYPE;
  BEGIN
    l_account := acc_service_pkg.require_by_public_id(
      p_public_id => p_account_public_id
    );

    RETURN l_account.ACC_ID;
  EXCEPTION
    WHEN acc_service_pkg.e_account_not_found THEN
      RAISE e_account_not_found;
  END resolve_account_id;

  PROCEDURE validate_profile_data(
    p_display_name  IN VARCHAR2,
    p_full_name     IN VARCHAR2,
    p_birth_date    IN DATE,
    p_locale_code   IN VARCHAR2,
    p_timezone_name IN VARCHAR2
  ) IS
  BEGIN
    pfl_rule_pkg.validate_display_name(p_display_name);
    pfl_rule_pkg.validate_full_name(p_full_name);
    pfl_rule_pkg.validate_birth_date(p_birth_date);
    pfl_rule_pkg.validate_locale_code(p_locale_code);
    pfl_rule_pkg.validate_timezone_name(p_timezone_name);
  EXCEPTION
    WHEN pfl_rule_pkg.e_invalid_display_name THEN
      RAISE e_invalid_display_name;
    WHEN pfl_rule_pkg.e_invalid_full_name THEN
      RAISE e_invalid_full_name;
    WHEN pfl_rule_pkg.e_invalid_birth_date THEN
      RAISE e_invalid_birth_date;
    WHEN pfl_rule_pkg.e_invalid_locale_code THEN
      RAISE e_invalid_locale_code;
    WHEN pfl_rule_pkg.e_invalid_timezone_name THEN
      RAISE e_invalid_timezone_name;
  END validate_profile_data;

  PROCEDURE assert_profile_exists(
    p_profile_id IN BEX_PROFILE.PFL_ID%TYPE
  ) IS
  BEGIN
    IF p_profile_id IS NULL THEN
      RAISE e_profile_not_found;
    END IF;
  END assert_profile_exists;

  ------------------------------------------------------------------------------
  -- Casos de uso
  ------------------------------------------------------------------------------

  FUNCTION create_profile(
    p_account_id     IN BEX_PROFILE.ACC_ID%TYPE,
    p_display_name   IN BEX_PROFILE.PFL_DISPLAY_NAME%TYPE,
    p_full_name      IN BEX_PROFILE.PFL_FULL_NAME%TYPE,
    p_birth_date     IN BEX_PROFILE.PFL_BIRTH_DATE%TYPE,
    p_bio            IN BEX_PROFILE.PFL_BIO%TYPE,
    p_avatar_url     IN BEX_PROFILE.PFL_AVATAR_URL%TYPE,
    p_locale_code    IN BEX_PROFILE.PFL_LOCALE_CODE%TYPE,
    p_timezone_name  IN BEX_PROFILE.PFL_TIMEZONE_NAME%TYPE,
    p_audit_actor_id IN BEX_PROFILE.PFL_CREATED_BY%TYPE
  ) RETURN BEX_PROFILE%ROWTYPE IS
    l_display_name BEX_PROFILE.PFL_DISPLAY_NAME%TYPE;
    l_full_name    BEX_PROFILE.PFL_FULL_NAME%TYPE;
    l_public_id    BEX_PROFILE.PFL_PUBLIC_ID%TYPE;
    l_profile_id   BEX_PROFILE.PFL_ID%TYPE;
    l_profile      BEX_PROFILE%ROWTYPE;
  BEGIN
    l_display_name := pfl_rule_pkg.normalize_display_name(p_display_name);
    l_full_name := pfl_rule_pkg.normalize_full_name(p_full_name);

    validate_profile_data(
      l_display_name,
      l_full_name,
      p_birth_date,
      p_locale_code,
      p_timezone_name
    );

    IF pfl_repository_pkg.account_has_profile(p_account_id) THEN
      RAISE e_account_already_has_profile;
    END IF;

    l_public_id := generate_public_id;

    pfl_repository_pkg.insert_profile(
      p_account_id    => p_account_id,
      p_public_id     => l_public_id,
      p_display_name  => l_display_name,
      p_full_name     => l_full_name,
      p_birth_date    => p_birth_date,
      p_bio           => p_bio,
      p_avatar_url    => p_avatar_url,
      p_locale_code   => p_locale_code,
      p_timezone_name => p_timezone_name,
      p_created_by    => p_audit_actor_id,
      p_updated_by    => p_audit_actor_id,
      o_profile_id    => l_profile_id
    );

    l_profile := pfl_repository_pkg.get_by_id(l_profile_id);
    assert_profile_exists(l_profile.PFL_ID);

    RETURN l_profile;
  END create_profile;

  FUNCTION create_by_account_public_id(
    p_account_public_id IN BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE,
    p_display_name      IN BEX_PROFILE.PFL_DISPLAY_NAME%TYPE,
    p_full_name         IN BEX_PROFILE.PFL_FULL_NAME%TYPE,
    p_birth_date        IN BEX_PROFILE.PFL_BIRTH_DATE%TYPE,
    p_bio               IN BEX_PROFILE.PFL_BIO%TYPE,
    p_avatar_url        IN BEX_PROFILE.PFL_AVATAR_URL%TYPE,
    p_locale_code       IN BEX_PROFILE.PFL_LOCALE_CODE%TYPE,
    p_timezone_name     IN BEX_PROFILE.PFL_TIMEZONE_NAME%TYPE,
    p_audit_actor_id    IN BEX_PROFILE.PFL_CREATED_BY%TYPE
  ) RETURN BEX_PROFILE%ROWTYPE IS
    l_account_id BEX_ACCOUNT.ACC_ID%TYPE;
  BEGIN
    l_account_id := resolve_account_id(p_account_public_id);

    RETURN create_profile(
      p_account_id     => l_account_id,
      p_display_name   => p_display_name,
      p_full_name      => p_full_name,
      p_birth_date     => p_birth_date,
      p_bio            => p_bio,
      p_avatar_url     => p_avatar_url,
      p_locale_code    => p_locale_code,
      p_timezone_name  => p_timezone_name,
      p_audit_actor_id => p_audit_actor_id
    );
  END create_by_account_public_id;

  FUNCTION update_profile(
    p_profile_id     IN BEX_PROFILE.PFL_ID%TYPE,
    p_display_name   IN BEX_PROFILE.PFL_DISPLAY_NAME%TYPE,
    p_full_name      IN BEX_PROFILE.PFL_FULL_NAME%TYPE,
    p_birth_date     IN BEX_PROFILE.PFL_BIRTH_DATE%TYPE,
    p_bio            IN BEX_PROFILE.PFL_BIO%TYPE,
    p_avatar_url     IN BEX_PROFILE.PFL_AVATAR_URL%TYPE,
    p_locale_code    IN BEX_PROFILE.PFL_LOCALE_CODE%TYPE,
    p_timezone_name  IN BEX_PROFILE.PFL_TIMEZONE_NAME%TYPE,
    p_audit_actor_id IN BEX_PROFILE.PFL_UPDATED_BY%TYPE
  ) RETURN BEX_PROFILE%ROWTYPE IS
    l_display_name BEX_PROFILE.PFL_DISPLAY_NAME%TYPE;
    l_full_name    BEX_PROFILE.PFL_FULL_NAME%TYPE;
    l_profile      BEX_PROFILE%ROWTYPE;
    l_updated      BOOLEAN;
  BEGIN
    l_profile := pfl_repository_pkg.get_by_id(p_profile_id);
    assert_profile_exists(l_profile.PFL_ID);

    l_display_name := pfl_rule_pkg.normalize_display_name(p_display_name);
    l_full_name := pfl_rule_pkg.normalize_full_name(p_full_name);

    validate_profile_data(
      l_display_name,
      l_full_name,
      p_birth_date,
      p_locale_code,
      p_timezone_name
    );

    pfl_repository_pkg.update_profile(
      p_profile_id    => p_profile_id,
      p_display_name  => l_display_name,
      p_full_name     => l_full_name,
      p_birth_date    => p_birth_date,
      p_bio           => p_bio,
      p_avatar_url    => p_avatar_url,
      p_locale_code   => p_locale_code,
      p_timezone_name => p_timezone_name,
      p_updated_by    => p_audit_actor_id,
      o_updated       => l_updated
    );

    IF NOT l_updated THEN
      RAISE e_profile_not_found;
    END IF;

    l_profile := pfl_repository_pkg.get_by_id(p_profile_id);
    assert_profile_exists(l_profile.PFL_ID);

    RETURN l_profile;
  END update_profile;

  FUNCTION update_by_public_id(
    p_profile_public_id IN BEX_PROFILE.PFL_PUBLIC_ID%TYPE,
    p_display_name      IN BEX_PROFILE.PFL_DISPLAY_NAME%TYPE,
    p_full_name         IN BEX_PROFILE.PFL_FULL_NAME%TYPE,
    p_birth_date        IN BEX_PROFILE.PFL_BIRTH_DATE%TYPE,
    p_bio               IN BEX_PROFILE.PFL_BIO%TYPE,
    p_avatar_url        IN BEX_PROFILE.PFL_AVATAR_URL%TYPE,
    p_locale_code       IN BEX_PROFILE.PFL_LOCALE_CODE%TYPE,
    p_timezone_name     IN BEX_PROFILE.PFL_TIMEZONE_NAME%TYPE,
    p_audit_actor_id    IN BEX_PROFILE.PFL_UPDATED_BY%TYPE
  ) RETURN BEX_PROFILE%ROWTYPE IS
    l_profile BEX_PROFILE%ROWTYPE;
  BEGIN
    l_profile := get_by_public_id(p_profile_public_id);

    RETURN update_profile(
      p_profile_id     => l_profile.PFL_ID,
      p_display_name   => p_display_name,
      p_full_name      => p_full_name,
      p_birth_date     => p_birth_date,
      p_bio            => p_bio,
      p_avatar_url     => p_avatar_url,
      p_locale_code    => p_locale_code,
      p_timezone_name  => p_timezone_name,
      p_audit_actor_id => p_audit_actor_id
    );
  END update_by_public_id;

  ------------------------------------------------------------------------------
  -- Consultas
  ------------------------------------------------------------------------------

  FUNCTION get_by_id(
    p_profile_id IN BEX_PROFILE.PFL_ID%TYPE
  ) RETURN BEX_PROFILE%ROWTYPE IS
    l_profile BEX_PROFILE%ROWTYPE;
  BEGIN
    l_profile := pfl_repository_pkg.get_by_id(p_profile_id);
    assert_profile_exists(l_profile.PFL_ID);

    RETURN l_profile;
  END get_by_id;

  FUNCTION get_by_public_id(
    p_public_id IN BEX_PROFILE.PFL_PUBLIC_ID%TYPE
  ) RETURN BEX_PROFILE%ROWTYPE IS
    l_profile BEX_PROFILE%ROWTYPE;
  BEGIN
    l_profile := pfl_repository_pkg.get_by_public_id(p_public_id);
    assert_profile_exists(l_profile.PFL_ID);

    RETURN l_profile;
  END get_by_public_id;

  FUNCTION get_by_account_id(
    p_account_id IN BEX_PROFILE.ACC_ID%TYPE
  ) RETURN BEX_PROFILE%ROWTYPE IS
    l_profile BEX_PROFILE%ROWTYPE;
  BEGIN
    l_profile := pfl_repository_pkg.get_by_account_id(p_account_id);
    assert_profile_exists(l_profile.PFL_ID);

    RETURN l_profile;
  END get_by_account_id;

  FUNCTION get_by_account_public_id(
    p_account_public_id IN BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE
  ) RETURN BEX_PROFILE%ROWTYPE IS
    l_account_id BEX_ACCOUNT.ACC_ID%TYPE;
  BEGIN
    l_account_id := resolve_account_id(p_account_public_id);

    RETURN get_by_account_id(l_account_id);
  END get_by_account_public_id;
END pfl_service_pkg;
/
