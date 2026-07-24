CREATE OR REPLACE PACKAGE BODY pur_service_pkg AS
  FUNCTION map_item(x pur_repository_pkg.t_item) RETURN t_item_record IS r t_item_record;
    s str_service_pkg.t_store_record;
  BEGIN r.item_public_id:=x.pri_public_id;
    r.product_public_id:=prd_service_pkg.resolve_product_public_id(x.prd_id);
    s:=str_service_pkg.get_store_by_id(x.str_id);r.store_public_id:=s.store_public_id;
    r.requested_quantity:=x.pri_requested_quantity;r.confirmed_quantity:=x.pri_confirmed_quantity;
    r.unit_price:=x.pri_unit_price;r.reject_reason:=x.pri_reject_reason;r.status:=x.pri_status;RETURN r;END;
  FUNCTION map_request(x pur_repository_pkg.t_request) RETURN t_record IS r t_record;
    p BEX_PROFILE%ROWTYPE;xs pur_repository_pkg.t_items;i PLS_INTEGER;
  BEGIN p:=pfl_service_pkg.get_by_id(x.pfl_id);r.request_public_id:=x.pur_public_id;
    r.profile_public_id:=p.pfl_public_id;r.status:=x.pur_status;r.requested_at:=x.pur_requested_at;
    r.confirmed_at:=x.pur_confirmed_at;r.response_at:=x.pur_response_at;r.expires_at:=x.pur_expires_at;
    xs:=pur_repository_pkg.list_items(x.pur_id);i:=xs.FIRST;
    WHILE i IS NOT NULL LOOP r.items(r.items.COUNT+1):=map_item(xs(i));i:=xs.NEXT(i);END LOOP;RETURN r;END;
  FUNCTION internal(p VARCHAR2) RETURN pur_repository_pkg.t_request IS r pur_repository_pkg.t_request;
  BEGIN BEGIN r:=pur_repository_pkg.get_request_by_public(p);
    EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_request_not_found;END;RETURN r;END;
  FUNCTION checkout(p_cart_public_id VARCHAR2,p_actor_id NUMBER) RETURN t_record IS
    c crt_service_pkg.t_checkout;rid NUMBER;i PLS_INTEGER;dummy NUMBER;
  BEGIN c:=crt_service_pkg.prepare_checkout(p_cart_public_id,p_actor_id);
    pur_repository_pkg.insert_request(LOWER(RAWTOHEX(SYS_GUID())),c.profile_id,
      SYSTIMESTAMP + INTERVAL '48' HOUR,p_actor_id,rid);i:=c.items.FIRST;
    WHILE i IS NOT NULL LOOP pur_repository_pkg.insert_item(LOWER(RAWTOHEX(SYS_GUID())),
      rid,c.items(i).product_id,c.items(i).store_id,c.items(i).requested_quantity,
      c.items(i).unit_price,p_actor_id,dummy);i:=c.items.NEXT(i);END LOOP;
    crt_service_pkg.complete_checkout(c.cart_id,p_actor_id);
    RETURN map_request(pur_repository_pkg.get_request_by_id(rid));END;
  FUNCTION get_request(p_public_id VARCHAR2,p_actor_id NUMBER) RETURN t_record IS
    r pur_repository_pkg.t_request;p BEX_PROFILE%ROWTYPE;
  BEGIN r:=internal(p_public_id);BEGIN p:=pfl_service_pkg.get_by_account_id(p_actor_id);
    EXCEPTION WHEN pfl_service_pkg.e_profile_not_found THEN RAISE e_forbidden;END;
    IF r.pfl_id<>p.pfl_id THEN RAISE e_forbidden;END IF;RETURN map_request(r);END;
  PROCEDURE recalc(p_id NUMBER,p_actor NUMBER) IS xs pur_repository_pkg.t_items;
    i PLS_INTEGER;pending NUMBER:=0;approved NUMBER:=0;rejected NUMBER:=0;partial NUMBER:=0;s VARCHAR2(30);
  BEGIN xs:=pur_repository_pkg.list_items(p_id);i:=xs.FIRST;
    WHILE i IS NOT NULL LOOP CASE xs(i).pri_status WHEN 'PENDING' THEN pending:=pending+1;
      WHEN 'APPROVED' THEN approved:=approved+1;WHEN 'REJECTED' THEN rejected:=rejected+1;
      ELSE partial:=partial+1;END CASE;i:=xs.NEXT(i);END LOOP;
    IF pending>0 THEN s:='PENDING';ELSIF approved=xs.COUNT THEN s:='APPROVED';
    ELSIF rejected=xs.COUNT THEN s:='REJECTED';ELSE s:='PARTIALLY_APPROVED';END IF;
    pur_repository_pkg.update_request_status(p_id,s,p_actor);END;
  FUNCTION respond_item(p_request_public_id VARCHAR2,p_item_public_id VARCHAR2,
    p_store_public_id VARCHAR2,p_confirmed_quantity NUMBER,p_reject_reason VARCHAR2,
    p_actor_id NUMBER) RETURN t_record IS r pur_repository_pkg.t_request;
    x pur_repository_pkg.t_item;store_id NUMBER;s VARCHAR2(30);reason VARCHAR2(500);
  BEGIN r:=internal(p_request_public_id);pur_repository_pkg.lock_request(r.pur_id);
    BEGIN pur_rule_pkg.assert_pending(r.pur_status);EXCEPTION WHEN pur_rule_pkg.e_request_closed THEN RAISE e_request_closed;END;
    BEGIN x:=pur_repository_pkg.get_item_by_public(p_item_public_id);
    EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_item_not_found;END;
    IF x.pur_id<>r.pur_id THEN RAISE e_item_not_found;END IF;
    store_id:=str_service_pkg.resolve_catalog_store_id(p_store_public_id,p_actor_id);
    IF x.str_id<>store_id THEN RAISE e_forbidden;END IF;pur_repository_pkg.lock_item(x.pri_id);
    BEGIN pur_rule_pkg.validate_response(x.pri_requested_quantity,p_confirmed_quantity,
      p_reject_reason,s,reason);EXCEPTION WHEN pur_rule_pkg.e_invalid_response THEN RAISE e_invalid_response;END;
    pur_repository_pkg.respond_item(x.pri_id,p_confirmed_quantity,reason,s,p_actor_id);
    recalc(r.pur_id,p_actor_id);RETURN map_request(pur_repository_pkg.get_request_by_id(r.pur_id));END;
END pur_service_pkg;
/
