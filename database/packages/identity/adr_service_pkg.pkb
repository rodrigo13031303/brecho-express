CREATE OR REPLACE PACKAGE BODY adr_service_pkg AS
  FUNCTION profile_id(p_actor NUMBER) RETURN NUMBER IS x BEX_PROFILE%ROWTYPE;BEGIN
    BEGIN x:=pfl_service_pkg.get_by_account_id(p_actor);EXCEPTION WHEN OTHERS THEN RAISE e_forbidden;END;
    RETURN x.pfl_id;END;
  PROCEDURE own(r adr_repository_pkg.t_row,p NUMBER) IS BEGIN IF r.pfl_id<>p THEN RAISE e_forbidden;END IF;END;
  FUNCTION create_address(p adr_repository_pkg.t_row,p_actor NUMBER) RETURN t_record IS
    r adr_repository_pkg.t_row;id NUMBER;pid NUMBER;
  BEGIN pid:=profile_id(p_actor);BEGIN adr_rule_pkg.validate_address(p.adr_zip_code,p.adr_street,
    p.adr_number,p.adr_district,p.adr_city,p.adr_state,NVL(p.adr_country,'BR'),p.adr_latitude,p.adr_longitude);
    EXCEPTION WHEN adr_rule_pkg.e_invalid_address THEN RAISE e_invalid;END;
    r:=p;r.adr_public_id:=LOWER(RAWTOHEX(SYS_GUID()));r.pfl_id:=pid;r.adr_country:=NVL(UPPER(TRIM(p.adr_country)),'BR');
    r.adr_state:=UPPER(TRIM(p.adr_state));r.adr_is_default:=NVL(p.adr_is_default,0);
    IF r.adr_is_default=1 THEN adr_repository_pkg.clear_default(pid,p_actor);END IF;
    adr_repository_pkg.insert_row(r,p_actor,id);RETURN adr_repository_pkg.by_public(r.adr_public_id);END;
  FUNCTION list_addresses(p_actor NUMBER) RETURN t_table IS BEGIN RETURN adr_repository_pkg.list_profile(profile_id(p_actor));END;
  FUNCTION set_default(p_public VARCHAR2,p_actor NUMBER) RETURN t_record IS r t_record;p NUMBER:=profile_id(p_actor);
  BEGIN BEGIN r:=adr_repository_pkg.by_public(p_public);EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_found;END;
    own(r,p);IF r.adr_status<>'ACTIVE' THEN RAISE e_invalid;END IF;
    adr_repository_pkg.clear_default(p,p_actor);adr_repository_pkg.set_status(r.adr_id,'ACTIVE',1,p_actor);
    RETURN adr_repository_pkg.by_public(p_public);END;
  FUNCTION deactivate(p_public VARCHAR2,p_actor NUMBER) RETURN t_record IS r t_record;p NUMBER:=profile_id(p_actor);
  BEGIN BEGIN r:=adr_repository_pkg.by_public(p_public);EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_found;END;
    own(r,p);adr_repository_pkg.set_status(r.adr_id,'INACTIVE',0,p_actor);RETURN adr_repository_pkg.by_public(p_public);END;
  FUNCTION resolve_active_id(p_public VARCHAR2,p_profile NUMBER) RETURN NUMBER IS r t_record;
  BEGIN BEGIN r:=adr_repository_pkg.by_public(p_public);EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_found;END;
    IF r.pfl_id<>p_profile OR r.adr_status<>'ACTIVE' THEN RAISE e_forbidden;END IF;RETURN r.adr_id;END;
END adr_service_pkg;
/
