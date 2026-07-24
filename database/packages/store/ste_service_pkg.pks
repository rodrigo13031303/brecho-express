CREATE OR REPLACE PACKAGE ste_service_pkg AS
  SUBTYPE t_record IS ste_repository_pkg.t_row;SUBTYPE t_records IS ste_repository_pkg.t_rows;
  e_not_found EXCEPTION;e_forbidden EXCEPTION;e_invalid EXCEPTION;
  FUNCTION create_event(p_store VARCHAR2,p_name VARCHAR2,p_description VARCHAR2,p_start TIMESTAMP,p_end TIMESTAMP,p_actor NUMBER)RETURN t_record;
  FUNCTION list_events(p_store VARCHAR2)RETURN t_records;
  FUNCTION change_status(p_public VARCHAR2,p_status VARCHAR2,p_actor NUMBER)RETURN t_record;
END ste_service_pkg;
/
