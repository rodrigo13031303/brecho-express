CREATE OR REPLACE PACKAGE prd_repository_pkg AS
  TYPE t_product_record IS RECORD (
    prd_id BEX_PRODUCT.PRD_ID%TYPE,
    prd_public_id BEX_PRODUCT.PRD_PUBLIC_ID%TYPE,
    str_id BEX_PRODUCT.STR_ID%TYPE,
    cat_id BEX_PRODUCT.CAT_ID%TYPE,
    brd_id BEX_PRODUCT.BRD_ID%TYPE,
    prd_title BEX_PRODUCT.PRD_TITLE%TYPE,
    prd_slug BEX_PRODUCT.PRD_SLUG%TYPE,
    prd_description BEX_PRODUCT.PRD_DESCRIPTION%TYPE,
    prd_price BEX_PRODUCT.PRD_PRICE%TYPE,
    prd_quantity BEX_PRODUCT.PRD_QUANTITY%TYPE,
    prd_condition BEX_PRODUCT.PRD_CONDITION%TYPE,
    prd_weight BEX_PRODUCT.PRD_WEIGHT%TYPE,
    prd_width BEX_PRODUCT.PRD_WIDTH%TYPE,
    prd_height BEX_PRODUCT.PRD_HEIGHT%TYPE,
    prd_length BEX_PRODUCT.PRD_LENGTH%TYPE,
    prd_status BEX_PRODUCT.PRD_STATUS%TYPE,
    prd_created_at BEX_PRODUCT.PRD_CREATED_AT%TYPE,
    prd_created_by BEX_PRODUCT.PRD_CREATED_BY%TYPE,
    prd_updated_at BEX_PRODUCT.PRD_UPDATED_AT%TYPE,
    prd_updated_by BEX_PRODUCT.PRD_UPDATED_BY%TYPE
  );
  TYPE t_product_table IS TABLE OF t_product_record INDEX BY PLS_INTEGER;

  PROCEDURE insert_product(
    p_product t_product_record,
    o_product_id OUT BEX_PRODUCT.PRD_ID%TYPE
  );
  FUNCTION get_by_id(p_product_id BEX_PRODUCT.PRD_ID%TYPE)
    RETURN t_product_record;
  FUNCTION get_by_public_id(p_public_id BEX_PRODUCT.PRD_PUBLIC_ID%TYPE)
    RETURN t_product_record;
  FUNCTION get_by_store_slug(
    p_store_id BEX_PRODUCT.STR_ID%TYPE,
    p_slug BEX_PRODUCT.PRD_SLUG%TYPE
  ) RETURN t_product_record;
  PROCEDURE lock_by_id(p_product_id BEX_PRODUCT.PRD_ID%TYPE);
  FUNCTION public_id_exists(p_public_id BEX_PRODUCT.PRD_PUBLIC_ID%TYPE)
    RETURN BOOLEAN;
  FUNCTION slug_exists(
    p_store_id BEX_PRODUCT.STR_ID%TYPE,
    p_slug BEX_PRODUCT.PRD_SLUG%TYPE,
    p_exclude_product_id BEX_PRODUCT.PRD_ID%TYPE DEFAULT NULL
  ) RETURN BOOLEAN;
  FUNCTION list_by_store(
    p_store_id BEX_PRODUCT.STR_ID%TYPE,
    p_status BEX_PRODUCT.PRD_STATUS%TYPE DEFAULT NULL
  ) RETURN t_product_table;
  FUNCTION list_public(
    p_category_id BEX_PRODUCT.CAT_ID%TYPE DEFAULT NULL,
    p_brand_id BEX_PRODUCT.BRD_ID%TYPE DEFAULT NULL,
    p_condition BEX_PRODUCT.PRD_CONDITION%TYPE DEFAULT NULL
  ) RETURN t_product_table;
  PROCEDURE update_product(
    p_product t_product_record,
    o_updated OUT BOOLEAN
  );
  PROCEDURE update_status(
    p_product_id BEX_PRODUCT.PRD_ID%TYPE,
    p_status BEX_PRODUCT.PRD_STATUS%TYPE,
    p_updated_at BEX_PRODUCT.PRD_UPDATED_AT%TYPE,
    p_updated_by BEX_PRODUCT.PRD_UPDATED_BY%TYPE,
    o_updated OUT BOOLEAN
  );
END prd_repository_pkg;
/
