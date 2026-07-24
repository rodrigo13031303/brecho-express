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

  TYPE t_member_record IS RECORD (
    store_user_public_id BEX_STORE_USER.STU_PUBLIC_ID%TYPE,
    store_public_id      BEX_STORE.STR_PUBLIC_ID%TYPE,
    account_public_id    BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE,
    role_code            BEX_STORE_USER.STU_ROLE_CODE%TYPE,
    status               BEX_STORE_USER.STU_STATUS%TYPE,
    joined_at            BEX_STORE_USER.STU_JOINED_AT%TYPE,
    left_at              BEX_STORE_USER.STU_LEFT_AT%TYPE,
    created_at           BEX_STORE_USER.STU_CREATED_AT%TYPE,
    updated_at           BEX_STORE_USER.STU_UPDATED_AT%TYPE
  );

  TYPE t_member_table IS TABLE OF t_member_record INDEX BY PLS_INTEGER;

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
  e_account_not_found EXCEPTION;
  e_name_required EXCEPTION;
  e_invalid_name EXCEPTION;
  e_slug_required EXCEPTION;
  e_invalid_slug EXCEPTION;
  e_invalid_description EXCEPTION;
  e_invalid_logo_url EXCEPTION;
  e_invalid_cover_url EXCEPTION;
  e_invalid_locale EXCEPTION;
  e_invalid_timezone EXCEPTION;
  e_invalid_status EXCEPTION;
  e_invalid_transition EXCEPTION;
  e_empty_patch EXCEPTION;
  e_slug_not_editable EXCEPTION;
  e_store_closed EXCEPTION;
  e_account_ineligible EXCEPTION;
  e_slug_already_used EXCEPTION;
  e_member_not_found EXCEPTION;
  e_member_invalid_role EXCEPTION;
  e_member_invalid_status EXCEPTION;
  e_member_invalid_transition EXCEPTION;
  e_active_member_link_exists EXCEPTION;
  e_member_forbidden EXCEPTION;
  e_last_admin_required EXCEPTION;
  e_catalog_forbidden EXCEPTION;

  PRAGMA EXCEPTION_INIT(e_store_not_found, -20860);
  PRAGMA EXCEPTION_INIT(e_account_not_found, -20840);
  PRAGMA EXCEPTION_INIT(e_name_required, -20861);
  PRAGMA EXCEPTION_INIT(e_invalid_name, -20862);
  PRAGMA EXCEPTION_INIT(e_slug_required, -20863);
  PRAGMA EXCEPTION_INIT(e_invalid_slug, -20864);
  PRAGMA EXCEPTION_INIT(e_invalid_description, -20865);
  PRAGMA EXCEPTION_INIT(e_invalid_logo_url, -20866);
  PRAGMA EXCEPTION_INIT(e_invalid_cover_url, -20867);
  PRAGMA EXCEPTION_INIT(e_invalid_locale, -20868);
  PRAGMA EXCEPTION_INIT(e_invalid_timezone, -20869);
  PRAGMA EXCEPTION_INIT(e_invalid_status, -20870);
  PRAGMA EXCEPTION_INIT(e_invalid_transition, -20871);
  PRAGMA EXCEPTION_INIT(e_empty_patch, -20872);
  PRAGMA EXCEPTION_INIT(e_slug_not_editable, -20873);
  PRAGMA EXCEPTION_INIT(e_store_closed, -20874);
  PRAGMA EXCEPTION_INIT(e_account_ineligible, -20875);
  PRAGMA EXCEPTION_INIT(e_slug_already_used, -20876);
  PRAGMA EXCEPTION_INIT(e_member_not_found, -20886);
  PRAGMA EXCEPTION_INIT(e_member_invalid_role, -20887);
  PRAGMA EXCEPTION_INIT(e_member_invalid_status, -20888);
  PRAGMA EXCEPTION_INIT(e_member_invalid_transition, -20889);
  PRAGMA EXCEPTION_INIT(e_active_member_link_exists, -20890);
  PRAGMA EXCEPTION_INIT(e_member_forbidden, -20891);
  PRAGMA EXCEPTION_INIT(e_last_admin_required, -20892);
  PRAGMA EXCEPTION_INIT(e_catalog_forbidden, -20893);

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

  -- Resolucao interna por identificador tecnico para orquestracao entre
  -- Services. Nao constitui fronteira externa.
  FUNCTION get_store_by_id(
    p_store_id IN BEX_STORE.STR_ID%TYPE
  ) RETURN t_store_record;

  -- Resolucao interna do identificador tecnico para orquestracao entre
  -- Services. Nao constitui fronteira externa.
  FUNCTION resolve_store_id(
    p_store_public_id IN BEX_STORE.STR_PUBLIC_ID%TYPE
  ) RETURN BEX_STORE.STR_ID%TYPE;

  -- Autoriza um Service consumidor a administrar o catalogo da STORE e
  -- devolve somente a identidade tecnica necessaria para a foreign key.
  FUNCTION resolve_catalog_store_id(
    p_store_public_id IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_actor_id        IN BEX_ACCOUNT.ACC_ID%TYPE
  ) RETURN BEX_STORE.STR_ID%TYPE;

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

  FUNCTION add_member(
    p_store_public_id   IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_account_public_id IN BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE,
    p_role_code         IN BEX_STORE_USER.STU_ROLE_CODE%TYPE,
    p_actor_id          IN BEX_ACCOUNT.ACC_ID%TYPE
  ) RETURN t_member_record;

  FUNCTION get_member(
    p_store_public_id      IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_store_user_public_id IN BEX_STORE_USER.STU_PUBLIC_ID%TYPE,
    p_actor_id             IN BEX_ACCOUNT.ACC_ID%TYPE
  ) RETURN t_member_record;

  FUNCTION list_members(
    p_store_public_id IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_actor_id        IN BEX_ACCOUNT.ACC_ID%TYPE,
    p_status          IN BEX_STORE_USER.STU_STATUS%TYPE DEFAULT NULL,
    p_role_code       IN BEX_STORE_USER.STU_ROLE_CODE%TYPE DEFAULT NULL
  ) RETURN t_member_table;

  FUNCTION change_member_role(
    p_store_public_id      IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_store_user_public_id IN BEX_STORE_USER.STU_PUBLIC_ID%TYPE,
    p_role_code            IN BEX_STORE_USER.STU_ROLE_CODE%TYPE,
    p_actor_id             IN BEX_ACCOUNT.ACC_ID%TYPE
  ) RETURN t_member_record;

  FUNCTION activate_member(
    p_store_public_id      IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_store_user_public_id IN BEX_STORE_USER.STU_PUBLIC_ID%TYPE,
    p_actor_id             IN BEX_ACCOUNT.ACC_ID%TYPE
  ) RETURN t_member_record;

  FUNCTION deactivate_member(
    p_store_public_id      IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_store_user_public_id IN BEX_STORE_USER.STU_PUBLIC_ID%TYPE,
    p_actor_id             IN BEX_ACCOUNT.ACC_ID%TYPE
  ) RETURN t_member_record;
END str_service_pkg;
/
