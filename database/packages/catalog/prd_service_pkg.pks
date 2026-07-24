CREATE OR REPLACE PACKAGE prd_service_pkg AS
  TYPE t_product_record IS RECORD (
    product_public_id BEX_PRODUCT.PRD_PUBLIC_ID%TYPE,
    store_public_id BEX_STORE.STR_PUBLIC_ID%TYPE,
    category_public_id BEX_CATEGORY.CAT_PUBLIC_ID%TYPE,
    brand_public_id BEX_BRAND.BRD_PUBLIC_ID%TYPE,
    title BEX_PRODUCT.PRD_TITLE%TYPE,
    slug BEX_PRODUCT.PRD_SLUG%TYPE,
    description BEX_PRODUCT.PRD_DESCRIPTION%TYPE,
    price BEX_PRODUCT.PRD_PRICE%TYPE,
    quantity BEX_PRODUCT.PRD_QUANTITY%TYPE,
    condition BEX_PRODUCT.PRD_CONDITION%TYPE,
    weight BEX_PRODUCT.PRD_WEIGHT%TYPE,
    width BEX_PRODUCT.PRD_WIDTH%TYPE,
    height BEX_PRODUCT.PRD_HEIGHT%TYPE,
    length BEX_PRODUCT.PRD_LENGTH%TYPE,
    status BEX_PRODUCT.PRD_STATUS%TYPE,
    created_at BEX_PRODUCT.PRD_CREATED_AT%TYPE,
    updated_at BEX_PRODUCT.PRD_UPDATED_AT%TYPE
  );
  TYPE t_product_table IS TABLE OF t_product_record INDEX BY PLS_INTEGER;
  TYPE t_product_identity IS RECORD (
    product_id BEX_PRODUCT.PRD_ID%TYPE,
    store_id BEX_PRODUCT.STR_ID%TYPE,
    status BEX_PRODUCT.PRD_STATUS%TYPE
  );

  e_product_not_found EXCEPTION; e_invalid_product EXCEPTION;
  e_invalid_status EXCEPTION; e_invalid_transition EXCEPTION;
  e_activation_no_stock EXCEPTION; e_product_archived EXCEPTION;
  e_empty_patch EXCEPTION; e_slug_already_used EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_product_not_found,-20780);
  PRAGMA EXCEPTION_INIT(e_invalid_product,-20781);
  PRAGMA EXCEPTION_INIT(e_invalid_status,-20782);
  PRAGMA EXCEPTION_INIT(e_invalid_transition,-20783);
  PRAGMA EXCEPTION_INIT(e_activation_no_stock,-20784);
  PRAGMA EXCEPTION_INIT(e_product_archived,-20785);
  PRAGMA EXCEPTION_INIT(e_empty_patch,-20786);
  PRAGMA EXCEPTION_INIT(e_slug_already_used,-20787);

  FUNCTION create_product(
    p_store_public_id BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_category_public_id BEX_CATEGORY.CAT_PUBLIC_ID%TYPE,
    p_brand_public_id BEX_BRAND.BRD_PUBLIC_ID%TYPE,
    p_creation prd_rule_pkg.t_product_creation,
    p_actor_id BEX_ACCOUNT.ACC_ID%TYPE
  ) RETURN t_product_record;
  FUNCTION get_by_public_id(p_public_id BEX_PRODUCT.PRD_PUBLIC_ID%TYPE)
    RETURN t_product_record;
  FUNCTION get_by_store_slug(
    p_store_public_id BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_slug BEX_PRODUCT.PRD_SLUG%TYPE
  ) RETURN t_product_record;
  FUNCTION list_by_store(
    p_store_public_id BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_status BEX_PRODUCT.PRD_STATUS%TYPE,
    p_actor_id BEX_ACCOUNT.ACC_ID%TYPE
  ) RETURN t_product_table;
  FUNCTION list_public(
    p_category_public_id BEX_CATEGORY.CAT_PUBLIC_ID%TYPE DEFAULT NULL,
    p_brand_public_id BEX_BRAND.BRD_PUBLIC_ID%TYPE DEFAULT NULL,
    p_condition BEX_PRODUCT.PRD_CONDITION%TYPE DEFAULT NULL
  ) RETURN t_product_table;
  FUNCTION update_product(
    p_product_public_id BEX_PRODUCT.PRD_PUBLIC_ID%TYPE,
    p_store_public_id BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_patch prd_rule_pkg.t_product_patch,
    p_set_category BOOLEAN,
    p_category_public_id BEX_CATEGORY.CAT_PUBLIC_ID%TYPE,
    p_set_brand BOOLEAN,
    p_brand_public_id BEX_BRAND.BRD_PUBLIC_ID%TYPE,
    p_actor_id BEX_ACCOUNT.ACC_ID%TYPE
  ) RETURN t_product_record;
  FUNCTION change_status(
    p_product_public_id BEX_PRODUCT.PRD_PUBLIC_ID%TYPE,
    p_store_public_id BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_new_status BEX_PRODUCT.PRD_STATUS%TYPE,
    p_actor_id BEX_ACCOUNT.ACC_ID%TYPE
  ) RETURN t_product_record;
  FUNCTION resolve_product_identity(
    p_product_public_id BEX_PRODUCT.PRD_PUBLIC_ID%TYPE
  ) RETURN t_product_identity;
  FUNCTION resolve_catalog_product_identity(
    p_product_public_id BEX_PRODUCT.PRD_PUBLIC_ID%TYPE,
    p_store_public_id BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_actor_id BEX_ACCOUNT.ACC_ID%TYPE
  ) RETURN t_product_identity;
  FUNCTION resolve_product_public_id(
    p_product_id BEX_PRODUCT.PRD_ID%TYPE
  ) RETURN BEX_PRODUCT.PRD_PUBLIC_ID%TYPE;
END prd_service_pkg;
/
