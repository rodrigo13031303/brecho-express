CREATE OR REPLACE PACKAGE brd_service_pkg AS
  TYPE t_brand_record IS RECORD (
    brand_public_id BEX_BRAND.BRD_PUBLIC_ID%TYPE,
    brand_name BEX_BRAND.BRD_NAME%TYPE,
    brand_slug BEX_BRAND.BRD_SLUG%TYPE,
    description BEX_BRAND.BRD_DESCRIPTION%TYPE,
    status BEX_BRAND.BRD_STATUS%TYPE,
    created_at BEX_BRAND.BRD_CREATED_AT%TYPE,
    updated_at BEX_BRAND.BRD_UPDATED_AT%TYPE
  );
  TYPE t_brand_table IS TABLE OF t_brand_record INDEX BY PLS_INTEGER;
  e_brand_not_found EXCEPTION;
  e_brand_inactive EXCEPTION;
  e_invalid_status EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_brand_not_found,-20770);
  PRAGMA EXCEPTION_INIT(e_brand_inactive,-20771);
  PRAGMA EXCEPTION_INIT(e_invalid_status,-20772);
  FUNCTION get_by_public_id(p_public_id BEX_BRAND.BRD_PUBLIC_ID%TYPE)
    RETURN t_brand_record;
  FUNCTION require_by_public_id(p_public_id BEX_BRAND.BRD_PUBLIC_ID%TYPE)
    RETURN t_brand_record;
  FUNCTION get_by_slug(p_slug BEX_BRAND.BRD_SLUG%TYPE)
    RETURN t_brand_record;
  FUNCTION require_by_slug(p_slug BEX_BRAND.BRD_SLUG%TYPE)
    RETURN t_brand_record;
  FUNCTION list_brands(p_status BEX_BRAND.BRD_STATUS%TYPE DEFAULT NULL)
    RETURN t_brand_table;
  FUNCTION resolve_active_brand_id(p_public_id BEX_BRAND.BRD_PUBLIC_ID%TYPE)
    RETURN BEX_BRAND.BRD_ID%TYPE;
  FUNCTION resolve_brand_public_id(p_brand_id BEX_BRAND.BRD_ID%TYPE)
    RETURN BEX_BRAND.BRD_PUBLIC_ID%TYPE;
END brd_service_pkg;
/
