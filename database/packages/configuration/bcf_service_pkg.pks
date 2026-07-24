CREATE OR REPLACE PACKAGE bcf_service_pkg AS
  SUBTYPE t_record IS bcf_repository_pkg.t_row;
  SUBTYPE t_records IS bcf_repository_pkg.t_rows;
  e_not_found EXCEPTION;
  e_invalid EXCEPTION;
  FUNCTION get_config(p_code VARCHAR2) RETURN t_record;
  FUNCTION list_module(p_module VARCHAR2) RETURN t_records;
  FUNCTION upsert_config(p_code VARCHAR2,p_module VARCHAR2,p_name VARCHAR2,p_description VARCHAR2,p_text VARCHAR2,p_number NUMBER,p_boolean CHAR,p_unit VARCHAR2,p_actor NUMBER) RETURN t_record;
END bcf_service_pkg;
/
