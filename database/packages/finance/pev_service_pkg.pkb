CREATE OR REPLACE PACKAGE BODY pev_service_pkg AS
  FUNCTION result(e pev_repository_pkg.t_row,p pay_service_pkg.t_record) RETURN t_result IS r t_result;
  BEGIN r.event_public_id:=e.pev_public_id;r.event_type:=e.pev_event_type;
    r.external_event_id:=e.pev_external_event_id;r.event_status:=e.pev_status;r.payment:=p;RETURN r;END;
  FUNCTION process_event(p_payment_public VARCHAR2,p_type VARCHAR2,p_external VARCHAR2,
    p_at TIMESTAMP,p_payload CLOB,p_actor NUMBER) RETURN t_result IS
    p pay_repository_pkg.t_row;e pev_repository_pkg.t_row;id NUMBER;pr pay_service_pkg.t_record;
  BEGIN BEGIN pev_rule_pkg.validate_event(p_type,p_external,p_at,p_payload);
    EXCEPTION WHEN pev_rule_pkg.e_invalid THEN RAISE e_invalid;END;
    BEGIN p:=pay_service_pkg.get_internal(p_payment_public);
    EXCEPTION WHEN pay_service_pkg.e_not_found THEN RAISE e_payment_not_found;END;
    BEGIN e:=pev_repository_pkg.by_external(p.pay_id,TRIM(p_external));
      pr:=pay_service_pkg.get_by_id_internal(p.pay_id);RETURN result(e,pr);
    EXCEPTION WHEN NO_DATA_FOUND THEN NULL;END;
    e.pev_public_id:=LOWER(RAWTOHEX(SYS_GUID()));e.pay_id:=p.pay_id;e.pev_event_type:=UPPER(TRIM(p_type));
    e.pev_external_event_id:=TRIM(p_external);e.pev_event_at:=p_at;e.pev_raw_payload:=p_payload;
    BEGIN pev_repository_pkg.insert_row(e,p_actor,id);EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
      e:=pev_repository_pkg.by_external(p.pay_id,TRIM(p_external));
      pr:=pay_service_pkg.get_by_id_internal(p.pay_id);RETURN result(e,pr);END;
    BEGIN pr:=pay_service_pkg.apply_event(p.pay_id,p_type,p_actor);
      pev_repository_pkg.update_status(id,'PROCESSED',p_actor);
    EXCEPTION WHEN pay_service_pkg.e_invalid THEN
      pev_repository_pkg.update_status(id,'IGNORED',p_actor);pr:=pay_service_pkg.get_by_id_internal(p.pay_id);
    END;
    e:=pev_repository_pkg.by_id(id);RETURN result(e,pr);END;
END pev_service_pkg;
/
