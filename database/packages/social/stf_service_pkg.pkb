CREATE OR REPLACE PACKAGE BODY stf_service_pkg AS
  FUNCTION actor_profile(p_actor NUMBER)RETURN BEX_PROFILE%ROWTYPE IS p BEX_PROFILE%ROWTYPE;BEGIN
    BEGIN p:=pfl_service_pkg.get_by_account_id(p_actor);EXCEPTION WHEN OTHERS THEN RAISE e_forbidden;END;RETURN p;END;
  FUNCTION follow_store(p_store VARCHAR2,p_actor NUMBER)RETURN t_record IS p BEX_PROFILE%ROWTYPE;r t_record;id NUMBER;s NUMBER;
  BEGIN p:=actor_profile(p_actor);BEGIN s:=str_service_pkg.resolve_store_id(p_store);EXCEPTION WHEN OTHERS THEN RAISE e_store_not_found;END;
    BEGIN r:=stf_repository_pkg.active_link(s,p.pfl_id);RAISE e_conflict;EXCEPTION WHEN NO_DATA_FOUND THEN NULL;END;
    BEGIN r:=stf_repository_pkg.latest_link(s,p.pfl_id);stf_rule_pkg.validate_transition(r.status,'ACTIVE');
      stf_repository_pkg.update_status(r.id,'ACTIVE',p.pfl_id);RETURN stf_repository_pkg.by_id(r.id);
    EXCEPTION WHEN NO_DATA_FOUND THEN r.public_id:=LOWER(RAWTOHEX(SYS_GUID()));r.store_id:=s;r.profile_id:=p.pfl_id;
      stf_repository_pkg.insert_row(r,p.pfl_id,id);RETURN stf_repository_pkg.by_id(id);END;END;
  FUNCTION unfollow_store(p_store VARCHAR2,p_actor NUMBER)RETURN t_record IS p BEX_PROFILE%ROWTYPE;r t_record;s NUMBER;
  BEGIN p:=actor_profile(p_actor);BEGIN s:=str_service_pkg.resolve_store_id(p_store);r:=stf_repository_pkg.active_link(s,p.pfl_id);
    EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_following;WHEN OTHERS THEN RAISE e_store_not_found;END;
    stf_repository_pkg.update_status(r.id,'INACTIVE',p.pfl_id);RETURN stf_repository_pkg.by_id(r.id);END;
  FUNCTION list_following(p_actor NUMBER)RETURN t_records IS p BEX_PROFILE%ROWTYPE;BEGIN p:=actor_profile(p_actor);RETURN stf_repository_pkg.list_profile(p.pfl_id);END;
END stf_service_pkg;
/
