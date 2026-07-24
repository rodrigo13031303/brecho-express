CREATE OR REPLACE PACKAGE pim_rule_pkg AS
  c_status_active CONSTANT BEX_PRODUCT_IMAGE.PIM_STATUS%TYPE:='ACTIVE';
  c_status_inactive CONSTANT BEX_PRODUCT_IMAGE.PIM_STATUS%TYPE:='INACTIVE';
  e_invalid_url EXCEPTION; e_invalid_alt_text EXCEPTION;
  e_invalid_sort_order EXCEPTION; e_invalid_primary EXCEPTION;
  e_invalid_status EXCEPTION; e_empty_patch EXCEPTION;
  TYPE t_image_data IS RECORD(
    url_value BEX_PRODUCT_IMAGE.PIM_URL%TYPE,
    alt_text_value BEX_PRODUCT_IMAGE.PIM_ALT_TEXT%TYPE,
    sort_order_value BEX_PRODUCT_IMAGE.PIM_SORT_ORDER%TYPE,
    is_primary_value BEX_PRODUCT_IMAGE.PIM_IS_PRIMARY%TYPE,
    status_value BEX_PRODUCT_IMAGE.PIM_STATUS%TYPE
  );
  TYPE t_image_patch IS RECORD(
    set_url BOOLEAN:=FALSE,url_value BEX_PRODUCT_IMAGE.PIM_URL%TYPE,
    set_alt_text BOOLEAN:=FALSE,alt_text_value BEX_PRODUCT_IMAGE.PIM_ALT_TEXT%TYPE,
    set_sort_order BOOLEAN:=FALSE,sort_order_value BEX_PRODUCT_IMAGE.PIM_SORT_ORDER%TYPE,
    set_is_primary BOOLEAN:=FALSE,is_primary_value BEX_PRODUCT_IMAGE.PIM_IS_PRIMARY%TYPE
  );
  FUNCTION normalize_url(p VARCHAR2) RETURN VARCHAR2;
  FUNCTION normalize_alt_text(p VARCHAR2) RETURN VARCHAR2;
  FUNCTION normalize_status(p VARCHAR2) RETURN VARCHAR2;
  PROCEDURE validate_data(io_data IN OUT NOCOPY t_image_data);
  PROCEDURE validate_patch(io_patch IN OUT NOCOPY t_image_patch);
  PROCEDURE validate_status(p VARCHAR2);
END pim_rule_pkg;
/
