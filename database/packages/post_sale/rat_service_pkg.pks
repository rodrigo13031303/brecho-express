CREATE OR REPLACE PACKAGE rat_service_pkg AS
  SUBTYPE t_record IS rat_repository_pkg.t_row;SUBTYPE t_records IS rat_repository_pkg.t_rows;
  e_not_found EXCEPTION;e_forbidden EXCEPTION;e_invalid EXCEPTION;
  FUNCTION add_attachment(p_request VARCHAR2,p_type VARCHAR2,p_url VARCHAR2,p_filename VARCHAR2,
    p_mime VARCHAR2,p_size NUMBER,p_description VARCHAR2,p_actor NUMBER)RETURN t_record;
  FUNCTION list_attachments(p_request VARCHAR2,p_actor NUMBER)RETURN t_records;
END rat_service_pkg;
/
