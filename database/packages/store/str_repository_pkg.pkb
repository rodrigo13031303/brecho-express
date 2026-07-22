CREATE OR REPLACE PACKAGE BODY str_repository_pkg AS
  ------------------------------------------------------------------------------
  -- Insercao
  ------------------------------------------------------------------------------

  PROCEDURE insert_store(
    p_public_id     IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_account_id    IN BEX_STORE.ACC_ID%TYPE,
    p_name          IN BEX_STORE.STR_NAME%TYPE,
    p_slug          IN BEX_STORE.STR_SLUG%TYPE,
    p_description   IN BEX_STORE.STR_DESCRIPTION%TYPE,
    p_status        IN BEX_STORE.STR_STATUS%TYPE,
    p_logo_url      IN BEX_STORE.STR_LOGO_URL%TYPE,
    p_cover_url     IN BEX_STORE.STR_COVER_URL%TYPE,
    p_locale_code   IN BEX_STORE.STR_LOCALE_CODE%TYPE,
    p_timezone_name IN BEX_STORE.STR_TIMEZONE_NAME%TYPE,
    p_created_by    IN BEX_STORE.STR_CREATED_BY%TYPE,
    p_updated_by    IN BEX_STORE.STR_UPDATED_BY%TYPE,
    o_store_id      OUT BEX_STORE.STR_ID%TYPE
  ) IS
  BEGIN
    INSERT INTO BEX_STORE
    (
      STR_PUBLIC_ID,
      ACC_ID,
      STR_NAME,
      STR_SLUG,
      STR_DESCRIPTION,
      STR_STATUS,
      STR_LOGO_URL,
      STR_COVER_URL,
      STR_LOCALE_CODE,
      STR_TIMEZONE_NAME,
      STR_CREATED_BY,
      STR_UPDATED_BY
    )
    VALUES
    (
      p_public_id,
      p_account_id,
      p_name,
      p_slug,
      p_description,
      p_status,
      p_logo_url,
      p_cover_url,
      p_locale_code,
      p_timezone_name,
      p_created_by,
      p_updated_by
    )
    RETURNING STR_ID INTO o_store_id;
  END insert_store;

  ------------------------------------------------------------------------------
  -- Atualizacoes
  ------------------------------------------------------------------------------

  PROCEDURE update_store(
    p_store_id          IN BEX_STORE.STR_ID%TYPE,
    p_set_name          IN BOOLEAN,
    p_name              IN BEX_STORE.STR_NAME%TYPE,
    p_set_slug          IN BOOLEAN,
    p_slug              IN BEX_STORE.STR_SLUG%TYPE,
    p_set_description   IN BOOLEAN,
    p_description       IN BEX_STORE.STR_DESCRIPTION%TYPE,
    p_set_logo_url      IN BOOLEAN,
    p_logo_url          IN BEX_STORE.STR_LOGO_URL%TYPE,
    p_set_cover_url     IN BOOLEAN,
    p_cover_url         IN BEX_STORE.STR_COVER_URL%TYPE,
    p_set_locale_code   IN BOOLEAN,
    p_locale_code       IN BEX_STORE.STR_LOCALE_CODE%TYPE,
    p_set_timezone_name IN BOOLEAN,
    p_timezone_name     IN BEX_STORE.STR_TIMEZONE_NAME%TYPE,
    p_updated_at        IN BEX_STORE.STR_UPDATED_AT%TYPE,
    p_updated_by        IN BEX_STORE.STR_UPDATED_BY%TYPE,
    o_updated           OUT BOOLEAN
  ) IS
    l_set_name          PLS_INTEGER := CASE WHEN p_set_name THEN 1 ELSE 0 END;
    l_set_slug          PLS_INTEGER := CASE WHEN p_set_slug THEN 1 ELSE 0 END;
    l_set_description   PLS_INTEGER := CASE WHEN p_set_description THEN 1 ELSE 0 END;
    l_set_logo_url      PLS_INTEGER := CASE WHEN p_set_logo_url THEN 1 ELSE 0 END;
    l_set_cover_url     PLS_INTEGER := CASE WHEN p_set_cover_url THEN 1 ELSE 0 END;
    l_set_locale_code   PLS_INTEGER := CASE WHEN p_set_locale_code THEN 1 ELSE 0 END;
    l_set_timezone_name PLS_INTEGER := CASE WHEN p_set_timezone_name THEN 1 ELSE 0 END;
  BEGIN
    UPDATE BEX_STORE
       SET STR_NAME = CASE WHEN l_set_name = 1 THEN p_name ELSE STR_NAME END,
           STR_SLUG = CASE WHEN l_set_slug = 1 THEN p_slug ELSE STR_SLUG END,
           STR_DESCRIPTION = CASE
             WHEN l_set_description = 1 THEN p_description
             ELSE STR_DESCRIPTION
           END,
           STR_LOGO_URL = CASE
             WHEN l_set_logo_url = 1 THEN p_logo_url
             ELSE STR_LOGO_URL
           END,
           STR_COVER_URL = CASE
             WHEN l_set_cover_url = 1 THEN p_cover_url
             ELSE STR_COVER_URL
           END,
           STR_LOCALE_CODE = CASE
             WHEN l_set_locale_code = 1 THEN p_locale_code
             ELSE STR_LOCALE_CODE
           END,
           STR_TIMEZONE_NAME = CASE
             WHEN l_set_timezone_name = 1 THEN p_timezone_name
             ELSE STR_TIMEZONE_NAME
           END,
           STR_UPDATED_AT = p_updated_at,
           STR_UPDATED_BY = p_updated_by
     WHERE STR_ID = p_store_id;

    o_updated := SQL%ROWCOUNT = 1;
  END update_store;

  PROCEDURE update_status(
    p_store_id   IN BEX_STORE.STR_ID%TYPE,
    p_status     IN BEX_STORE.STR_STATUS%TYPE,
    p_updated_at IN BEX_STORE.STR_UPDATED_AT%TYPE,
    p_updated_by IN BEX_STORE.STR_UPDATED_BY%TYPE,
    o_updated    OUT BOOLEAN
  ) IS
  BEGIN
    UPDATE BEX_STORE
       SET STR_STATUS = p_status,
           STR_UPDATED_AT = p_updated_at,
           STR_UPDATED_BY = p_updated_by
     WHERE STR_ID = p_store_id;

    o_updated := SQL%ROWCOUNT = 1;
  END update_status;

  ------------------------------------------------------------------------------
  -- Consultas
  ------------------------------------------------------------------------------

  FUNCTION get_by_public_id(
    p_public_id IN BEX_STORE.STR_PUBLIC_ID%TYPE
  ) RETURN t_store_record IS
    l_store t_store_record;
  BEGIN
    SELECT s.STR_ID,
           s.STR_PUBLIC_ID,
           s.ACC_ID,
           s.STR_NAME,
           s.STR_SLUG,
           s.STR_DESCRIPTION,
           s.STR_STATUS,
           s.STR_LOGO_URL,
           s.STR_COVER_URL,
           s.STR_LOCALE_CODE,
           s.STR_TIMEZONE_NAME,
           s.STR_CREATED_AT,
           s.STR_CREATED_BY,
           s.STR_UPDATED_AT,
           s.STR_UPDATED_BY
      INTO l_store
      FROM BEX_STORE s
     WHERE s.STR_PUBLIC_ID = p_public_id;

    RETURN l_store;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN l_store;
  END get_by_public_id;

  FUNCTION get_by_slug(
    p_slug IN BEX_STORE.STR_SLUG%TYPE
  ) RETURN t_store_record IS
    l_store t_store_record;
  BEGIN
    SELECT s.STR_ID,
           s.STR_PUBLIC_ID,
           s.ACC_ID,
           s.STR_NAME,
           s.STR_SLUG,
           s.STR_DESCRIPTION,
           s.STR_STATUS,
           s.STR_LOGO_URL,
           s.STR_COVER_URL,
           s.STR_LOCALE_CODE,
           s.STR_TIMEZONE_NAME,
           s.STR_CREATED_AT,
           s.STR_CREATED_BY,
           s.STR_UPDATED_AT,
           s.STR_UPDATED_BY
      INTO l_store
      FROM BEX_STORE s
     WHERE s.STR_SLUG = p_slug;

    RETURN l_store;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN l_store;
  END get_by_slug;

  FUNCTION public_id_exists(
    p_public_id IN BEX_STORE.STR_PUBLIC_ID%TYPE
  ) RETURN BOOLEAN IS
    l_exists PLS_INTEGER;
  BEGIN
    SELECT 1
      INTO l_exists
      FROM BEX_STORE s
     WHERE s.STR_PUBLIC_ID = p_public_id;

    RETURN TRUE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN FALSE;
  END public_id_exists;

  FUNCTION slug_exists(
    p_slug IN BEX_STORE.STR_SLUG%TYPE
  ) RETURN BOOLEAN IS
    l_exists PLS_INTEGER;
  BEGIN
    SELECT 1
      INTO l_exists
      FROM BEX_STORE s
     WHERE s.STR_SLUG = p_slug;

    RETURN TRUE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN FALSE;
  END slug_exists;

  FUNCTION list_by_account(
    p_account_id IN BEX_STORE.ACC_ID%TYPE
  ) RETURN t_store_table IS
    l_stores t_store_table;
  BEGIN
    SELECT s.STR_ID,
           s.STR_PUBLIC_ID,
           s.ACC_ID,
           s.STR_NAME,
           s.STR_SLUG,
           s.STR_DESCRIPTION,
           s.STR_STATUS,
           s.STR_LOGO_URL,
           s.STR_COVER_URL,
           s.STR_LOCALE_CODE,
           s.STR_TIMEZONE_NAME,
           s.STR_CREATED_AT,
           s.STR_CREATED_BY,
           s.STR_UPDATED_AT,
           s.STR_UPDATED_BY
      BULK COLLECT INTO l_stores
      FROM BEX_STORE s
     WHERE s.ACC_ID = p_account_id
     ORDER BY s.STR_CREATED_AT DESC,
              s.STR_ID DESC;

    RETURN l_stores;
  END list_by_account;
END str_repository_pkg;
/
