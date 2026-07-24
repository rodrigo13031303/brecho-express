CREATE OR REPLACE PACKAGE BODY shp_service_pkg AS
  FUNCTION internal(p VARCHAR2) RETURN shp_repository_pkg.t_row IS r shp_repository_pkg.t_row;
  BEGIN BEGIN r:=shp_repository_pkg.by_public(p);EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_found;END;RETURN r;END;
  FUNCTION map_row(s shp_repository_pkg.t_row) RETURN t_record IS r t_record;
    o ord_repository_pkg.t_order;st str_service_pkg.t_store_record;a adr_repository_pkg.t_row;
    xs shp_repository_pkg.t_items;i PLS_INTEGER;oi ord_repository_pkg.t_item;
  BEGIN o:=ord_repository_pkg.by_id(s.ord_id);st:=str_service_pkg.get_store_by_id(s.str_id);
    a:=adr_repository_pkg.by_id(s.adr_id);
    r.shipment_public_id:=s.shp_public_id;r.order_public_id:=o.ord_public_id;r.store_public_id:=st.store_public_id;
    r.address_public_id:=a.adr_public_id;r.delivery_profile_public_id:=dlp_service_pkg.public_id_by_id(s.dlp_id);
    r.tracking_code:=s.shp_tracking_code;r.estimated_delivery_at:=s.shp_estimated_delivery_at;
    r.delivered_at:=s.shp_delivered_at;r.status:=s.shp_status;xs:=shp_repository_pkg.list_items(s.shp_id);i:=xs.FIRST;
    WHILE i IS NOT NULL LOOP oi:=ord_repository_pkg.item_by_id(xs(i).ori_id);
      r.items(r.items.COUNT+1).item_public_id:=xs(i).shi_public_id;r.items(r.items.COUNT).order_item_public_id:=oi.ori_public_id;
      r.items(r.items.COUNT).product_public_id:=prd_service_pkg.resolve_product_public_id(xs(i).prd_id);
      r.items(r.items.COUNT).quantity:=xs(i).shi_quantity;r.items(r.items.COUNT).status:=xs(i).shi_status;i:=xs.NEXT(i);END LOOP;RETURN r;END;
  FUNCTION create_shipment(p_order_public VARCHAR2,p_store_public VARCHAR2,p_address_public VARCHAR2,
    p_delivery_public VARCHAR2,p_items t_public_ids,p_estimated TIMESTAMP,p_actor NUMBER) RETURN t_record IS
    o ord_repository_pkg.t_order;s shp_repository_pkg.t_row;it shp_repository_pkg.t_item;
    oi ord_repository_pkg.t_item;id NUMBER;dummy NUMBER;i PLS_INTEGER;
  BEGIN o:=ord_service_pkg.get_internal(p_order_public);s.str_id:=str_service_pkg.resolve_catalog_store_id(p_store_public,p_actor);
    s.adr_id:=adr_service_pkg.resolve_active_id(p_address_public,o.pfl_id);s.dlp_id:=dlp_service_pkg.resolve_active_id(p_delivery_public);
    IF p_items.COUNT=0 OR o.ord_status NOT IN('PAID','PROCESSING') THEN RAISE e_invalid;END IF;
    s.shp_public_id:=LOWER(RAWTOHEX(SYS_GUID()));s.ord_id:=o.ord_id;s.shp_estimated_delivery_at:=p_estimated;
    shp_repository_pkg.insert_row(s,p_actor,id);i:=p_items.FIRST;
    WHILE i IS NOT NULL LOOP oi:=ord_service_pkg.item_internal(p_items(i));
      IF oi.ord_id<>o.ord_id OR oi.str_id<>s.str_id OR oi.ori_status<>'ACTIVE' THEN RAISE e_invalid;END IF;
      it.shi_public_id:=LOWER(RAWTOHEX(SYS_GUID()));it.shp_id:=id;it.ori_id:=oi.ori_id;
      it.prd_id:=oi.prd_id;it.shi_quantity:=oi.ori_quantity;
      BEGIN shp_repository_pkg.insert_item(it,p_actor,dummy);EXCEPTION WHEN DUP_VAL_ON_INDEX THEN RAISE e_conflict;END;
      i:=p_items.NEXT(i);END LOOP;RETURN map_row(shp_repository_pkg.by_id(id));END;
  FUNCTION get_shipment(p_public VARCHAR2,p_actor NUMBER) RETURN t_record IS
    s shp_repository_pkg.t_row;d NUMBER;st str_service_pkg.t_store_record;
  BEGIN s:=internal(p_public);st:=str_service_pkg.get_store_by_id(s.str_id);
    d:=str_service_pkg.resolve_catalog_store_id(st.store_public_id,p_actor);RETURN map_row(s);
  EXCEPTION WHEN str_service_pkg.e_catalog_forbidden THEN RAISE e_forbidden;END;
  FUNCTION change_status(p_public VARCHAR2,p_status VARCHAR2,p_tracking VARCHAR2,p_actor NUMBER) RETURN t_record IS
    s shp_repository_pkg.t_row;d NUMBER;st str_service_pkg.t_store_record;
  BEGIN s:=internal(p_public);st:=str_service_pkg.get_store_by_id(s.str_id);
    d:=str_service_pkg.resolve_catalog_store_id(st.store_public_id,p_actor);
    BEGIN shp_rule_pkg.validate_transition(s.shp_status,p_status);EXCEPTION WHEN shp_rule_pkg.e_invalid_transition THEN RAISE e_invalid;END;
    shp_repository_pkg.update_status(s.shp_id,UPPER(TRIM(p_status)),TRIM(p_tracking),p_actor);
    RETURN map_row(shp_repository_pkg.by_id(s.shp_id));
  EXCEPTION WHEN str_service_pkg.e_catalog_forbidden THEN RAISE e_forbidden;END;
END shp_service_pkg;
/
