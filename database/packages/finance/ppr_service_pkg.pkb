CREATE OR REPLACE PACKAGE BODY ppr_service_pkg AS
  FUNCTION create_internal(p_code VARCHAR2,p_name VARCHAR2,p_actor NUMBER) RETURN t_record IS r t_record;id NUMBER;
  BEGIN BEGIN ppr_rule_pkg.validate_data(p_code,p_name,'ACTIVE');EXCEPTION WHEN ppr_rule_pkg.e_invalid THEN RAISE e_invalid;END;
    r.ppr_public_id:=LOWER(RAWTOHEX(SYS_GUID()));r.ppr_code:=UPPER(TRIM(p_code));r.ppr_name:=TRIM(p_name);r.ppr_status:='ACTIVE';
    BEGIN ppr_repository_pkg.insert_row(r,p_actor,id);EXCEPTION WHEN DUP_VAL_ON_INDEX THEN RAISE e_invalid;END;
    RETURN ppr_repository_pkg.by_id(id);END;
  FUNCTION get_provider(p_public VARCHAR2) RETURN t_record IS r t_record;BEGIN
    BEGIN r:=ppr_repository_pkg.by_public(p_public);EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_found;END;RETURN r;END;
  FUNCTION list_active RETURN t_table IS BEGIN RETURN ppr_repository_pkg.list_rows('ACTIVE');END;
  FUNCTION resolve_active_id(p_public VARCHAR2) RETURN NUMBER IS r t_record;BEGIN r:=get_provider(p_public);
    IF r.ppr_status<>'ACTIVE' THEN RAISE e_invalid;END IF;RETURN r.ppr_id;END;
  FUNCTION public_id_by_id(p_id NUMBER) RETURN CHAR IS r t_record;BEGIN
    BEGIN r:=ppr_repository_pkg.by_id(p_id);EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_found;END;RETURN r.ppr_public_id;END;
END ppr_service_pkg;
/
