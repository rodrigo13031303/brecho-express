CREATE OR REPLACE PACKAGE pfl_repository_pkg AS
  -- Camada de persistencia da entidade PROFILE.
  -- Recebe valores preparados e executa somente SQL sobre BEX_PROFILE.

  PROCEDURE insert_profile(
    p_account_id    IN BEX_PROFILE.ACC_ID%TYPE,
    p_public_id     IN BEX_PROFILE.PFL_PUBLIC_ID%TYPE,
    p_display_name  IN BEX_PROFILE.PFL_DISPLAY_NAME%TYPE,
    p_full_name     IN BEX_PROFILE.PFL_FULL_NAME%TYPE,
    p_birth_date    IN BEX_PROFILE.PFL_BIRTH_DATE%TYPE,
    p_bio           IN BEX_PROFILE.PFL_BIO%TYPE,
    p_avatar_url    IN BEX_PROFILE.PFL_AVATAR_URL%TYPE,
    p_locale_code   IN BEX_PROFILE.PFL_LOCALE_CODE%TYPE,
    p_timezone_name IN BEX_PROFILE.PFL_TIMEZONE_NAME%TYPE,
    p_created_by    IN BEX_PROFILE.PFL_CREATED_BY%TYPE,
    p_updated_by    IN BEX_PROFILE.PFL_UPDATED_BY%TYPE,
    o_profile_id    OUT BEX_PROFILE.PFL_ID%TYPE
  );

  PROCEDURE update_profile(
    p_profile_id    IN BEX_PROFILE.PFL_ID%TYPE,
    p_display_name  IN BEX_PROFILE.PFL_DISPLAY_NAME%TYPE,
    p_full_name     IN BEX_PROFILE.PFL_FULL_NAME%TYPE,
    p_birth_date    IN BEX_PROFILE.PFL_BIRTH_DATE%TYPE,
    p_bio           IN BEX_PROFILE.PFL_BIO%TYPE,
    p_avatar_url    IN BEX_PROFILE.PFL_AVATAR_URL%TYPE,
    p_locale_code   IN BEX_PROFILE.PFL_LOCALE_CODE%TYPE,
    p_timezone_name IN BEX_PROFILE.PFL_TIMEZONE_NAME%TYPE,
    p_updated_by    IN BEX_PROFILE.PFL_UPDATED_BY%TYPE,
    o_updated       OUT BOOLEAN
  );

  FUNCTION get_by_id(
    p_profile_id IN BEX_PROFILE.PFL_ID%TYPE
  ) RETURN BEX_PROFILE%ROWTYPE;

  FUNCTION get_by_public_id(
    p_public_id IN BEX_PROFILE.PFL_PUBLIC_ID%TYPE
  ) RETURN BEX_PROFILE%ROWTYPE;

  FUNCTION get_by_account_id(
    p_account_id IN BEX_PROFILE.ACC_ID%TYPE
  ) RETURN BEX_PROFILE%ROWTYPE;

  FUNCTION profile_exists(
    p_profile_id IN BEX_PROFILE.PFL_ID%TYPE
  ) RETURN BOOLEAN;

  FUNCTION public_id_exists(
    p_public_id IN BEX_PROFILE.PFL_PUBLIC_ID%TYPE
  ) RETURN BOOLEAN;

  FUNCTION account_has_profile(
    p_account_id IN BEX_PROFILE.ACC_ID%TYPE
  ) RETURN BOOLEAN;
END pfl_repository_pkg;
/
