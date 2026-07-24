CREATE OR REPLACE PACKAGE ntf_service_pkg AS
  SUBTYPE t_record IS ntf_repository_pkg.t_row; SUBTYPE t_records IS ntf_repository_pkg.t_rows;
  e_not_found EXCEPTION;e_invalid EXCEPTION;
  FUNCTION create_notification(p_profile NUMBER,p_type VARCHAR2,p_title VARCHAR2,p_body VARCHAR2) RETURN t_record;
  FUNCTION get_notification(p_public_id VARCHAR2) RETURN t_record;
  FUNCTION list_notifications(p_profile NUMBER) RETURN t_records;
  FUNCTION read_notification(p_public_id VARCHAR2) RETURN t_record;
END ntf_service_pkg;
/
