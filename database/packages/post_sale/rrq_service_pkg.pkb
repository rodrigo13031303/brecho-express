CREATE OR REPLACE PACKAGE BODY rrq_service_pkg AS
  FUNCTION profile(p_actor NUMBER)RETURN BEX_PROFILE%ROWTYPE IS p BEX_PROFILE%ROWTYPE;BEGIN
    BEGIN p:=pfl_service_pkg.get_by_account_id(p_actor);EXCEPTION WHEN OTHERS THEN RAISE e_forbidden;END;RETURN p;END;
  FUNCTION get_internal(p_public VARCHAR2)RETURN t_record IS r t_record;BEGIN BEGIN r:=rrq_repository_pkg.by_public(p_public);
    EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_found;END;RETURN r;END;
  FUNCTION open_request(p_order VARCHAR2,p_store VARCHAR2,p_reason VARCHAR2,p_description VARCHAR2,p_actor NUMBER)RETURN t_record IS
    src ord_service_pkg.t_post_sale_source;p BEX_PROFILE%ROWTYPE;r t_record;id NUMBER;
  BEGIN BEGIN rrq_rule_pkg.validate_open(p_reason,p_description);EXCEPTION WHEN rrq_rule_pkg.e_invalid THEN RAISE e_invalid;END;
    src:=ord_service_pkg.post_sale_source(p_order,p_store);p:=profile(p_actor);
    IF src.status<>'COMPLETED' OR p.pfl_id<>src.profile_id THEN RAISE e_forbidden;END IF;
    r.rrq_public_id:=LOWER(RAWTOHEX(SYS_GUID()));r.ord_id:=src.order_id;r.str_id:=src.store_id;r.pfl_id:=p.pfl_id;
    r.reason_code:=UPPER(TRIM(p_reason));r.description:=TRIM(p_description);r.priority:='NORMAL';r.severity:='NORMAL';r.source:='CUSTOMER';
    rrq_repository_pkg.insert_row(r,p.pfl_id,id);RETURN rrq_repository_pkg.by_id(id);END;
  FUNCTION get_request(p_public VARCHAR2,p_actor NUMBER)RETURN t_record IS r t_record;p BEX_PROFILE%ROWTYPE;
  BEGIN r:=get_internal(p_public);p:=profile(p_actor);IF r.pfl_id<>p.pfl_id THEN RAISE e_forbidden;END IF;RETURN r;END;
  FUNCTION list_store(p_store VARCHAR2,p_actor NUMBER)RETURN t_records IS id NUMBER;BEGIN
    id:=str_service_pkg.resolve_catalog_store_id(p_store,p_actor);RETURN rrq_repository_pkg.list_by_store(id);
    EXCEPTION WHEN OTHERS THEN RAISE e_forbidden;END;
  FUNCTION respond(p_public VARCHAR2,p_response VARCHAR2,p_actor NUMBER)RETURN t_record IS r t_record;s str_service_pkg.t_store_record;p BEX_PROFILE%ROWTYPE;
  BEGIN r:=get_internal(p_public);s:=str_service_pkg.get_store_by_id(r.str_id);
    IF str_service_pkg.resolve_catalog_store_id(s.store_public_id,p_actor)<>r.str_id OR TRIM(p_response)IS NULL OR LENGTH(p_response)>2000 THEN RAISE e_forbidden;END IF;
    p:=profile(p_actor);rrq_repository_pkg.update_response(r.rrq_id,p_response,p.pfl_id);RETURN rrq_repository_pkg.by_id(r.rrq_id);END;
  FUNCTION change_state_internal(p_public VARCHAR2,p_status VARCHAR2,p_result VARCHAR2,p_actor NUMBER)RETURN t_record IS
    r t_record;p BEX_PROFILE%ROWTYPE;n VARCHAR2(20):=UPPER(TRIM(p_status));
  BEGIN r:=get_internal(p_public);p:=profile(p_actor);BEGIN rrq_rule_pkg.validate_transition(r.status,n,p_result);
    EXCEPTION WHEN rrq_rule_pkg.e_invalid_transition THEN RAISE e_invalid;END;
    rrq_repository_pkg.update_state(r.rrq_id,n,UPPER(TRIM(p_result)),p.pfl_id,p.pfl_id);RETURN rrq_repository_pkg.by_id(r.rrq_id);END;
END rrq_service_pkg;
/
