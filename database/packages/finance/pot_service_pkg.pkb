CREATE OR REPLACE PACKAGE BODY pot_service_pkg AS
  FUNCTION map_row(p pot_repository_pkg.t_row) RETURN t_record IS r t_record;s str_service_pkg.t_store_record;
  BEGIN s:=str_service_pkg.get_store_by_id(p.str_id);r.payout_public_id:=p.pot_public_id;r.store_public_id:=s.store_public_id;
    r.amount:=p.pot_amount;r.pix_key:=p.pot_pix_key;r.pix_key_type:=p.pot_pix_key_type;r.status:=p.pot_status;
    r.requested_at:=p.pot_requested_at;r.approved_at:=p.pot_approved_at;r.paid_at:=p.pot_paid_at;
    r.rejected_at:=p.pot_rejected_at;r.reject_reason:=p.pot_reject_reason;RETURN r;END;
  FUNCTION request_payout(p_store VARCHAR2,p_amount NUMBER,p_key VARCHAR2,p_type VARCHAR2,p_actor NUMBER) RETURN t_record IS
    p pot_repository_pkg.t_row;id NUMBER;
  BEGIN BEGIN pot_rule_pkg.validate_request(p_amount,p_key,p_type);EXCEPTION WHEN pot_rule_pkg.e_invalid THEN RAISE e_invalid;END;
    p.str_id:=str_service_pkg.resolve_catalog_store_id(p_store,p_actor);
    sbt_service_pkg.lock_store(p.str_id);
    IF sbt_service_pkg.available_balance(p.str_id)<p_amount THEN RAISE e_insufficient;END IF;
    p.pot_public_id:=LOWER(RAWTOHEX(SYS_GUID()));p.pot_amount:=p_amount;p.pot_pix_key:=TRIM(p_key);
    p.pot_pix_key_type:=UPPER(TRIM(p_type));pot_repository_pkg.insert_row(p,p_actor,id);
    sbt_service_pkg.post(p.str_id,NULL,NULL,id,'PAYOUT_RESERVE',p_amount,'DEBIT',SYSTIMESTAMP,'Payout reserve',p_actor);
    RETURN map_row(pot_repository_pkg.by_id(id));END;
  FUNCTION get_payout(p_public VARCHAR2,p_actor NUMBER) RETURN t_record IS p pot_repository_pkg.t_row;d NUMBER;s str_service_pkg.t_store_record;
  BEGIN BEGIN p:=pot_repository_pkg.by_public(p_public);EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_found;END;
    s:=str_service_pkg.get_store_by_id(p.str_id);BEGIN d:=str_service_pkg.resolve_catalog_store_id(s.store_public_id,p_actor);
    EXCEPTION WHEN str_service_pkg.e_catalog_forbidden THEN RAISE e_forbidden;END;RETURN map_row(p);END;
  FUNCTION change_state_internal(p_public VARCHAR2,p_status VARCHAR2,p_reason VARCHAR2,p_actor NUMBER) RETURN t_record IS p pot_repository_pkg.t_row;
  BEGIN BEGIN p:=pot_repository_pkg.by_public(p_public);EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_found;END;
    pot_repository_pkg.lock_row(p.pot_id);p:=pot_repository_pkg.by_id(p.pot_id);
    BEGIN pot_rule_pkg.validate_transition(p.pot_status,p_status,p_reason);
    EXCEPTION WHEN pot_rule_pkg.e_invalid_transition THEN RAISE e_invalid;END;
    pot_repository_pkg.update_state(p.pot_id,UPPER(TRIM(p_status)),p_reason,p_actor);
    IF UPPER(TRIM(p_status))='REJECTED' THEN sbt_service_pkg.post(p.str_id,NULL,NULL,p.pot_id,
      'PAYOUT_RESTORE',p.pot_amount,'CREDIT',SYSTIMESTAMP,'Rejected payout restored',p_actor);
    ELSIF UPPER(TRIM(p_status))='PAID' THEN sbt_service_pkg.post(p.str_id,NULL,NULL,p.pot_id,
      'PAYOUT_PAID',p.pot_amount,'DEBIT',SYSTIMESTAMP,'Payout paid',p_actor);END IF;
    RETURN map_row(pot_repository_pkg.by_id(p.pot_id));END;
END pot_service_pkg;
/
