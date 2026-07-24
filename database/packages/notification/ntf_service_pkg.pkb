CREATE OR REPLACE PACKAGE BODY ntf_service_pkg AS
  FUNCTION create_notification(p_profile NUMBER,p_type VARCHAR2,p_title VARCHAR2,p_body VARCHAR2) RETURN t_record IS r t_record;i NUMBER;BEGIN ntf_rule_pkg.validate_notification(p_type,p_title,p_body);r.public_id:=LOWER(RAWTOHEX(SYS_GUID()));r.profile_id:=p_profile;r.notification_type:=UPPER(TRIM(p_type));r.title:=TRIM(p_title);r.body:=TRIM(p_body);ntf_repository_pkg.insert_row(r,i);RETURN ntf_repository_pkg.by_public(r.public_id);EXCEPTION WHEN ntf_rule_pkg.e_invalid THEN RAISE e_invalid;END;
  FUNCTION get_notification(p_public_id VARCHAR2) RETURN t_record IS BEGIN RETURN ntf_repository_pkg.by_public(p_public_id);EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_found;END;
  FUNCTION list_notifications(p_profile NUMBER) RETURN t_records IS BEGIN RETURN ntf_repository_pkg.list_profile(p_profile);END;
  FUNCTION read_notification(p_public_id VARCHAR2) RETURN t_record IS r t_record;BEGIN r:=get_notification(p_public_id);ntf_repository_pkg.mark_read(r.id);RETURN get_notification(p_public_id);END;
END ntf_service_pkg;
/
