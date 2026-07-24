CREATE OR REPLACE PACKAGE BODY prd_service_pkg AS
  FUNCTION is_true(p_value BOOLEAN) RETURN BOOLEAN IS
  BEGIN RETURN p_value IS NOT NULL AND p_value; END;

  FUNCTION map_row(p prd_repository_pkg.t_product_record)
    RETURN t_product_record IS r t_product_record;
    s str_service_pkg.t_store_record;
  BEGIN
    IF p.prd_id IS NULL THEN RETURN r; END IF;
    s:=str_service_pkg.get_store_by_id(p.str_id);
    r.product_public_id:=p.prd_public_id; r.store_public_id:=s.store_public_id;
    r.category_public_id:=cat_service_pkg.resolve_category_public_id(p.cat_id);
    IF p.brd_id IS NOT NULL THEN
      r.brand_public_id:=brd_service_pkg.resolve_brand_public_id(p.brd_id);
    END IF;
    r.title:=p.prd_title; r.slug:=p.prd_slug;
    r.description:=p.prd_description; r.price:=p.prd_price;
    r.quantity:=p.prd_quantity; r.condition:=p.prd_condition;
    r.weight:=p.prd_weight; r.width:=p.prd_width; r.height:=p.prd_height;
    r.length:=p.prd_length; r.status:=p.prd_status;
    r.created_at:=p.prd_created_at; r.updated_at:=p.prd_updated_at;
    RETURN r;
  END;

  FUNCTION generate_public_id RETURN BEX_PRODUCT.PRD_PUBLIC_ID%TYPE IS
  BEGIN RETURN LOWER(RAWTOHEX(SYS_GUID())); END;

  PROCEDURE normalize_creation(
    io_value IN OUT NOCOPY prd_rule_pkg.t_product_creation
  ) IS
  BEGIN prd_rule_pkg.normalize_and_validate_creation(io_value);
  EXCEPTION
    WHEN prd_rule_pkg.e_title_required OR prd_rule_pkg.e_invalid_title
      OR prd_rule_pkg.e_slug_required OR prd_rule_pkg.e_invalid_slug
      OR prd_rule_pkg.e_invalid_description OR prd_rule_pkg.e_invalid_price
      OR prd_rule_pkg.e_invalid_quantity OR prd_rule_pkg.e_invalid_condition
      OR prd_rule_pkg.e_invalid_weight OR prd_rule_pkg.e_invalid_dimensions
    THEN RAISE e_invalid_product;
  END;

  FUNCTION get_internal(p_public_id BEX_PRODUCT.PRD_PUBLIC_ID%TYPE)
    RETURN prd_repository_pkg.t_product_record IS p prd_repository_pkg.t_product_record;
  BEGIN
    BEGIN p:=prd_repository_pkg.get_by_public_id(p_public_id);
    EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_product_not_found; END;
    RETURN p;
  END;

  FUNCTION create_product(
    p_store_public_id BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_category_public_id BEX_CATEGORY.CAT_PUBLIC_ID%TYPE,
    p_brand_public_id BEX_BRAND.BRD_PUBLIC_ID%TYPE,
    p_creation prd_rule_pkg.t_product_creation,
    p_actor_id BEX_ACCOUNT.ACC_ID%TYPE
  ) RETURN t_product_record IS
    c prd_rule_pkg.t_product_creation:=p_creation;
    p prd_repository_pkg.t_product_record; l_id NUMBER;
  BEGIN
    p.str_id:=str_service_pkg.resolve_catalog_store_id(
      p_store_public_id,p_actor_id
    );
    p.cat_id:=cat_service_pkg.resolve_active_category_id(p_category_public_id);
    IF p_brand_public_id IS NOT NULL THEN
      p.brd_id:=brd_service_pkg.resolve_active_brand_id(p_brand_public_id);
    END IF;
    normalize_creation(c);
    IF prd_repository_pkg.slug_exists(p.str_id,c.slug_value) THEN
      RAISE e_slug_already_used;
    END IF;
    p.prd_public_id:=generate_public_id; p.prd_title:=c.title_value;
    p.prd_slug:=c.slug_value; p.prd_description:=c.description_value;
    p.prd_price:=c.price_value; p.prd_quantity:=c.quantity_value;
    p.prd_condition:=c.condition_value; p.prd_weight:=c.weight_value;
    p.prd_width:=c.width_value; p.prd_height:=c.height_value;
    p.prd_length:=c.length_value; p.prd_status:=c.status_value;
    p.prd_created_by:=p_actor_id; p.prd_updated_by:=p_actor_id;
    BEGIN prd_repository_pkg.insert_product(p,l_id);
    EXCEPTION WHEN DUP_VAL_ON_INDEX THEN RAISE e_slug_already_used; END;
    RETURN map_row(prd_repository_pkg.get_by_id(l_id));
  END;

  FUNCTION get_by_public_id(p_public_id BEX_PRODUCT.PRD_PUBLIC_ID%TYPE)
    RETURN t_product_record IS
  BEGIN RETURN map_row(get_internal(p_public_id)); END;

  FUNCTION get_by_store_slug(
    p_store_public_id BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_slug BEX_PRODUCT.PRD_SLUG%TYPE
  ) RETURN t_product_record IS p prd_repository_pkg.t_product_record;
    l_store NUMBER; l_slug VARCHAR2(32767);
  BEGIN
    l_store:=str_service_pkg.resolve_store_id(p_store_public_id);
    l_slug:=prd_rule_pkg.normalize_slug(p_slug);
    BEGIN prd_rule_pkg.validate_slug(l_slug);
    EXCEPTION
      WHEN prd_rule_pkg.e_slug_required OR prd_rule_pkg.e_invalid_slug
      THEN RAISE e_invalid_product;
    END;
    BEGIN p:=prd_repository_pkg.get_by_store_slug(l_store,l_slug);
    EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_product_not_found; END;
    RETURN map_row(p);
  END;

  FUNCTION map_rows(p prd_repository_pkg.t_product_table)
    RETURN t_product_table IS r t_product_table; i PLS_INTEGER:=p.FIRST;
  BEGIN
    WHILE i IS NOT NULL LOOP r(r.COUNT+1):=map_row(p(i)); i:=p.NEXT(i); END LOOP;
    RETURN r;
  END;

  FUNCTION list_by_store(
    p_store_public_id BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_status BEX_PRODUCT.PRD_STATUS%TYPE,
    p_actor_id BEX_ACCOUNT.ACC_ID%TYPE
  ) RETURN t_product_table IS l_store NUMBER; l_status VARCHAR2(30);
  BEGIN
    l_store:=str_service_pkg.resolve_catalog_store_id(
      p_store_public_id,p_actor_id
    );
    IF p_status IS NOT NULL THEN
      l_status:=prd_rule_pkg.normalize_status(p_status);
      BEGIN prd_rule_pkg.validate_status(l_status);
      EXCEPTION WHEN prd_rule_pkg.e_invalid_status THEN RAISE e_invalid_status; END;
    END IF;
    RETURN map_rows(prd_repository_pkg.list_by_store(l_store,l_status));
  END;

  FUNCTION list_public(
    p_category_public_id BEX_CATEGORY.CAT_PUBLIC_ID%TYPE DEFAULT NULL,
    p_brand_public_id BEX_BRAND.BRD_PUBLIC_ID%TYPE DEFAULT NULL,
    p_condition BEX_PRODUCT.PRD_CONDITION%TYPE DEFAULT NULL
  ) RETURN t_product_table IS l_cat NUMBER; l_brd NUMBER; l_cond VARCHAR2(30);
  BEGIN
    IF p_category_public_id IS NOT NULL THEN
      l_cat:=cat_service_pkg.resolve_active_category_id(p_category_public_id);
    END IF;
    IF p_brand_public_id IS NOT NULL THEN
      l_brd:=brd_service_pkg.resolve_active_brand_id(p_brand_public_id);
    END IF;
    IF p_condition IS NOT NULL THEN
      l_cond:=prd_rule_pkg.normalize_condition(p_condition);
      BEGIN prd_rule_pkg.validate_condition(l_cond);
      EXCEPTION WHEN prd_rule_pkg.e_invalid_condition THEN RAISE e_invalid_product; END;
    END IF;
    RETURN map_rows(prd_repository_pkg.list_public(l_cat,l_brd,l_cond));
  END;

  FUNCTION update_product(
    p_product_public_id BEX_PRODUCT.PRD_PUBLIC_ID%TYPE,
    p_store_public_id BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_patch prd_rule_pkg.t_product_patch,p_set_category BOOLEAN,
    p_category_public_id BEX_CATEGORY.CAT_PUBLIC_ID%TYPE,p_set_brand BOOLEAN,
    p_brand_public_id BEX_BRAND.BRD_PUBLIC_ID%TYPE,
    p_actor_id BEX_ACCOUNT.ACC_ID%TYPE
  ) RETURN t_product_record IS p prd_repository_pkg.t_product_record;
    x prd_rule_pkg.t_product_patch:=p_patch; l_store NUMBER; l_ok BOOLEAN;
  BEGIN
    l_store:=str_service_pkg.resolve_catalog_store_id(
      p_store_public_id,p_actor_id
    ); p:=get_internal(p_product_public_id);
    IF p.str_id<>l_store THEN RAISE e_product_not_found; END IF;
    prd_repository_pkg.lock_by_id(p.prd_id);
    BEGIN
      prd_rule_pkg.normalize_and_validate_patch(
        p.prd_status,p.prd_weight,p.prd_width,p.prd_height,p.prd_length,x
      );
    EXCEPTION
      WHEN prd_rule_pkg.e_empty_patch THEN
        IF NOT is_true(p_set_category) AND NOT is_true(p_set_brand)
        THEN RAISE e_empty_patch; END IF;
      WHEN prd_rule_pkg.e_product_archived THEN RAISE e_product_archived;
      WHEN prd_rule_pkg.e_title_required OR prd_rule_pkg.e_invalid_title
        OR prd_rule_pkg.e_slug_required OR prd_rule_pkg.e_invalid_slug
        OR prd_rule_pkg.e_invalid_description OR prd_rule_pkg.e_invalid_price
        OR prd_rule_pkg.e_invalid_quantity OR prd_rule_pkg.e_invalid_condition
        OR prd_rule_pkg.e_invalid_weight OR prd_rule_pkg.e_invalid_dimensions
      THEN RAISE e_invalid_product;
    END;
    IF is_true(p_set_category) THEN
      p.cat_id:=cat_service_pkg.resolve_active_category_id(p_category_public_id);
    END IF;
    IF is_true(p_set_brand) THEN
      IF p_brand_public_id IS NULL THEN p.brd_id:=NULL;
      ELSE p.brd_id:=brd_service_pkg.resolve_active_brand_id(p_brand_public_id); END IF;
    END IF;
    IF is_true(x.set_title) THEN p.prd_title:=x.title_value; END IF;
    IF is_true(x.set_slug) THEN
      IF prd_repository_pkg.slug_exists(p.str_id,x.slug_value,p.prd_id)
      THEN RAISE e_slug_already_used; END IF; p.prd_slug:=x.slug_value;
    END IF;
    IF is_true(x.set_description) THEN p.prd_description:=x.description_value; END IF;
    IF is_true(x.set_price) THEN p.prd_price:=x.price_value; END IF;
    IF is_true(x.set_quantity) THEN p.prd_quantity:=x.quantity_value; END IF;
    IF is_true(x.set_condition) THEN p.prd_condition:=x.condition_value; END IF;
    IF is_true(x.set_weight) THEN p.prd_weight:=x.weight_value; END IF;
    IF is_true(x.set_width) THEN p.prd_width:=x.width_value; END IF;
    IF is_true(x.set_height) THEN p.prd_height:=x.height_value; END IF;
    IF is_true(x.set_length) THEN p.prd_length:=x.length_value; END IF;
    p.prd_updated_at:=SYSTIMESTAMP; p.prd_updated_by:=p_actor_id;
    prd_repository_pkg.update_product(p,l_ok);
    RETURN map_row(prd_repository_pkg.get_by_id(p.prd_id));
  END;

  FUNCTION change_status(
    p_product_public_id BEX_PRODUCT.PRD_PUBLIC_ID%TYPE,
    p_store_public_id BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_new_status BEX_PRODUCT.PRD_STATUS%TYPE,p_actor_id BEX_ACCOUNT.ACC_ID%TYPE
  ) RETURN t_product_record IS p prd_repository_pkg.t_product_record;
    l_store NUMBER; l_new VARCHAR2(30); l_ok BOOLEAN;
  BEGIN
    l_store:=str_service_pkg.resolve_catalog_store_id(
      p_store_public_id,p_actor_id
    ); p:=get_internal(p_product_public_id);
    IF p.str_id<>l_store THEN RAISE e_product_not_found; END IF;
    prd_repository_pkg.lock_by_id(p.prd_id);
    l_new:=prd_rule_pkg.normalize_status(p_new_status);
    BEGIN prd_rule_pkg.validate_status_transition(
      p.prd_status,l_new,p.prd_quantity
    );
    EXCEPTION
      WHEN prd_rule_pkg.e_invalid_status THEN RAISE e_invalid_status;
      WHEN prd_rule_pkg.e_invalid_transition THEN RAISE e_invalid_transition;
      WHEN prd_rule_pkg.e_activation_no_stock THEN RAISE e_activation_no_stock;
    END;
    prd_repository_pkg.update_status(
      p.prd_id,l_new,SYSTIMESTAMP,p_actor_id,l_ok
    );
    RETURN map_row(prd_repository_pkg.get_by_id(p.prd_id));
  END;

  FUNCTION resolve_product_identity(
    p_product_public_id BEX_PRODUCT.PRD_PUBLIC_ID%TYPE
  ) RETURN t_product_identity IS
    p prd_repository_pkg.t_product_record; r t_product_identity;
  BEGIN
    p:=get_internal(p_product_public_id);
    r.product_id:=p.prd_id; r.store_id:=p.str_id; r.status:=p.prd_status;
    RETURN r;
  END;

  FUNCTION resolve_catalog_product_identity(
    p_product_public_id BEX_PRODUCT.PRD_PUBLIC_ID%TYPE,
    p_store_public_id BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_actor_id BEX_ACCOUNT.ACC_ID%TYPE
  ) RETURN t_product_identity IS
    r t_product_identity; l_store BEX_STORE.STR_ID%TYPE;
  BEGIN
    l_store:=str_service_pkg.resolve_catalog_store_id(
      p_store_public_id,p_actor_id
    );
    r:=resolve_product_identity(p_product_public_id);
    IF r.store_id<>l_store THEN RAISE e_product_not_found; END IF;
    RETURN r;
  END;

  FUNCTION resolve_product_public_id(
    p_product_id BEX_PRODUCT.PRD_ID%TYPE
  ) RETURN BEX_PRODUCT.PRD_PUBLIC_ID%TYPE IS
    l_product prd_repository_pkg.t_product_record;
  BEGIN
    l_product:=prd_repository_pkg.get_by_id(p_product_id);
    RETURN l_product.prd_public_id;
  EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_product_not_found;
  END;
END prd_service_pkg;
/
