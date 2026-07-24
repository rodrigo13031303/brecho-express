CREATE OR REPLACE PACKAGE pim_repository_pkg AS
  TYPE t_row IS RECORD(
    pim_id BEX_PRODUCT_IMAGE.PIM_ID%TYPE,
    pim_public_id BEX_PRODUCT_IMAGE.PIM_PUBLIC_ID%TYPE,
    prd_id BEX_PRODUCT_IMAGE.PRD_ID%TYPE,
    pim_url BEX_PRODUCT_IMAGE.PIM_URL%TYPE,
    pim_alt_text BEX_PRODUCT_IMAGE.PIM_ALT_TEXT%TYPE,
    pim_sort_order BEX_PRODUCT_IMAGE.PIM_SORT_ORDER%TYPE,
    pim_is_primary BEX_PRODUCT_IMAGE.PIM_IS_PRIMARY%TYPE,
    pim_status BEX_PRODUCT_IMAGE.PIM_STATUS%TYPE,
    pim_created_at BEX_PRODUCT_IMAGE.PIM_CREATED_AT%TYPE,
    pim_updated_at BEX_PRODUCT_IMAGE.PIM_UPDATED_AT%TYPE,
    pim_created_by BEX_PRODUCT_IMAGE.PIM_CREATED_BY%TYPE,
    pim_updated_by BEX_PRODUCT_IMAGE.PIM_UPDATED_BY%TYPE
  );
  TYPE t_table IS TABLE OF t_row INDEX BY PLS_INTEGER;
  PROCEDURE insert_row(p t_row,o_id OUT NUMBER);
  FUNCTION get_by_id(p_id NUMBER) RETURN t_row;
  FUNCTION get_by_public_id(p_public_id VARCHAR2) RETURN t_row;
  FUNCTION list_by_product(p_product_id NUMBER,p_status VARCHAR2 DEFAULT NULL) RETURN t_table;
  PROCEDURE lock_by_id(p_id NUMBER);
  PROCEDURE clear_primary(p_product_id NUMBER,p_except_id NUMBER,p_actor NUMBER);
  PROCEDURE update_row(p t_row,o_updated OUT BOOLEAN);
  PROCEDURE update_status(p_id NUMBER,p_status VARCHAR2,p_actor NUMBER,o_updated OUT BOOLEAN);
END pim_repository_pkg;
/
