CREATE OR REPLACE PACKAGE BODY ste_service_pkg AS
  FUNCTION create_event(p_store VARCHAR2,p_name VARCHAR2,p_description VARCHAR2,p_start TIMESTAMP,p_end TIMESTAMP,p_actor NUMBER)RETURN t_record IS
    r t_record;id NUMBER;BEGIN BEGIN ste_rule_pkg.validate_event(p_name,p_description,p_start,p_end);EXCEPTION WHEN ste_rule_pkg.e_invalid THEN RAISE e_invalid;END;
    BEGIN r.store_id:=str_service_pkg.resolve_catalog_store_id(p_store,p_actor);EXCEPTION WHEN OTHERS THEN RAISE e_forbidden;END;
    r.public_id:=LOWER(RAWTOHEX(SYS_GUID()));r.event_name:=TRIM(p_name);r.description:=TRIM(p_description);r.start_at:=p_start;r.end_at:=p_end;
    ste_repository_pkg.insert_row(r,p_actor,id);RETURN ste_repository_pkg.by_id(id);END;
  FUNCTION list_events(p_store VARCHAR2)RETURN t_records IS BEGIN RETURN ste_repository_pkg.list_store(str_service_pkg.resolve_store_id(p_store));
    EXCEPTION WHEN OTHERS THEN RAISE e_not_found;END;
  FUNCTION change_status(p_public VARCHAR2,p_status VARCHAR2,p_actor NUMBER)RETURN t_record IS r t_record;s str_service_pkg.t_store_record;n VARCHAR2(20):=UPPER(TRIM(p_status));
  BEGIN BEGIN r:=ste_repository_pkg.by_public(p_public);EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_found;END;s:=str_service_pkg.get_store_by_id(r.store_id);
    BEGIN IF str_service_pkg.resolve_catalog_store_id(s.store_public_id,p_actor)<>r.store_id THEN RAISE e_forbidden;END IF;EXCEPTION WHEN OTHERS THEN RAISE e_forbidden;END;
    BEGIN ste_rule_pkg.validate_transition(r.status,n);EXCEPTION WHEN ste_rule_pkg.e_invalid_transition THEN RAISE e_invalid;END;
    ste_repository_pkg.update_status(r.id,n,p_actor);RETURN ste_repository_pkg.by_id(r.id);END;
END ste_service_pkg;
/
