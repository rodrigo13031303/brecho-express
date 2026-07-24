CREATE OR REPLACE PACKAGE cat_service_pkg AS
  TYPE t_category_record IS RECORD (
    category_public_id BEX_CATEGORY.CAT_PUBLIC_ID%TYPE,
    category_name      BEX_CATEGORY.CAT_NAME%TYPE,
    category_slug      BEX_CATEGORY.CAT_SLUG%TYPE,
    description        BEX_CATEGORY.CAT_DESCRIPTION%TYPE,
    status             BEX_CATEGORY.CAT_STATUS%TYPE,
    created_at         BEX_CATEGORY.CAT_CREATED_AT%TYPE,
    updated_at         BEX_CATEGORY.CAT_UPDATED_AT%TYPE
  );

  TYPE t_category_table IS TABLE OF t_category_record
    INDEX BY PLS_INTEGER;

  e_category_not_found EXCEPTION;
  e_category_inactive  EXCEPTION;
  e_invalid_status     EXCEPTION;

  PRAGMA EXCEPTION_INIT(e_category_not_found, -20760);
  PRAGMA EXCEPTION_INIT(e_category_inactive, -20761);
  PRAGMA EXCEPTION_INIT(e_invalid_status, -20762);

  FUNCTION get_by_public_id(
    p_public_id IN BEX_CATEGORY.CAT_PUBLIC_ID%TYPE
  ) RETURN t_category_record;

  FUNCTION require_by_public_id(
    p_public_id IN BEX_CATEGORY.CAT_PUBLIC_ID%TYPE
  ) RETURN t_category_record;

  FUNCTION get_by_slug(
    p_slug IN BEX_CATEGORY.CAT_SLUG%TYPE
  ) RETURN t_category_record;

  FUNCTION require_by_slug(
    p_slug IN BEX_CATEGORY.CAT_SLUG%TYPE
  ) RETURN t_category_record;

  FUNCTION list_categories(
    p_status IN BEX_CATEGORY.CAT_STATUS%TYPE DEFAULT NULL
  ) RETURN t_category_table;

  -- Fronteira interna para Services consumidores. Resolve somente CATEGORY
  -- ACTIVE e nunca constitui identificador exposto pela API.
  FUNCTION resolve_active_category_id(
    p_public_id IN BEX_CATEGORY.CAT_PUBLIC_ID%TYPE
  ) RETURN BEX_CATEGORY.CAT_ID%TYPE;

  FUNCTION resolve_category_public_id(
    p_category_id IN BEX_CATEGORY.CAT_ID%TYPE
  ) RETURN BEX_CATEGORY.CAT_PUBLIC_ID%TYPE;
END cat_service_pkg;
/
