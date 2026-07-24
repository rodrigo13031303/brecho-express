CREATE OR REPLACE PACKAGE brd_rule_pkg AS
  c_status_active CONSTANT BEX_BRAND.BRD_STATUS%TYPE := 'ACTIVE';
  c_status_inactive CONSTANT BEX_BRAND.BRD_STATUS%TYPE := 'INACTIVE';
  e_name_required EXCEPTION;
  e_invalid_name EXCEPTION;
  e_slug_required EXCEPTION;
  e_invalid_slug EXCEPTION;
  e_invalid_description EXCEPTION;
  e_invalid_status EXCEPTION;
  e_invalid_transition EXCEPTION;

  TYPE t_brand_creation IS RECORD (
    name_value BEX_BRAND.BRD_NAME%TYPE,
    slug_value BEX_BRAND.BRD_SLUG%TYPE,
    description_value BEX_BRAND.BRD_DESCRIPTION%TYPE,
    status_value BEX_BRAND.BRD_STATUS%TYPE
  );

  FUNCTION normalize_name(p_name VARCHAR2) RETURN VARCHAR2;
  FUNCTION normalize_slug(p_slug VARCHAR2) RETURN VARCHAR2;
  FUNCTION normalize_description(p_description VARCHAR2) RETURN VARCHAR2;
  FUNCTION normalize_status(p_status VARCHAR2) RETURN VARCHAR2;
  PROCEDURE validate_name(p_name VARCHAR2);
  PROCEDURE validate_slug(p_slug VARCHAR2);
  PROCEDURE validate_description(p_description VARCHAR2);
  PROCEDURE validate_status(p_status VARCHAR2);
  PROCEDURE validate_status_transition(
    p_current_status VARCHAR2,
    p_new_status VARCHAR2
  );
  PROCEDURE normalize_and_validate_creation(
    io_creation IN OUT NOCOPY t_brand_creation
  );
END brd_rule_pkg;
/
