CREATE OR REPLACE PACKAGE BODY pfl_repository_pkg AS
  ------------------------------------------------------------------------------
  -- Insercao
  ------------------------------------------------------------------------------

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
  ) IS
  BEGIN
    INSERT INTO BEX_PROFILE
    (
      ACC_ID,
      PFL_PUBLIC_ID,
      PFL_DISPLAY_NAME,
      PFL_FULL_NAME,
      PFL_BIRTH_DATE,
      PFL_BIO,
      PFL_AVATAR_URL,
      PFL_LOCALE_CODE,
      PFL_TIMEZONE_NAME,
      PFL_CREATED_BY,
      PFL_UPDATED_BY
    )
    VALUES
    (
      p_account_id,
      p_public_id,
      p_display_name,
      p_full_name,
      p_birth_date,
      p_bio,
      p_avatar_url,
      p_locale_code,
      p_timezone_name,
      p_created_by,
      p_updated_by
    )
    RETURNING PFL_ID INTO o_profile_id;
  END insert_profile;

  ------------------------------------------------------------------------------
  -- Atualizacao
  ------------------------------------------------------------------------------

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
  ) IS
  BEGIN
    UPDATE BEX_PROFILE
       SET PFL_DISPLAY_NAME = p_display_name,
           PFL_FULL_NAME = p_full_name,
           PFL_BIRTH_DATE = p_birth_date,
           PFL_BIO = p_bio,
           PFL_AVATAR_URL = p_avatar_url,
           PFL_LOCALE_CODE = p_locale_code,
           PFL_TIMEZONE_NAME = p_timezone_name,
           PFL_UPDATED_AT = SYSTIMESTAMP,
           PFL_UPDATED_BY = p_updated_by
     WHERE PFL_ID = p_profile_id;

    o_updated := SQL%ROWCOUNT = 1;
  END update_profile;

  ------------------------------------------------------------------------------
  -- Consultas
  ------------------------------------------------------------------------------

  FUNCTION get_by_id(
    p_profile_id IN BEX_PROFILE.PFL_ID%TYPE
  ) RETURN BEX_PROFILE%ROWTYPE IS
    l_profile BEX_PROFILE%ROWTYPE;
  BEGIN
    SELECT p.PFL_ID,
           p.ACC_ID,
           p.PFL_PUBLIC_ID,
           p.PFL_DISPLAY_NAME,
           p.PFL_FULL_NAME,
           p.PFL_BIRTH_DATE,
           p.PFL_BIO,
           p.PFL_AVATAR_URL,
           p.PFL_LOCALE_CODE,
           p.PFL_TIMEZONE_NAME,
           p.PFL_CREATED_AT,
           p.PFL_UPDATED_AT,
           p.PFL_CREATED_BY,
           p.PFL_UPDATED_BY
      INTO l_profile
      FROM BEX_PROFILE p
     WHERE p.PFL_ID = p_profile_id;

    RETURN l_profile;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN l_profile;
  END get_by_id;

  FUNCTION get_by_public_id(
    p_public_id IN BEX_PROFILE.PFL_PUBLIC_ID%TYPE
  ) RETURN BEX_PROFILE%ROWTYPE IS
    l_profile BEX_PROFILE%ROWTYPE;
  BEGIN
    SELECT p.PFL_ID,
           p.ACC_ID,
           p.PFL_PUBLIC_ID,
           p.PFL_DISPLAY_NAME,
           p.PFL_FULL_NAME,
           p.PFL_BIRTH_DATE,
           p.PFL_BIO,
           p.PFL_AVATAR_URL,
           p.PFL_LOCALE_CODE,
           p.PFL_TIMEZONE_NAME,
           p.PFL_CREATED_AT,
           p.PFL_UPDATED_AT,
           p.PFL_CREATED_BY,
           p.PFL_UPDATED_BY
      INTO l_profile
      FROM BEX_PROFILE p
     WHERE p.PFL_PUBLIC_ID = p_public_id;

    RETURN l_profile;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN l_profile;
  END get_by_public_id;

  FUNCTION get_by_account_id(
    p_account_id IN BEX_PROFILE.ACC_ID%TYPE
  ) RETURN BEX_PROFILE%ROWTYPE IS
    l_profile BEX_PROFILE%ROWTYPE;
  BEGIN
    SELECT p.PFL_ID,
           p.ACC_ID,
           p.PFL_PUBLIC_ID,
           p.PFL_DISPLAY_NAME,
           p.PFL_FULL_NAME,
           p.PFL_BIRTH_DATE,
           p.PFL_BIO,
           p.PFL_AVATAR_URL,
           p.PFL_LOCALE_CODE,
           p.PFL_TIMEZONE_NAME,
           p.PFL_CREATED_AT,
           p.PFL_UPDATED_AT,
           p.PFL_CREATED_BY,
           p.PFL_UPDATED_BY
      INTO l_profile
      FROM BEX_PROFILE p
     WHERE p.ACC_ID = p_account_id;

    RETURN l_profile;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN l_profile;
  END get_by_account_id;

  FUNCTION profile_exists(
    p_profile_id IN BEX_PROFILE.PFL_ID%TYPE
  ) RETURN BOOLEAN IS
    l_exists PLS_INTEGER;
  BEGIN
    SELECT 1
      INTO l_exists
      FROM BEX_PROFILE p
     WHERE p.PFL_ID = p_profile_id;

    RETURN TRUE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN FALSE;
  END profile_exists;

  FUNCTION public_id_exists(
    p_public_id IN BEX_PROFILE.PFL_PUBLIC_ID%TYPE
  ) RETURN BOOLEAN IS
    l_exists PLS_INTEGER;
  BEGIN
    SELECT 1
      INTO l_exists
      FROM BEX_PROFILE p
     WHERE p.PFL_PUBLIC_ID = p_public_id;

    RETURN TRUE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN FALSE;
  END public_id_exists;

  FUNCTION account_has_profile(
    p_account_id IN BEX_PROFILE.ACC_ID%TYPE
  ) RETURN BOOLEAN IS
    l_exists PLS_INTEGER;
  BEGIN
    SELECT 1
      INTO l_exists
      FROM BEX_PROFILE p
     WHERE p.ACC_ID = p_account_id;

    RETURN TRUE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN FALSE;
  END account_has_profile;
END pfl_repository_pkg;
/
