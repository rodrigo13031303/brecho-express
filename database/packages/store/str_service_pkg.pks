CREATE OR REPLACE PACKAGE str_service_pkg AS
  -- Casos de uso publicos da entidade STORE.
  -- Coordena Rule, Repository e outros Services sem executar SQL, controlar
  -- transacoes ou conhecer JSON, HTTP, ORDS ou APEX.

  TYPE t_store_record IS RECORD (
    store_public_id BEX_STORE.STR_PUBLIC_ID%TYPE,
    store_name      BEX_STORE.STR_NAME%TYPE,
    store_slug      BEX_STORE.STR_SLUG%TYPE,
    description     BEX_STORE.STR_DESCRIPTION%TYPE,
    status          BEX_STORE.STR_STATUS%TYPE,
    logo_url        BEX_STORE.STR_LOGO_URL%TYPE,
    cover_url       BEX_STORE.STR_COVER_URL%TYPE,
    locale_code     BEX_STORE.STR_LOCALE_CODE%TYPE,
    timezone_name   BEX_STORE.STR_TIMEZONE_NAME%TYPE,
    created_at      BEX_STORE.STR_CREATED_AT%TYPE,
    updated_at      BEX_STORE.STR_UPDATED_AT%TYPE
  );

  TYPE t_store_table IS TABLE OF t_store_record INDEX BY PLS_INTEGER;

  TYPE t_store_patch IS RECORD (
    set_name          BOOLEAN := FALSE,
    name_value        BEX_STORE.STR_NAME%TYPE,
    set_slug          BOOLEAN := FALSE,
    slug_value        BEX_STORE.STR_SLUG%TYPE,
    set_description   BOOLEAN := FALSE,
    description_value BEX_STORE.STR_DESCRIPTION%TYPE,
    set_logo_url      BOOLEAN := FALSE,
    logo_url_value    BEX_STORE.STR_LOGO_URL%TYPE,
    set_cover_url     BOOLEAN := FALSE,
    cover_url_value   BEX_STORE.STR_COVER_URL%TYPE,
    set_locale_code   BOOLEAN := FALSE,
    locale_code_value BEX_STORE.STR_LOCALE_CODE%TYPE,
    set_timezone_name BOOLEAN := FALSE,
    timezone_value    BEX_STORE.STR_TIMEZONE_NAME%TYPE
  );

  e_store_not_found EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_store_not_found, -20860);

  FUNCTION create_by_account_public_id(
    p_account_public_id IN BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE,
    p_name              IN BEX_STORE.STR_NAME%TYPE,
    p_slug              IN BEX_STORE.STR_SLUG%TYPE,
    p_description       IN BEX_STORE.STR_DESCRIPTION%TYPE DEFAULT NULL,
    p_logo_url          IN BEX_STORE.STR_LOGO_URL%TYPE DEFAULT NULL,
    p_cover_url         IN BEX_STORE.STR_COVER_URL%TYPE DEFAULT NULL,
    p_locale_code       IN BEX_STORE.STR_LOCALE_CODE%TYPE DEFAULT NULL,
    p_timezone_name     IN BEX_STORE.STR_TIMEZONE_NAME%TYPE DEFAULT NULL,
    p_audit_actor_id    IN BEX_STORE.STR_CREATED_BY%TYPE DEFAULT NULL
  ) RETURN t_store_record;

  FUNCTION get_by_public_id(
    p_store_public_id IN BEX_STORE.STR_PUBLIC_ID%TYPE
  ) RETURN t_store_record;

  FUNCTION require_by_public_id(
    p_store_public_id IN BEX_STORE.STR_PUBLIC_ID%TYPE
  ) RETURN t_store_record;

  FUNCTION get_by_slug(
    p_slug IN BEX_STORE.STR_SLUG%TYPE
  ) RETURN t_store_record;

  FUNCTION require_by_slug(
    p_slug IN BEX_STORE.STR_SLUG%TYPE
  ) RETURN t_store_record;

  FUNCTION list_by_account_public_id(
    p_account_public_id IN BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE
  ) RETURN t_store_table;

  FUNCTION update_by_public_id(
    p_store_public_id IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_patch           IN t_store_patch,
    p_audit_actor_id  IN BEX_STORE.STR_UPDATED_BY%TYPE DEFAULT NULL
  ) RETURN t_store_record;

  FUNCTION activate_by_public_id(
    p_store_public_id IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_audit_actor_id  IN BEX_STORE.STR_UPDATED_BY%TYPE DEFAULT NULL
  ) RETURN t_store_record;

  FUNCTION close_by_public_id(
    p_store_public_id IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_audit_actor_id  IN BEX_STORE.STR_UPDATED_BY%TYPE DEFAULT NULL
  ) RETURN t_store_record;

  FUNCTION slug_available(
    p_slug IN BEX_STORE.STR_SLUG%TYPE
  ) RETURN BOOLEAN;
END str_service_pkg;
/
