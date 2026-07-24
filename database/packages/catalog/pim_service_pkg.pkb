CREATE OR REPLACE PACKAGE BODY pim_service_pkg AS
  FUNCTION yes(p BOOLEAN) RETURN BOOLEAN IS BEGIN RETURN p IS NOT NULL AND p; END;
  FUNCTION map_row(p pim_repository_pkg.t_row) RETURN t_record IS r t_record;
  BEGIN
    r.image_public_id:=p.pim_public_id;
    r.product_public_id:=prd_service_pkg.resolve_product_public_id(p.prd_id);
    r.image_url:=p.pim_url;r.alt_text:=p.pim_alt_text;r.sort_order:=p.pim_sort_order;
    r.is_primary:=p.pim_is_primary;r.status:=p.pim_status;
    r.created_at:=p.pim_created_at;r.updated_at:=p.pim_updated_at;RETURN r;
  END;
  FUNCTION internal(p VARCHAR2) RETURN pim_repository_pkg.t_row IS r pim_repository_pkg.t_row;
  BEGIN BEGIN r:=pim_repository_pkg.get_by_public_id(p);
    EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_image_not_found; END; RETURN r; END;
  PROCEDURE valid_data(io_data IN OUT NOCOPY pim_rule_pkg.t_image_data) IS
  BEGIN pim_rule_pkg.validate_data(io_data);
  EXCEPTION WHEN pim_rule_pkg.e_invalid_url OR pim_rule_pkg.e_invalid_alt_text
    OR pim_rule_pkg.e_invalid_sort_order OR pim_rule_pkg.e_invalid_primary
    OR pim_rule_pkg.e_invalid_status THEN RAISE e_invalid_image; END;
  FUNCTION add_image(p_product_public_id VARCHAR2,p_store_public_id VARCHAR2,
    p_data pim_rule_pkg.t_image_data,p_actor_id NUMBER) RETURN t_record IS
    d pim_rule_pkg.t_image_data:=p_data;r pim_repository_pkg.t_row;
    x prd_service_pkg.t_product_identity;id NUMBER;
  BEGIN
    x:=prd_service_pkg.resolve_catalog_product_identity(
      p_product_public_id,p_store_public_id,p_actor_id);
    valid_data(d);
    IF d.is_primary_value=1 THEN pim_repository_pkg.clear_primary(x.product_id,NULL,p_actor_id); END IF;
    r.pim_public_id:=LOWER(RAWTOHEX(SYS_GUID()));r.prd_id:=x.product_id;
    r.pim_url:=d.url_value;r.pim_alt_text:=d.alt_text_value;
    r.pim_sort_order:=d.sort_order_value;r.pim_is_primary:=d.is_primary_value;
    r.pim_status:=d.status_value;r.pim_created_by:=p_actor_id;r.pim_updated_by:=p_actor_id;
    BEGIN pim_repository_pkg.insert_row(r,id);
    EXCEPTION WHEN DUP_VAL_ON_INDEX THEN RAISE e_primary_conflict; END;
    RETURN map_row(pim_repository_pkg.get_by_id(id));
  END;
  FUNCTION get_image(p_image_public_id VARCHAR2) RETURN t_record IS
  BEGIN RETURN map_row(internal(p_image_public_id)); END;
  FUNCTION list_images(p_product_public_id VARCHAR2) RETURN t_table IS
    x prd_service_pkg.t_product_identity;p pim_repository_pkg.t_table;r t_table;
    i PLS_INTEGER;
  BEGIN
    x:=prd_service_pkg.resolve_product_identity(p_product_public_id);
    p:=pim_repository_pkg.list_by_product(x.product_id,'ACTIVE');i:=p.FIRST;
    WHILE i IS NOT NULL LOOP r(r.COUNT+1):=map_row(p(i));i:=p.NEXT(i);END LOOP;
    RETURN r;
  END;
  FUNCTION update_image(p_image_public_id VARCHAR2,p_store_public_id VARCHAR2,
    p_patch pim_rule_pkg.t_image_patch,p_actor_id NUMBER) RETURN t_record IS
    r pim_repository_pkg.t_row;x prd_service_pkg.t_product_identity;
    p pim_rule_pkg.t_image_patch:=p_patch;ok BOOLEAN;
  BEGIN
    r:=internal(p_image_public_id);
    x:=prd_service_pkg.resolve_catalog_product_identity(
      prd_service_pkg.resolve_product_public_id(r.prd_id),p_store_public_id,p_actor_id);
    pim_repository_pkg.lock_by_id(r.pim_id);
    BEGIN pim_rule_pkg.validate_patch(p);
    EXCEPTION WHEN pim_rule_pkg.e_empty_patch THEN RAISE e_empty_patch;
      WHEN pim_rule_pkg.e_invalid_url OR pim_rule_pkg.e_invalid_alt_text
       OR pim_rule_pkg.e_invalid_sort_order OR pim_rule_pkg.e_invalid_primary
      THEN RAISE e_invalid_image; END;
    IF yes(p.set_url) THEN r.pim_url:=p.url_value;END IF;
    IF yes(p.set_alt_text) THEN r.pim_alt_text:=p.alt_text_value;END IF;
    IF yes(p.set_sort_order) THEN r.pim_sort_order:=p.sort_order_value;END IF;
    IF yes(p.set_is_primary) THEN
      IF p.is_primary_value=1 THEN
        pim_repository_pkg.clear_primary(r.prd_id,r.pim_id,p_actor_id);
      END IF;r.pim_is_primary:=p.is_primary_value;
    END IF;r.pim_updated_by:=p_actor_id;pim_repository_pkg.update_row(r,ok);
    RETURN map_row(pim_repository_pkg.get_by_id(r.pim_id));
  END;
  FUNCTION deactivate_image(p_image_public_id VARCHAR2,p_store_public_id VARCHAR2,
    p_actor_id NUMBER) RETURN t_record IS r pim_repository_pkg.t_row;
    x prd_service_pkg.t_product_identity;ok BOOLEAN;
  BEGIN
    r:=internal(p_image_public_id);
    x:=prd_service_pkg.resolve_catalog_product_identity(
      prd_service_pkg.resolve_product_public_id(r.prd_id),p_store_public_id,p_actor_id);
    pim_repository_pkg.lock_by_id(r.pim_id);
    pim_repository_pkg.update_status(r.pim_id,'INACTIVE',p_actor_id,ok);
    RETURN map_row(pim_repository_pkg.get_by_id(r.pim_id));
  END;
END pim_service_pkg;
/
