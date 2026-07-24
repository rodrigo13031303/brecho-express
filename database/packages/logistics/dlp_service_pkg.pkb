CREATE OR REPLACE PACKAGE BODY dlp_service_pkg AS
  FUNCTION create_internal(p dlp_repository_pkg.t_row,p_actor NUMBER) RETURN t_record IS
    r t_record;id NUMBER;
  BEGIN BEGIN dlp_rule_pkg.validate_profile(p.dlp_code,p.dlp_name,p.dlp_base_price,
    p.dlp_max_distance_km,p.dlp_max_weight_kg,p.dlp_is_express);
    EXCEPTION WHEN dlp_rule_pkg.e_invalid THEN RAISE e_invalid;END;
    r:=p;r.dlp_public_id:=LOWER(RAWTOHEX(SYS_GUID()));r.dlp_code:=UPPER(TRIM(p.dlp_code));
    r.dlp_name:=TRIM(p.dlp_name);r.dlp_status:=NVL(UPPER(TRIM(p.dlp_status)),'ACTIVE');
    dlp_repository_pkg.insert_row(r,p_actor,id);RETURN dlp_repository_pkg.by_id(id);
  EXCEPTION WHEN DUP_VAL_ON_INDEX THEN RAISE e_invalid;END;
  FUNCTION get_profile(p_public VARCHAR2) RETURN t_record IS r t_record;BEGIN
    BEGIN r:=dlp_repository_pkg.by_public(p_public);EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_found;END;
    RETURN r;END;
  FUNCTION list_profiles(p_status VARCHAR2 DEFAULT 'ACTIVE') RETURN t_table IS
  BEGIN IF UPPER(TRIM(p_status)) NOT IN('ACTIVE','INACTIVE') THEN RAISE e_invalid;END IF;
    RETURN dlp_repository_pkg.list_rows(UPPER(TRIM(p_status)));END;
  FUNCTION resolve_active_id(p_public VARCHAR2) RETURN NUMBER IS r t_record;BEGIN
    r:=get_profile(p_public);IF r.dlp_status<>'ACTIVE' THEN RAISE e_inactive;END IF;RETURN r.dlp_id;END;
  FUNCTION public_id_by_id(p_id NUMBER) RETURN CHAR IS r t_record;BEGIN
    BEGIN r:=dlp_repository_pkg.by_id(p_id);EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_found;END;
    RETURN r.dlp_public_id;END;
END dlp_service_pkg;
/
