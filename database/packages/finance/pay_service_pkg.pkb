CREATE OR REPLACE PACKAGE BODY pay_service_pkg AS
  FUNCTION get_internal(p_public VARCHAR2) RETURN pay_repository_pkg.t_row IS r pay_repository_pkg.t_row;
  BEGIN BEGIN r:=pay_repository_pkg.by_public(p_public);EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_found;END;RETURN r;END;
  FUNCTION map_row(p pay_repository_pkg.t_row) RETURN t_record IS r t_record;o ord_repository_pkg.t_order;
  BEGIN r.payment_public_id:=p.pay_public_id;r.request_public_id:=pur_service_pkg.request_public_id_by_id(p.pur_id);
    r.provider_public_id:=ppr_service_pkg.public_id_by_id(p.ppr_id);IF p.ord_id IS NOT NULL THEN
      o:=ord_repository_pkg.by_id(p.ord_id);r.order_public_id:=o.ord_public_id;END IF;
    r.external_id:=p.pay_external_id;r.amount:=p.pay_amount;r.method:=p.pay_method;
    r.status:=p.pay_status;r.approved_at:=p.pay_approved_at;r.created_at:=p.pay_created_at;RETURN r;END;
  FUNCTION create_payment(p_request_public VARCHAR2,p_provider_public VARCHAR2,p_external VARCHAR2,
    p_method VARCHAR2,p_actor NUMBER) RETURN t_record IS src pur_service_pkg.t_order_source;
    p pay_repository_pkg.t_row;i PLS_INTEGER;id NUMBER;
  BEGIN src:=pur_service_pkg.get_order_source(p_request_public);p.pay_amount:=0;i:=src.items.FIRST;
    WHILE i IS NOT NULL LOOP p.pay_amount:=p.pay_amount+src.items(i).quantity*src.items(i).unit_price;i:=src.items.NEXT(i);END LOOP;
    BEGIN pay_rule_pkg.validate_creation(p.pay_amount,p_method);EXCEPTION WHEN pay_rule_pkg.e_invalid THEN RAISE e_invalid;END;
    IF TRIM(p_external) IS NULL OR LENGTH(TRIM(p_external))>100 THEN RAISE e_invalid;END IF;
    p.pay_public_id:=LOWER(RAWTOHEX(SYS_GUID()));p.pur_id:=src.request_id;
    p.ppr_id:=ppr_service_pkg.resolve_active_id(p_provider_public);p.pay_external_id:=TRIM(p_external);
    p.pay_method:=UPPER(TRIM(p_method));BEGIN pay_repository_pkg.insert_row(p,p_actor,id);
    EXCEPTION WHEN DUP_VAL_ON_INDEX THEN RAISE e_conflict;END;RETURN map_row(pay_repository_pkg.by_id(id));END;
  FUNCTION get_payment(p_public VARCHAR2,p_actor NUMBER) RETURN t_record IS p pay_repository_pkg.t_row;
    src pur_service_pkg.t_order_source;pr BEX_PROFILE%ROWTYPE;
  BEGIN p:=get_internal(p_public);src:=pur_service_pkg.get_order_source(pur_service_pkg.request_public_id_by_id(p.pur_id));
    BEGIN pr:=pfl_service_pkg.get_by_account_id(p_actor);EXCEPTION WHEN OTHERS THEN RAISE e_forbidden;END;
    IF pr.pfl_id<>src.profile_id THEN RAISE e_forbidden;END IF;RETURN map_row(p);END;
  FUNCTION get_by_id_internal(p_id NUMBER) RETURN t_record IS p pay_repository_pkg.t_row;
  BEGIN BEGIN p:=pay_repository_pkg.by_id(p_id);EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_found;END;
    RETURN map_row(p);END;
  FUNCTION apply_event(p_id NUMBER,p_event_type VARCHAR2,p_actor NUMBER) RETURN t_record IS
    p pay_repository_pkg.t_row;n VARCHAR2(20);o ord_service_pkg.t_record;oi ord_repository_pkg.t_order;
  BEGIN pay_repository_pkg.lock_row(p_id);p:=pay_repository_pkg.by_id(p_id);
    BEGIN pay_rule_pkg.validate_event(p.pay_status,p_event_type,n);
    EXCEPTION WHEN pay_rule_pkg.e_invalid_transition THEN RAISE e_invalid;END;
    IF n='APPROVED' THEN o:=ord_service_pkg.create_paid_order(
      pur_service_pkg.request_public_id_by_id(p.pur_id),0,0,SYSTIMESTAMP,p_actor);
      oi:=ord_service_pkg.get_internal(o.order_public_id);pay_repository_pkg.update_state(p.pay_id,n,oi.ord_id,p_actor);
    ELSE pay_repository_pkg.update_state(p.pay_id,n,NULL,p_actor);END IF;
    RETURN map_row(pay_repository_pkg.by_id(p.pay_id));END;
END pay_service_pkg;
/
