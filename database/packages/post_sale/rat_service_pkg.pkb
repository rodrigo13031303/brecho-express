CREATE OR REPLACE PACKAGE BODY rat_service_pkg AS
  FUNCTION add_attachment(p_request VARCHAR2,p_type VARCHAR2,p_url VARCHAR2,p_filename VARCHAR2,
    p_mime VARCHAR2,p_size NUMBER,p_description VARCHAR2,p_actor NUMBER)RETURN t_record IS
    q rrq_service_pkg.t_record;p BEX_PROFILE%ROWTYPE;r t_record;id NUMBER;
  BEGIN BEGIN rat_rule_pkg.validate_create(p_type,p_url,p_size);EXCEPTION WHEN rat_rule_pkg.e_invalid THEN RAISE e_invalid;END;
    q:=rrq_service_pkg.get_request(p_request,p_actor);p:=pfl_service_pkg.get_by_account_id(p_actor);
    r.rat_public_id:=LOWER(RAWTOHEX(SYS_GUID()));r.rrq_id:=q.rrq_id;r.pfl_id:=p.pfl_id;r.attachment_type:=UPPER(TRIM(p_type));
    r.attachment_url:=TRIM(p_url);r.filename:=TRIM(p_filename);r.mime_type:=LOWER(TRIM(p_mime));r.size_bytes:=p_size;r.description:=TRIM(p_description);
    rat_repository_pkg.insert_row(r,p.pfl_id,id);RETURN rat_repository_pkg.by_id(id);
  EXCEPTION WHEN rrq_service_pkg.e_forbidden THEN RAISE e_forbidden;WHEN rrq_service_pkg.e_not_found THEN RAISE e_not_found;END;
  FUNCTION list_attachments(p_request VARCHAR2,p_actor NUMBER)RETURN t_records IS q rrq_service_pkg.t_record;
  BEGIN q:=rrq_service_pkg.get_request(p_request,p_actor);RETURN rat_repository_pkg.list_request(q.rrq_id);
  EXCEPTION WHEN rrq_service_pkg.e_forbidden THEN RAISE e_forbidden;WHEN rrq_service_pkg.e_not_found THEN RAISE e_not_found;END;
END rat_service_pkg;
/
