CREATE OR REPLACE PACKAGE pim_service_pkg AS
  TYPE t_record IS RECORD(
    image_public_id BEX_PRODUCT_IMAGE.PIM_PUBLIC_ID%TYPE,
    product_public_id BEX_PRODUCT.PRD_PUBLIC_ID%TYPE,
    image_url BEX_PRODUCT_IMAGE.PIM_URL%TYPE,
    alt_text BEX_PRODUCT_IMAGE.PIM_ALT_TEXT%TYPE,
    sort_order BEX_PRODUCT_IMAGE.PIM_SORT_ORDER%TYPE,
    is_primary BEX_PRODUCT_IMAGE.PIM_IS_PRIMARY%TYPE,
    status BEX_PRODUCT_IMAGE.PIM_STATUS%TYPE,
    created_at BEX_PRODUCT_IMAGE.PIM_CREATED_AT%TYPE,
    updated_at BEX_PRODUCT_IMAGE.PIM_UPDATED_AT%TYPE
  );
  TYPE t_table IS TABLE OF t_record INDEX BY PLS_INTEGER;
  e_image_not_found EXCEPTION; e_invalid_image EXCEPTION;
  e_empty_patch EXCEPTION; e_primary_conflict EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_image_not_found,-20790);
  PRAGMA EXCEPTION_INIT(e_invalid_image,-20791);
  PRAGMA EXCEPTION_INIT(e_empty_patch,-20792);
  PRAGMA EXCEPTION_INIT(e_primary_conflict,-20793);
  FUNCTION add_image(p_product_public_id VARCHAR2,p_store_public_id VARCHAR2,
    p_data pim_rule_pkg.t_image_data,p_actor_id NUMBER) RETURN t_record;
  FUNCTION get_image(p_image_public_id VARCHAR2) RETURN t_record;
  FUNCTION list_images(p_product_public_id VARCHAR2) RETURN t_table;
  FUNCTION update_image(p_image_public_id VARCHAR2,p_store_public_id VARCHAR2,
    p_patch pim_rule_pkg.t_image_patch,p_actor_id NUMBER) RETURN t_record;
  FUNCTION deactivate_image(p_image_public_id VARCHAR2,p_store_public_id VARCHAR2,
    p_actor_id NUMBER) RETURN t_record;
END pim_service_pkg;
/
