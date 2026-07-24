CREATE OR REPLACE PACKAGE prd_rule_pkg AS
  c_status_draft    CONSTANT BEX_PRODUCT.PRD_STATUS%TYPE := 'DRAFT';
  c_status_active   CONSTANT BEX_PRODUCT.PRD_STATUS%TYPE := 'ACTIVE';
  c_status_inactive CONSTANT BEX_PRODUCT.PRD_STATUS%TYPE := 'INACTIVE';
  c_status_sold     CONSTANT BEX_PRODUCT.PRD_STATUS%TYPE := 'SOLD';
  c_status_archived CONSTANT BEX_PRODUCT.PRD_STATUS%TYPE := 'ARCHIVED';

  c_condition_new      CONSTANT BEX_PRODUCT.PRD_CONDITION%TYPE := 'NEW';
  c_condition_like_new CONSTANT BEX_PRODUCT.PRD_CONDITION%TYPE := 'LIKE_NEW';
  c_condition_good     CONSTANT BEX_PRODUCT.PRD_CONDITION%TYPE := 'GOOD';
  c_condition_fair     CONSTANT BEX_PRODUCT.PRD_CONDITION%TYPE := 'FAIR';

  e_title_required       EXCEPTION;
  e_invalid_title        EXCEPTION;
  e_slug_required        EXCEPTION;
  e_invalid_slug         EXCEPTION;
  e_invalid_description  EXCEPTION;
  e_invalid_price        EXCEPTION;
  e_invalid_quantity     EXCEPTION;
  e_invalid_condition    EXCEPTION;
  e_invalid_weight       EXCEPTION;
  e_invalid_dimensions   EXCEPTION;
  e_invalid_status       EXCEPTION;
  e_invalid_transition   EXCEPTION;
  e_activation_no_stock  EXCEPTION;
  e_product_archived     EXCEPTION;
  e_empty_patch          EXCEPTION;

  TYPE t_product_creation IS RECORD (
    title_value       BEX_PRODUCT.PRD_TITLE%TYPE,
    slug_value        BEX_PRODUCT.PRD_SLUG%TYPE,
    description_value BEX_PRODUCT.PRD_DESCRIPTION%TYPE,
    price_value       BEX_PRODUCT.PRD_PRICE%TYPE,
    quantity_value    BEX_PRODUCT.PRD_QUANTITY%TYPE,
    condition_value   BEX_PRODUCT.PRD_CONDITION%TYPE,
    weight_value      BEX_PRODUCT.PRD_WEIGHT%TYPE,
    width_value       BEX_PRODUCT.PRD_WIDTH%TYPE,
    height_value      BEX_PRODUCT.PRD_HEIGHT%TYPE,
    length_value      BEX_PRODUCT.PRD_LENGTH%TYPE,
    status_value      BEX_PRODUCT.PRD_STATUS%TYPE
  );

  TYPE t_product_patch IS RECORD (
    set_title          BOOLEAN := FALSE,
    title_value        BEX_PRODUCT.PRD_TITLE%TYPE,
    set_slug           BOOLEAN := FALSE,
    slug_value         BEX_PRODUCT.PRD_SLUG%TYPE,
    set_description    BOOLEAN := FALSE,
    description_value  BEX_PRODUCT.PRD_DESCRIPTION%TYPE,
    set_price          BOOLEAN := FALSE,
    price_value        BEX_PRODUCT.PRD_PRICE%TYPE,
    set_quantity       BOOLEAN := FALSE,
    quantity_value     BEX_PRODUCT.PRD_QUANTITY%TYPE,
    set_condition      BOOLEAN := FALSE,
    condition_value    BEX_PRODUCT.PRD_CONDITION%TYPE,
    set_weight         BOOLEAN := FALSE,
    weight_value       BEX_PRODUCT.PRD_WEIGHT%TYPE,
    set_width          BOOLEAN := FALSE,
    width_value        BEX_PRODUCT.PRD_WIDTH%TYPE,
    set_height         BOOLEAN := FALSE,
    height_value       BEX_PRODUCT.PRD_HEIGHT%TYPE,
    set_length         BOOLEAN := FALSE,
    length_value       BEX_PRODUCT.PRD_LENGTH%TYPE
  );

  FUNCTION normalize_title(p_title VARCHAR2) RETURN VARCHAR2;
  FUNCTION normalize_slug(p_slug VARCHAR2) RETURN VARCHAR2;
  FUNCTION normalize_description(p_description VARCHAR2) RETURN VARCHAR2;
  FUNCTION normalize_condition(p_condition VARCHAR2) RETURN VARCHAR2;
  FUNCTION normalize_status(p_status VARCHAR2) RETURN VARCHAR2;

  PROCEDURE validate_title(p_title VARCHAR2);
  PROCEDURE validate_slug(p_slug VARCHAR2);
  PROCEDURE validate_description(p_description VARCHAR2);
  PROCEDURE validate_price(p_price NUMBER);
  PROCEDURE validate_quantity(p_quantity NUMBER);
  PROCEDURE validate_condition(p_condition VARCHAR2);
  PROCEDURE validate_measurements(
    p_weight NUMBER,
    p_width  NUMBER,
    p_height NUMBER,
    p_length NUMBER
  );
  PROCEDURE validate_status(p_status VARCHAR2);
  PROCEDURE validate_status_transition(
    p_current_status VARCHAR2,
    p_new_status     VARCHAR2,
    p_quantity       NUMBER
  );
  PROCEDURE assert_product_editable(p_current_status VARCHAR2);
  PROCEDURE validate_patch_not_empty(p_patch t_product_patch);
  PROCEDURE normalize_and_validate_creation(
    io_creation IN OUT NOCOPY t_product_creation
  );
  PROCEDURE normalize_and_validate_patch(
    p_current_status VARCHAR2,
    p_current_weight NUMBER,
    p_current_width  NUMBER,
    p_current_height NUMBER,
    p_current_length NUMBER,
    io_patch         IN OUT NOCOPY t_product_patch
  );
END prd_rule_pkg;
/
