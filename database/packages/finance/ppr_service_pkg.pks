CREATE OR REPLACE PACKAGE ppr_service_pkg AS
  SUBTYPE t_record IS ppr_repository_pkg.t_row;SUBTYPE t_table IS ppr_repository_pkg.t_rows;
  e_not_found EXCEPTION;e_invalid EXCEPTION;
  FUNCTION create_internal(p_code VARCHAR2,p_name VARCHAR2,p_actor NUMBER) RETURN t_record;
  FUNCTION get_provider(p_public VARCHAR2) RETURN t_record;
  FUNCTION list_active RETURN t_table;
  FUNCTION resolve_active_id(p_public VARCHAR2) RETURN NUMBER;
  FUNCTION public_id_by_id(p_id NUMBER) RETURN CHAR;
END ppr_service_pkg;
/
