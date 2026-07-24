CREATE OR REPLACE PACKAGE srv_service_pkg AS
  SUBTYPE t_record IS srv_repository_pkg.t_row;SUBTYPE t_records IS srv_repository_pkg.t_rows;
  e_not_found EXCEPTION;e_forbidden EXCEPTION;e_invalid EXCEPTION;e_conflict EXCEPTION;
  FUNCTION create_review(p_order VARCHAR2,p_store VARCHAR2,p_overall NUMBER,p_product NUMBER,p_conservation NUMBER,
    p_service NUMBER,p_delivery NUMBER,p_packaging NUMBER,p_again VARCHAR2,p_comment VARCHAR2,p_actor NUMBER)RETURN t_record;
  FUNCTION get_review(p_public VARCHAR2)RETURN t_record;FUNCTION list_store(p_store VARCHAR2)RETURN t_records;
  FUNCTION reply(p_public VARCHAR2,p_reply VARCHAR2,p_actor NUMBER)RETURN t_record;
END srv_service_pkg;
/
