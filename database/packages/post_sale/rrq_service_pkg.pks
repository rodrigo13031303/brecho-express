CREATE OR REPLACE PACKAGE rrq_service_pkg AS
  SUBTYPE t_record IS rrq_repository_pkg.t_row;SUBTYPE t_records IS rrq_repository_pkg.t_rows;
  e_not_found EXCEPTION;e_forbidden EXCEPTION;e_invalid EXCEPTION;e_conflict EXCEPTION;
  FUNCTION open_request(p_order VARCHAR2,p_store VARCHAR2,p_reason VARCHAR2,p_description VARCHAR2,p_actor NUMBER) RETURN t_record;
  FUNCTION get_request(p_public VARCHAR2,p_actor NUMBER) RETURN t_record;
  FUNCTION get_internal(p_public VARCHAR2) RETURN t_record;
  FUNCTION list_store(p_store VARCHAR2,p_actor NUMBER) RETURN t_records;
  FUNCTION respond(p_public VARCHAR2,p_response VARCHAR2,p_actor NUMBER) RETURN t_record;
  FUNCTION change_state_internal(p_public VARCHAR2,p_status VARCHAR2,p_result VARCHAR2,p_actor NUMBER) RETURN t_record;
END rrq_service_pkg;
/
