CREATE OR REPLACE PACKAGE BODY prl_service_pkg AS
  FUNCTION profile(p_public VARCHAR2)RETURN BEX_PROFILE%ROWTYPE IS p BEX_PROFILE%ROWTYPE;BEGIN
    BEGIN p:=pfl_service_pkg.get_by_public_id(p_public);EXCEPTION WHEN OTHERS THEN RAISE e_profile_not_found;END;RETURN p;END;
  FUNCTION role(p_code VARCHAR2)RETURN rol_query_pkg.t_record IS r rol_query_pkg.t_record;BEGIN
    BEGIN r:=rol_query_pkg.get_by_code(p_code);EXCEPTION WHEN OTHERS THEN RAISE e_role_not_found;END;RETURN r;END;
  FUNCTION grant_role(p_profile_public VARCHAR2,p_role_code VARCHAR2,p_expires TIMESTAMP,p_actor_profile NUMBER)RETURN t_record IS
    p BEX_PROFILE%ROWTYPE;r rol_query_pkg.t_record;x t_record;id NUMBER;
  BEGIN BEGIN prl_rule_pkg.validate_expiry(p_expires);EXCEPTION WHEN prl_rule_pkg.e_invalid_expiry THEN RAISE e_invalid_expiry;END;
    p:=profile(p_profile_public);r:=role(p_role_code);
    BEGIN x:=prl_repository_pkg.by_profile_role(p.pfl_id,r.role_id);IF x.status='ACTIVE'AND(x.expires_at IS NULL OR x.expires_at>SYSTIMESTAMP)THEN RAISE e_already_active;END IF;
      prl_repository_pkg.activate(x.id,p_expires,p_actor_profile);RETURN prl_repository_pkg.by_id(x.id);
    EXCEPTION WHEN NO_DATA_FOUND THEN x.public_id:=LOWER(RAWTOHEX(SYS_GUID()));x.profile_id:=p.pfl_id;x.role_id:=r.role_id;x.expires_at:=p_expires;
      prl_repository_pkg.insert_row(x,p_actor_profile,id);RETURN prl_repository_pkg.by_id(id);END;END;
  FUNCTION revoke_role(p_profile_public VARCHAR2,p_role_code VARCHAR2,p_actor_profile NUMBER)RETURN t_record IS
    p BEX_PROFILE%ROWTYPE;r rol_query_pkg.t_record;x t_record;
  BEGIN p:=profile(p_profile_public);r:=role(p_role_code);BEGIN x:=prl_repository_pkg.by_profile_role(p.pfl_id,r.role_id);
    EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_active;END;IF x.status<>'ACTIVE'THEN RAISE e_not_active;END IF;
    prl_repository_pkg.deactivate(x.id,p_actor_profile);RETURN prl_repository_pkg.by_id(x.id);END;
  FUNCTION list_roles(p_profile_public VARCHAR2)RETURN t_records IS p BEX_PROFILE%ROWTYPE;BEGIN p:=profile(p_profile_public);RETURN prl_repository_pkg.list_profile(p.pfl_id);END;
END prl_service_pkg;
/
