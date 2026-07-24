CREATE OR REPLACE PACKAGE BODY crt_service_pkg AS
  FUNCTION profile(p_actor NUMBER) RETURN BEX_PROFILE%ROWTYPE IS r BEX_PROFILE%ROWTYPE;
  BEGIN BEGIN r:=pfl_service_pkg.get_by_account_id(p_actor);
    EXCEPTION WHEN pfl_service_pkg.e_profile_not_found THEN RAISE e_forbidden;END;RETURN r;END;
  PROCEDURE own(c crt_repository_pkg.t_cart,p BEX_PROFILE%ROWTYPE) IS BEGIN
    IF c.pfl_id<>p.pfl_id THEN RAISE e_forbidden;END IF;END;
  FUNCTION map_item(x crt_repository_pkg.t_item) RETURN t_item_record IS r t_item_record;
    pr prd_service_pkg.t_product_record;s str_service_pkg.t_store_record;
  BEGIN r.item_public_id:=x.cti_public_id;
    r.product_public_id:=prd_service_pkg.resolve_product_public_id(x.prd_id);
    s:=str_service_pkg.get_store_by_id(x.str_id);r.store_public_id:=s.store_public_id;
    r.quantity:=x.cti_quantity;r.unit_price:=x.cti_unit_price;r.status:=x.cti_status;RETURN r;END;
  FUNCTION map_cart(c crt_repository_pkg.t_cart) RETURN t_cart_record IS r t_cart_record;
    p BEX_PROFILE%ROWTYPE;xs crt_repository_pkg.t_items;i PLS_INTEGER;
  BEGIN p:=pfl_service_pkg.get_by_id(c.pfl_id);r.cart_public_id:=c.crt_public_id;
    r.profile_public_id:=p.pfl_public_id;r.status:=c.crt_status;r.expires_at:=c.crt_expires_at;
    r.created_at:=c.crt_created_at;r.updated_at:=c.crt_updated_at;
    xs:=crt_repository_pkg.list_items(c.crt_id,'ACTIVE');i:=xs.FIRST;
    WHILE i IS NOT NULL LOOP r.items(r.items.COUNT+1):=map_item(xs(i));i:=xs.NEXT(i);END LOOP;RETURN r;END;
  FUNCTION internal(p VARCHAR2) RETURN crt_repository_pkg.t_cart IS c crt_repository_pkg.t_cart;
  BEGIN BEGIN c:=crt_repository_pkg.get_cart_by_public(p);
    EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_cart_not_found;END;RETURN c;END;
  FUNCTION get_or_create_active(p_actor_id NUMBER) RETURN t_cart_record IS p BEX_PROFILE%ROWTYPE;
    c crt_repository_pkg.t_cart;id NUMBER;
  BEGIN p:=profile(p_actor_id);BEGIN c:=crt_repository_pkg.get_active_by_profile(p.pfl_id);
    EXCEPTION WHEN NO_DATA_FOUND THEN BEGIN crt_repository_pkg.insert_cart(
      LOWER(RAWTOHEX(SYS_GUID())),p.pfl_id,SYSTIMESTAMP + INTERVAL '30' DAY,p_actor_id,id);
      EXCEPTION WHEN DUP_VAL_ON_INDEX THEN c:=crt_repository_pkg.get_active_by_profile(p.pfl_id);END;
      IF id IS NOT NULL THEN c:=crt_repository_pkg.get_cart_by_id(id);END IF;END;RETURN map_cart(c);END;
  FUNCTION get_cart(p_cart_public_id VARCHAR2,p_actor_id NUMBER) RETURN t_cart_record IS
    c crt_repository_pkg.t_cart;p BEX_PROFILE%ROWTYPE;
  BEGIN p:=profile(p_actor_id);c:=internal(p_cart_public_id);own(c,p);RETURN map_cart(c);END;
  FUNCTION add_item(p_cart_public_id VARCHAR2,p_product_public_id VARCHAR2,p_quantity NUMBER,p_actor_id NUMBER) RETURN t_cart_record IS
    c crt_repository_pkg.t_cart;p BEX_PROFILE%ROWTYPE;x prd_service_pkg.t_product_identity;id NUMBER;
  BEGIN p:=profile(p_actor_id);c:=internal(p_cart_public_id);own(c,p);
    BEGIN crt_rule_pkg.assert_editable(c.crt_status);crt_rule_pkg.validate_quantity(p_quantity);
    EXCEPTION WHEN crt_rule_pkg.e_cart_closed THEN RAISE e_cart_closed;
      WHEN crt_rule_pkg.e_invalid_quantity THEN RAISE e_invalid_quantity;END;
    x:=prd_service_pkg.resolve_available_product(p_product_public_id,p_quantity);
    BEGIN crt_repository_pkg.insert_item(LOWER(RAWTOHEX(SYS_GUID())),c.crt_id,
      x.product_id,x.store_id,p_quantity,x.unit_price,p_actor_id,id);
    EXCEPTION WHEN DUP_VAL_ON_INDEX THEN RAISE e_item_conflict;END;RETURN map_cart(c);END;
  FUNCTION item_for_cart(p_item VARCHAR2,c NUMBER) RETURN crt_repository_pkg.t_item IS x crt_repository_pkg.t_item;
  BEGIN BEGIN x:=crt_repository_pkg.get_item_by_public(p_item);
    EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_item_not_found;END;
    IF x.crt_id<>c THEN RAISE e_item_not_found;END IF;RETURN x;END;
  FUNCTION update_item(p_cart_public_id VARCHAR2,p_item_public_id VARCHAR2,p_quantity NUMBER,p_actor_id NUMBER) RETURN t_cart_record IS
    c crt_repository_pkg.t_cart;p BEX_PROFILE%ROWTYPE;i crt_repository_pkg.t_item;
    x prd_service_pkg.t_product_identity;
  BEGIN p:=profile(p_actor_id);c:=internal(p_cart_public_id);own(c,p);
    BEGIN crt_rule_pkg.assert_editable(c.crt_status);
    EXCEPTION WHEN crt_rule_pkg.e_cart_closed THEN RAISE e_cart_closed;END;
    BEGIN crt_rule_pkg.validate_quantity(p_quantity);EXCEPTION WHEN crt_rule_pkg.e_invalid_quantity THEN RAISE e_invalid_quantity;END;
    i:=item_for_cart(p_item_public_id,c.crt_id);x:=prd_service_pkg.resolve_available_product(
      prd_service_pkg.resolve_product_public_id(i.prd_id),p_quantity);
    crt_repository_pkg.update_item_qty(i.cti_id,p_quantity,x.unit_price,p_actor_id);RETURN map_cart(c);END;
  FUNCTION remove_item(p_cart_public_id VARCHAR2,p_item_public_id VARCHAR2,p_actor_id NUMBER) RETURN t_cart_record IS
    c crt_repository_pkg.t_cart;p BEX_PROFILE%ROWTYPE;i crt_repository_pkg.t_item;
  BEGIN p:=profile(p_actor_id);c:=internal(p_cart_public_id);own(c,p);
    BEGIN crt_rule_pkg.assert_editable(c.crt_status);
    EXCEPTION WHEN crt_rule_pkg.e_cart_closed THEN RAISE e_cart_closed;END;
    i:=item_for_cart(p_item_public_id,c.crt_id);crt_repository_pkg.update_item_status(i.cti_id,'REMOVED',p_actor_id);RETURN map_cart(c);END;
  FUNCTION prepare_checkout(p_cart_public_id VARCHAR2,p_actor_id NUMBER) RETURN t_checkout IS
    c crt_repository_pkg.t_cart;p BEX_PROFILE%ROWTYPE;xs crt_repository_pkg.t_items;
    r t_checkout;i PLS_INTEGER;x prd_service_pkg.t_product_identity;
  BEGIN p:=profile(p_actor_id);c:=internal(p_cart_public_id);own(c,p);crt_repository_pkg.lock_cart(c.crt_id);
    BEGIN crt_rule_pkg.assert_editable(c.crt_status);EXCEPTION WHEN crt_rule_pkg.e_cart_closed THEN RAISE e_cart_closed;END;
    xs:=crt_repository_pkg.list_items(c.crt_id,'ACTIVE');IF xs.COUNT=0 THEN RAISE e_empty_cart;END IF;
    r.cart_id:=c.crt_id;r.profile_id:=c.pfl_id;i:=xs.FIRST;
    WHILE i IS NOT NULL LOOP x:=prd_service_pkg.resolve_available_product(
      prd_service_pkg.resolve_product_public_id(xs(i).prd_id),xs(i).cti_quantity);
      r.items(r.items.COUNT+1).product_id:=x.product_id;
      r.items(r.items.COUNT).store_id:=x.store_id;
      r.items(r.items.COUNT).requested_quantity:=xs(i).cti_quantity;
      r.items(r.items.COUNT).unit_price:=x.unit_price;i:=xs.NEXT(i);END LOOP;RETURN r;END;
  PROCEDURE complete_checkout(p_cart_id NUMBER,p_actor_id NUMBER) IS
  BEGIN crt_repository_pkg.update_cart_status(p_cart_id,'CHECKED_OUT',p_actor_id);END;
END crt_service_pkg;
/
