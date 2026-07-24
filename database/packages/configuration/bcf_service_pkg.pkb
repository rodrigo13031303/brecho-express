CREATE OR REPLACE PACKAGE BODY bcf_service_pkg AS
  FUNCTION get_config(p_code VARCHAR2) RETURN t_record IS r t_record;BEGIN
    BEGIN r:=bcf_repository_pkg.by_code(p_code);EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_found;END;RETURN r;
  END;
  FUNCTION list_module(p_module VARCHAR2) RETURN t_records IS BEGIN
    RETURN bcf_repository_pkg.list_module(p_module);
  END;
  FUNCTION upsert_config(p_code VARCHAR2,p_module VARCHAR2,p_name VARCHAR2,p_description VARCHAR2,p_text VARCHAR2,p_number NUMBER,p_boolean CHAR,p_unit VARCHAR2,p_actor NUMBER) RETURN t_record IS
    r t_record;id NUMBER;
  BEGIN
    BEGIN bcf_rule_pkg.validate_value(p_text,p_number,p_boolean);EXCEPTION WHEN bcf_rule_pkg.e_invalid THEN RAISE e_invalid;END;
    BEGIN r:=bcf_repository_pkg.by_code(p_code);EXCEPTION WHEN NO_DATA_FOUND THEN
      r.public_id:=LOWER(RAWTOHEX(SYS_GUID()));r.code:=UPPER(TRIM(p_code));r.module_code:=UPPER(TRIM(p_module));r.name:=TRIM(p_name);
      r.description:=TRIM(p_description);r.value_text:=p_text;r.value_number:=p_number;r.value_boolean:=UPPER(p_boolean);r.unit_code:=p_unit;
      bcf_repository_pkg.insert_row(r,p_actor,id);RETURN bcf_repository_pkg.by_code(p_code);END;
    bcf_repository_pkg.update_row(p_code,p_text,p_number,p_boolean,p_unit,'ACTIVE',p_actor);
    RETURN bcf_repository_pkg.by_code(p_code);
  END;
END bcf_service_pkg;
/
