CREATE OR REPLACE PACKAGE prl_service_pkg AS
  SUBTYPE t_record IS prl_repository_pkg.t_row;SUBTYPE t_records IS prl_repository_pkg.t_rows;
  e_profile_not_found EXCEPTION;e_role_not_found EXCEPTION;e_invalid_expiry EXCEPTION;e_already_active EXCEPTION;e_not_active EXCEPTION;
  FUNCTION grant_role(p_profile_public VARCHAR2,p_role_code VARCHAR2,p_expires TIMESTAMP,p_actor_profile NUMBER)RETURN t_record;
  FUNCTION revoke_role(p_profile_public VARCHAR2,p_role_code VARCHAR2,p_actor_profile NUMBER)RETURN t_record;
  FUNCTION list_roles(p_profile_public VARCHAR2)RETURN t_records;
END prl_service_pkg;
/
