CREATE OR REPLACE PACKAGE adr_service_pkg AS
  SUBTYPE t_record IS adr_repository_pkg.t_row;SUBTYPE t_table IS adr_repository_pkg.t_rows;
  e_not_found EXCEPTION;e_forbidden EXCEPTION;e_invalid EXCEPTION;
  FUNCTION create_address(p adr_repository_pkg.t_row,p_actor NUMBER) RETURN t_record;
  FUNCTION list_addresses(p_actor NUMBER) RETURN t_table;
  FUNCTION set_default(p_public VARCHAR2,p_actor NUMBER) RETURN t_record;
  FUNCTION deactivate(p_public VARCHAR2,p_actor NUMBER) RETURN t_record;
  FUNCTION resolve_active_id(p_public VARCHAR2,p_profile NUMBER) RETURN NUMBER;
END adr_service_pkg;
/
