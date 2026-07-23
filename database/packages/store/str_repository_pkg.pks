CREATE OR REPLACE PACKAGE str_repository_pkg AS
  -- Camada de persistencia da entidade STORE.
  -- Recebe valores preparados e executa somente SQL sobre BEX_STORE.

  TYPE t_store_record IS RECORD (
    str_id            BEX_STORE.STR_ID%TYPE,
    str_public_id     BEX_STORE.STR_PUBLIC_ID%TYPE,
    acc_id            BEX_STORE.ACC_ID%TYPE,
    str_name          BEX_STORE.STR_NAME%TYPE,
    str_slug          BEX_STORE.STR_SLUG%TYPE,
    str_description   BEX_STORE.STR_DESCRIPTION%TYPE,
    str_status        BEX_STORE.STR_STATUS%TYPE,
    str_logo_url      BEX_STORE.STR_LOGO_URL%TYPE,
    str_cover_url     BEX_STORE.STR_COVER_URL%TYPE,
    str_locale_code   BEX_STORE.STR_LOCALE_CODE%TYPE,
    str_timezone_name BEX_STORE.STR_TIMEZONE_NAME%TYPE,
    str_created_at    BEX_STORE.STR_CREATED_AT%TYPE,
    str_created_by    BEX_STORE.STR_CREATED_BY%TYPE,
    str_updated_at    BEX_STORE.STR_UPDATED_AT%TYPE,
    str_updated_by    BEX_STORE.STR_UPDATED_BY%TYPE
  );

  TYPE t_store_table IS TABLE OF t_store_record INDEX BY PLS_INTEGER;

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
  );

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
  );

  PROCEDURE update_status(
    p_store_id   IN BEX_STORE.STR_ID%TYPE,
    p_status     IN BEX_STORE.STR_STATUS%TYPE,
    p_updated_at IN BEX_STORE.STR_UPDATED_AT%TYPE,
    p_updated_by IN BEX_STORE.STR_UPDATED_BY%TYPE,
    o_updated    OUT BOOLEAN
  );

  FUNCTION get_by_public_id(
    p_public_id IN BEX_STORE.STR_PUBLIC_ID%TYPE
  ) RETURN t_store_record;

  FUNCTION get_by_id(
    p_str_id IN BEX_STORE.STR_ID%TYPE
  ) RETURN t_store_record;

  FUNCTION get_by_slug(
    p_slug IN BEX_STORE.STR_SLUG%TYPE
  ) RETURN t_store_record;

  FUNCTION public_id_exists(
    p_public_id IN BEX_STORE.STR_PUBLIC_ID%TYPE
  ) RETURN BOOLEAN;

  FUNCTION slug_exists(
    p_slug IN BEX_STORE.STR_SLUG%TYPE
  ) RETURN BOOLEAN;

  FUNCTION list_by_account(
    p_account_id IN BEX_STORE.ACC_ID%TYPE
  ) RETURN t_store_table;
END str_repository_pkg;
/
