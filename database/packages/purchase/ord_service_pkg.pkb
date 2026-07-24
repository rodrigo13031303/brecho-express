CREATE OR REPLACE PACKAGE BODY ord_service_pkg AS
  FUNCTION get_internal(p_public VARCHAR2) RETURN ord_repository_pkg.t_order IS r ord_repository_pkg.t_order;
  BEGIN BEGIN r:=ord_repository_pkg.by_public(p_public);EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_found;END;RETURN r;END;
  FUNCTION item_internal(p_public VARCHAR2) RETURN ord_repository_pkg.t_item IS r ord_repository_pkg.t_item;
  BEGIN BEGIN r:=ord_repository_pkg.item_by_public(p_public);EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_found;END;RETURN r;END;
  FUNCTION map_order(o ord_repository_pkg.t_order) RETURN t_record IS r t_record;
    xs ord_repository_pkg.t_items;i PLS_INTEGER;p BEX_PROFILE%ROWTYPE;s str_service_pkg.t_store_record;
  BEGIN p:=pfl_service_pkg.get_by_id(o.pfl_id);r.order_public_id:=o.ord_public_id;r.order_number:=o.ord_number;
    r.profile_public_id:=p.pfl_public_id;r.subtotal_amount:=o.ord_subtotal_amount;r.discount_amount:=o.ord_discount_amount;
    r.shipping_amount:=o.ord_shipping_amount;r.total_amount:=o.ord_total_amount;r.status:=o.ord_status;
    r.paid_at:=o.ord_paid_at;r.created_at:=o.ord_created_at;xs:=ord_repository_pkg.list_items(o.ord_id);i:=xs.FIRST;
    WHILE i IS NOT NULL LOOP r.items(r.items.COUNT+1).item_public_id:=xs(i).ori_public_id;
      r.items(r.items.COUNT).product_public_id:=prd_service_pkg.resolve_product_public_id(xs(i).prd_id);
      s:=str_service_pkg.get_store_by_id(xs(i).str_id);r.items(r.items.COUNT).store_public_id:=s.store_public_id;
      r.items(r.items.COUNT).quantity:=xs(i).ori_quantity;r.items(r.items.COUNT).unit_price:=xs(i).ori_unit_price;
      r.items(r.items.COUNT).discount_amount:=xs(i).ori_discount_amount;
      r.items(r.items.COUNT).total_price:=xs(i).ori_total_price;i:=xs.NEXT(i);END LOOP;RETURN r;END;
  FUNCTION create_paid_order(p_request_public VARCHAR2,p_discount NUMBER,p_shipping NUMBER,
    p_paid_at TIMESTAMP,p_actor NUMBER) RETURN t_record IS src pur_service_pkg.t_order_source;
    o ord_repository_pkg.t_order;it ord_repository_pkg.t_item;i PLS_INTEGER;id NUMBER;dummy NUMBER;
  BEGIN src:=pur_service_pkg.get_order_source(p_request_public);o.ord_subtotal_amount:=0;i:=src.items.FIRST;
    WHILE i IS NOT NULL LOOP o.ord_subtotal_amount:=o.ord_subtotal_amount+
      src.items(i).quantity*src.items(i).unit_price;i:=src.items.NEXT(i);END LOOP;
    o.ord_discount_amount:=NVL(p_discount,0);o.ord_shipping_amount:=NVL(p_shipping,0);
    o.ord_total_amount:=o.ord_subtotal_amount-o.ord_discount_amount+o.ord_shipping_amount;
    BEGIN ord_rule_pkg.validate_amounts(o.ord_subtotal_amount,o.ord_discount_amount,o.ord_shipping_amount,o.ord_total_amount);
    EXCEPTION WHEN ord_rule_pkg.e_invalid_amount THEN RAISE e_invalid;END;
    o.ord_public_id:=LOWER(RAWTOHEX(SYS_GUID()));o.pur_id:=src.request_id;o.pfl_id:=src.profile_id;
    o.ord_number:='BEX-'||TO_CHAR(SYSTIMESTAMP,'YYYYMMDDHH24MISSFF3')||'-'||UPPER(SUBSTR(RAWTOHEX(SYS_GUID()),1,6));
    o.ord_paid_at:=NVL(p_paid_at,SYSTIMESTAMP);
    BEGIN ord_repository_pkg.insert_order(o,p_actor,id);EXCEPTION WHEN DUP_VAL_ON_INDEX THEN RAISE e_conflict;END;
    i:=src.items.FIRST;WHILE i IS NOT NULL LOOP it.ori_public_id:=LOWER(RAWTOHEX(SYS_GUID()));it.ord_id:=id;
      it.prd_id:=src.items(i).product_id;it.str_id:=src.items(i).store_id;it.ori_quantity:=src.items(i).quantity;
      it.ori_unit_price:=src.items(i).unit_price;it.ori_discount_amount:=0;
      it.ori_total_price:=it.ori_quantity*it.ori_unit_price;ord_repository_pkg.insert_item(it,p_actor,dummy);
      i:=src.items.NEXT(i);END LOOP;RETURN map_order(ord_repository_pkg.by_id(id));END;
  FUNCTION get_order(p_public VARCHAR2,p_actor NUMBER) RETURN t_record IS o ord_repository_pkg.t_order;p BEX_PROFILE%ROWTYPE;
  BEGIN o:=get_internal(p_public);BEGIN p:=pfl_service_pkg.get_by_account_id(p_actor);EXCEPTION WHEN OTHERS THEN RAISE e_forbidden;END;
    IF p.pfl_id<>o.pfl_id THEN RAISE e_forbidden;END IF;RETURN map_order(o);END;
  FUNCTION change_status_internal(p_public VARCHAR2,p_status VARCHAR2,p_actor NUMBER) RETURN t_record IS o ord_repository_pkg.t_order;
  BEGIN o:=get_internal(p_public);BEGIN ord_rule_pkg.validate_transition(o.ord_status,UPPER(TRIM(p_status)));
    EXCEPTION WHEN ord_rule_pkg.e_invalid_transition THEN RAISE e_invalid;END;
    ord_repository_pkg.update_status(o.ord_id,UPPER(TRIM(p_status)),p_actor);RETURN map_order(ord_repository_pkg.by_id(o.ord_id));END;
END ord_service_pkg;
/
