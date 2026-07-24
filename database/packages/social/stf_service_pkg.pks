CREATE OR REPLACE PACKAGE stf_service_pkg AS
  SUBTYPE t_record IS stf_repository_pkg.t_row;SUBTYPE t_records IS stf_repository_pkg.t_rows;
  e_store_not_found EXCEPTION;e_forbidden EXCEPTION;e_conflict EXCEPTION;e_not_following EXCEPTION;
  FUNCTION follow_store(p_store VARCHAR2,p_actor NUMBER)RETURN t_record;
  FUNCTION unfollow_store(p_store VARCHAR2,p_actor NUMBER)RETURN t_record;
  FUNCTION list_following(p_actor NUMBER)RETURN t_records;
END stf_service_pkg;
/
