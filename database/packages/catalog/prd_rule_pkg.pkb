CREATE OR REPLACE PACKAGE BODY prd_rule_pkg AS
  FUNCTION is_true(p_value BOOLEAN) RETURN BOOLEAN IS
  BEGIN
    RETURN p_value IS NOT NULL AND p_value;
  END;

  FUNCTION normalize_title(p_title VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN REGEXP_REPLACE(TRIM(p_title),'[[:space:]]+',' ');
  END;

  FUNCTION normalize_slug(p_slug VARCHAR2) RETURN VARCHAR2 IS
    l_slug VARCHAR2(32767);
  BEGIN
    IF p_slug IS NULL THEN RETURN NULL; END IF;
    l_slug:=TRANSLATE(
      TRIM(p_slug),
      UNISTR(
        '\00E1\00E0\00E2\00E3\00E4\00E9\00E8\00EA\00EB'||
        '\00ED\00EC\00EE\00EF\00F3\00F2\00F4\00F5\00F6'||
        '\00FA\00F9\00FB\00FC\00E7\00F1'||
        '\00C1\00C0\00C2\00C3\00C4\00C9\00C8\00CA\00CB'||
        '\00CD\00CC\00CE\00CF\00D3\00D2\00D4\00D5\00D6'||
        '\00DA\00D9\00DB\00DC\00C7\00D1'
      ),
      'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN'
    );
    l_slug:=LOWER(l_slug);
    l_slug:=REGEXP_REPLACE(l_slug,'[[:space:]]+','-');
    l_slug:=REGEXP_REPLACE(l_slug,'[^a-z0-9-]','');
    l_slug:=REGEXP_REPLACE(l_slug,'-+','-');
    RETURN REGEXP_REPLACE(l_slug,'^-+|-+$','');
  END;

  FUNCTION normalize_description(p_description VARCHAR2) RETURN VARCHAR2 IS
  BEGIN RETURN TRIM(p_description); END;
  FUNCTION normalize_condition(p_condition VARCHAR2) RETURN VARCHAR2 IS
  BEGIN RETURN UPPER(TRIM(p_condition)); END;
  FUNCTION normalize_status(p_status VARCHAR2) RETURN VARCHAR2 IS
  BEGIN RETURN UPPER(TRIM(p_status)); END;

  PROCEDURE validate_title(p_title VARCHAR2) IS
    l_value VARCHAR2(32767):=normalize_title(p_title);
  BEGIN
    IF l_value IS NULL THEN RAISE e_title_required;
    ELSIF LENGTH(l_value)>200 THEN RAISE e_invalid_title; END IF;
  END;

  PROCEDURE validate_slug(p_slug VARCHAR2) IS
    l_value VARCHAR2(32767):=normalize_slug(p_slug);
  BEGIN
    IF l_value IS NULL THEN RAISE e_slug_required;
    ELSIF LENGTH(l_value)>200
       OR NOT REGEXP_LIKE(l_value,'^[a-z0-9]+(-[a-z0-9]+)*$')
    THEN RAISE e_invalid_slug; END IF;
  END;

  PROCEDURE validate_description(p_description VARCHAR2) IS
  BEGIN
    IF normalize_description(p_description) IS NOT NULL
       AND LENGTH(normalize_description(p_description))>4000
    THEN RAISE e_invalid_description; END IF;
  END;

  PROCEDURE validate_price(p_price NUMBER) IS
  BEGIN
    IF p_price IS NULL OR p_price<0 THEN RAISE e_invalid_price; END IF;
  END;

  PROCEDURE validate_quantity(p_quantity NUMBER) IS
  BEGIN
    IF p_quantity IS NULL OR p_quantity<0 OR p_quantity<>TRUNC(p_quantity)
    THEN RAISE e_invalid_quantity; END IF;
  END;

  PROCEDURE validate_condition(p_condition VARCHAR2) IS
    l_value VARCHAR2(32767):=normalize_condition(p_condition);
  BEGIN
    IF l_value IS NULL OR l_value NOT IN (
      c_condition_new,c_condition_like_new,c_condition_good,c_condition_fair
    ) THEN RAISE e_invalid_condition; END IF;
  END;

  PROCEDURE validate_measurements(
    p_weight NUMBER,p_width NUMBER,p_height NUMBER,p_length NUMBER
  ) IS
  BEGIN
    IF p_weight IS NOT NULL AND p_weight<=0 THEN RAISE e_invalid_weight; END IF;
    IF (p_width IS NULL AND p_height IS NULL AND p_length IS NULL) THEN
      RETURN;
    END IF;
    IF p_width IS NULL OR p_height IS NULL OR p_length IS NULL
       OR p_width<=0 OR p_height<=0 OR p_length<=0
    THEN RAISE e_invalid_dimensions; END IF;
  END;

  PROCEDURE validate_status(p_status VARCHAR2) IS
    l_value VARCHAR2(32767):=normalize_status(p_status);
  BEGIN
    IF l_value IS NULL OR l_value NOT IN (
      c_status_draft,c_status_active,c_status_inactive,
      c_status_sold,c_status_archived
    ) THEN RAISE e_invalid_status; END IF;
  END;

  PROCEDURE validate_status_transition(
    p_current_status VARCHAR2,p_new_status VARCHAR2,p_quantity NUMBER
  ) IS
    l_current VARCHAR2(32767);
    l_new VARCHAR2(32767);
  BEGIN
    validate_status(p_current_status);
    validate_status(p_new_status);
    validate_quantity(p_quantity);
    l_current:=normalize_status(p_current_status);
    l_new:=normalize_status(p_new_status);
    IF l_new=c_status_active AND p_quantity=0 THEN
      RAISE e_activation_no_stock;
    END IF;
    IF (l_current=c_status_draft AND l_new IN (c_status_active,c_status_archived))
       OR (l_current=c_status_active AND l_new IN (
         c_status_inactive,c_status_sold,c_status_archived
       ))
       OR (l_current=c_status_inactive AND l_new IN (
         c_status_active,c_status_archived
       ))
       OR (l_current=c_status_sold AND l_new IN (
         c_status_active,c_status_archived
       ))
    THEN RETURN; END IF;
    RAISE e_invalid_transition;
  END;

  PROCEDURE assert_product_editable(p_current_status VARCHAR2) IS
  BEGIN
    validate_status(p_current_status);
    IF normalize_status(p_current_status)=c_status_archived
    THEN RAISE e_product_archived; END IF;
  END;

  PROCEDURE validate_patch_not_empty(p_patch t_product_patch) IS
  BEGIN
    IF NOT is_true(p_patch.set_title)
       AND NOT is_true(p_patch.set_slug)
       AND NOT is_true(p_patch.set_description)
       AND NOT is_true(p_patch.set_price)
       AND NOT is_true(p_patch.set_quantity)
       AND NOT is_true(p_patch.set_condition)
       AND NOT is_true(p_patch.set_weight)
       AND NOT is_true(p_patch.set_width)
       AND NOT is_true(p_patch.set_height)
       AND NOT is_true(p_patch.set_length)
    THEN RAISE e_empty_patch; END IF;
  END;

  PROCEDURE normalize_and_validate_creation(
    io_creation IN OUT NOCOPY t_product_creation
  ) IS
  BEGIN
    io_creation.title_value:=normalize_title(io_creation.title_value);
    io_creation.slug_value:=normalize_slug(io_creation.slug_value);
    io_creation.description_value:=
      normalize_description(io_creation.description_value);
    io_creation.condition_value:=normalize_condition(io_creation.condition_value);
    io_creation.status_value:=c_status_draft;
    validate_title(io_creation.title_value);
    validate_slug(io_creation.slug_value);
    validate_description(io_creation.description_value);
    validate_price(io_creation.price_value);
    validate_quantity(io_creation.quantity_value);
    validate_condition(io_creation.condition_value);
    validate_measurements(
      io_creation.weight_value,io_creation.width_value,
      io_creation.height_value,io_creation.length_value
    );
  END;

  PROCEDURE normalize_and_validate_patch(
    p_current_status VARCHAR2,
    p_current_weight NUMBER,
    p_current_width  NUMBER,
    p_current_height NUMBER,
    p_current_length NUMBER,
    io_patch IN OUT NOCOPY t_product_patch
  ) IS
    l_weight BEX_PRODUCT.PRD_WEIGHT%TYPE;
    l_width  BEX_PRODUCT.PRD_WIDTH%TYPE;
    l_height BEX_PRODUCT.PRD_HEIGHT%TYPE;
    l_length BEX_PRODUCT.PRD_LENGTH%TYPE;
  BEGIN
    assert_product_editable(p_current_status);
    validate_patch_not_empty(io_patch);
    IF is_true(io_patch.set_title) THEN
      io_patch.title_value:=normalize_title(io_patch.title_value);
      validate_title(io_patch.title_value);
    END IF;
    IF is_true(io_patch.set_slug) THEN
      io_patch.slug_value:=normalize_slug(io_patch.slug_value);
      validate_slug(io_patch.slug_value);
    END IF;
    IF is_true(io_patch.set_description) THEN
      io_patch.description_value:=
        normalize_description(io_patch.description_value);
      validate_description(io_patch.description_value);
    END IF;
    IF is_true(io_patch.set_price) THEN validate_price(io_patch.price_value); END IF;
    IF is_true(io_patch.set_quantity) THEN
      validate_quantity(io_patch.quantity_value);
    END IF;
    IF is_true(io_patch.set_condition) THEN
      io_patch.condition_value:=normalize_condition(io_patch.condition_value);
      validate_condition(io_patch.condition_value);
    END IF;
    IF is_true(io_patch.set_weight)
       OR is_true(io_patch.set_width)
       OR is_true(io_patch.set_height)
       OR is_true(io_patch.set_length) THEN
      IF is_true(io_patch.set_weight) THEN
        l_weight:=io_patch.weight_value;
      ELSE l_weight:=p_current_weight; END IF;
      IF is_true(io_patch.set_width) THEN
        l_width:=io_patch.width_value;
      ELSE l_width:=p_current_width; END IF;
      IF is_true(io_patch.set_height) THEN
        l_height:=io_patch.height_value;
      ELSE l_height:=p_current_height; END IF;
      IF is_true(io_patch.set_length) THEN
        l_length:=io_patch.length_value;
      ELSE l_length:=p_current_length; END IF;
      validate_measurements(l_weight,l_width,l_height,l_length);
    END IF;
  END;
END prd_rule_pkg;
/
