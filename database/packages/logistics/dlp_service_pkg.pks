CREATE OR REPLACE PACKAGE dlp_service_pkg AS
  SUBTYPE t_record IS dlp_repository_pkg.t_row;SUBTYPE t_table IS dlp_repository_pkg.t_rows;
  e_not_found EXCEPTION;e_invalid EXCEPTION;e_inactive EXCEPTION;
  FUNCTION create_internal(p dlp_repository_pkg.t_row,p_actor NUMBER) RETURN t_record;
  FUNCTION get_profile(p_public VARCHAR2) RETURN t_record;
  FUNCTION list_profiles(p_status VARCHAR2 DEFAULT 'ACTIVE') RETURN t_table;
  FUNCTION resolve_active_id(p_public VARCHAR2) RETURN NUMBER;
  FUNCTION public_id_by_id(p_id NUMBER) RETURN CHAR;
END dlp_service_pkg;
/
