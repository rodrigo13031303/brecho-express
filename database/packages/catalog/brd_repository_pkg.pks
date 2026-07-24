CREATE OR REPLACE PACKAGE brd_repository_pkg AS
  TYPE t_brand_record IS RECORD (
    brd_id BEX_BRAND.BRD_ID%TYPE,
    brd_public_id BEX_BRAND.BRD_PUBLIC_ID%TYPE,
    brd_name BEX_BRAND.BRD_NAME%TYPE,
    brd_slug BEX_BRAND.BRD_SLUG%TYPE,
    brd_description BEX_BRAND.BRD_DESCRIPTION%TYPE,
    brd_status BEX_BRAND.BRD_STATUS%TYPE,
    brd_created_at BEX_BRAND.BRD_CREATED_AT%TYPE,
    brd_created_by BEX_BRAND.BRD_CREATED_BY%TYPE,
    brd_updated_at BEX_BRAND.BRD_UPDATED_AT%TYPE,
    brd_updated_by BEX_BRAND.BRD_UPDATED_BY%TYPE
  );
  TYPE t_brand_table IS TABLE OF t_brand_record INDEX BY PLS_INTEGER;
  PROCEDURE insert_brand(
    p_public_id BEX_BRAND.BRD_PUBLIC_ID%TYPE,
    p_name BEX_BRAND.BRD_NAME%TYPE,
    p_slug BEX_BRAND.BRD_SLUG%TYPE,
    p_description BEX_BRAND.BRD_DESCRIPTION%TYPE,
    p_status BEX_BRAND.BRD_STATUS%TYPE,
    p_created_by BEX_BRAND.BRD_CREATED_BY%TYPE,
    p_updated_by BEX_BRAND.BRD_UPDATED_BY%TYPE,
    o_brand_id OUT BEX_BRAND.BRD_ID%TYPE
  );
  FUNCTION get_by_id(p_brand_id BEX_BRAND.BRD_ID%TYPE)
    RETURN t_brand_record;
  FUNCTION get_by_public_id(p_public_id BEX_BRAND.BRD_PUBLIC_ID%TYPE)
    RETURN t_brand_record;
  FUNCTION get_by_slug(p_slug BEX_BRAND.BRD_SLUG%TYPE)
    RETURN t_brand_record;
  PROCEDURE lock_by_id(p_brand_id BEX_BRAND.BRD_ID%TYPE);
  FUNCTION public_id_exists(p_public_id BEX_BRAND.BRD_PUBLIC_ID%TYPE)
    RETURN BOOLEAN;
  FUNCTION slug_exists(p_slug BEX_BRAND.BRD_SLUG%TYPE) RETURN BOOLEAN;
  FUNCTION list_all(p_status BEX_BRAND.BRD_STATUS%TYPE DEFAULT NULL)
    RETURN t_brand_table;
  PROCEDURE update_brand(
    p_brand_id BEX_BRAND.BRD_ID%TYPE,
    p_name BEX_BRAND.BRD_NAME%TYPE,
    p_slug BEX_BRAND.BRD_SLUG%TYPE,
    p_description BEX_BRAND.BRD_DESCRIPTION%TYPE,
    p_updated_at BEX_BRAND.BRD_UPDATED_AT%TYPE,
    p_updated_by BEX_BRAND.BRD_UPDATED_BY%TYPE,
    o_updated OUT BOOLEAN
  );
  PROCEDURE update_status(
    p_brand_id BEX_BRAND.BRD_ID%TYPE,
    p_status BEX_BRAND.BRD_STATUS%TYPE,
    p_updated_at BEX_BRAND.BRD_UPDATED_AT%TYPE,
    p_updated_by BEX_BRAND.BRD_UPDATED_BY%TYPE,
    o_updated OUT BOOLEAN
  );
END brd_repository_pkg;
/
