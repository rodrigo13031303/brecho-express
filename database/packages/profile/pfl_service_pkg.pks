CREATE OR REPLACE PACKAGE pfl_service_pkg AS
  -- Casos de uso da entidade PROFILE.
  -- Coordena regras e persistencia sem executar SQL ou controlar transacoes.

  e_profile_not_found           EXCEPTION;
  e_account_already_has_profile EXCEPTION;
  e_account_not_found           EXCEPTION;
  e_invalid_display_name        EXCEPTION;
  e_invalid_full_name           EXCEPTION;
  e_invalid_birth_date          EXCEPTION;
  e_invalid_locale_code         EXCEPTION;
  e_invalid_timezone_name       EXCEPTION;

  PRAGMA EXCEPTION_INIT(e_profile_not_found, -20700);
  PRAGMA EXCEPTION_INIT(e_account_already_has_profile, -20701);
  PRAGMA EXCEPTION_INIT(e_invalid_display_name, -20702);
  PRAGMA EXCEPTION_INIT(e_invalid_full_name, -20703);
  PRAGMA EXCEPTION_INIT(e_invalid_birth_date, -20704);
  PRAGMA EXCEPTION_INIT(e_invalid_locale_code, -20705);
  PRAGMA EXCEPTION_INIT(e_invalid_timezone_name, -20706);
  PRAGMA EXCEPTION_INIT(e_account_not_found, -20840);

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
  ) RETURN BEX_PROFILE%ROWTYPE;

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
  ) RETURN BEX_PROFILE%ROWTYPE;

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
  ) RETURN BEX_PROFILE%ROWTYPE;

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
  ) RETURN BEX_PROFILE%ROWTYPE;

  FUNCTION get_by_id(
    p_profile_id IN BEX_PROFILE.PFL_ID%TYPE
  ) RETURN BEX_PROFILE%ROWTYPE;

  FUNCTION get_by_public_id(
    p_public_id IN BEX_PROFILE.PFL_PUBLIC_ID%TYPE
  ) RETURN BEX_PROFILE%ROWTYPE;

  FUNCTION get_by_account_id(
    p_account_id IN BEX_PROFILE.ACC_ID%TYPE
  ) RETURN BEX_PROFILE%ROWTYPE;

  FUNCTION get_by_account_public_id(
    p_account_public_id IN BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE
  ) RETURN BEX_PROFILE%ROWTYPE;
END pfl_service_pkg;
/
