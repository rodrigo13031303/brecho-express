CREATE OR REPLACE PACKAGE str_rule_pkg AS
  c_status_draft     CONSTANT BEX_STORE.STR_STATUS%TYPE := 'DRAFT';
  c_status_active    CONSTANT BEX_STORE.STR_STATUS%TYPE := 'ACTIVE';
  c_status_suspended CONSTANT BEX_STORE.STR_STATUS%TYPE := 'SUSPENDED';
  c_status_closed    CONSTANT BEX_STORE.STR_STATUS%TYPE := 'CLOSED';

  c_code_name_required       CONSTANT core_error_pkg.t_error_code := 'BEX-STORE-001';
  c_code_invalid_name        CONSTANT core_error_pkg.t_error_code := 'BEX-STORE-002';
  c_code_slug_required       CONSTANT core_error_pkg.t_error_code := 'BEX-STORE-003';
  c_code_invalid_slug        CONSTANT core_error_pkg.t_error_code := 'BEX-STORE-004';
  c_code_invalid_description CONSTANT core_error_pkg.t_error_code := 'BEX-STORE-005';
  c_code_invalid_logo_url    CONSTANT core_error_pkg.t_error_code := 'BEX-STORE-006';
  c_code_invalid_cover_url   CONSTANT core_error_pkg.t_error_code := 'BEX-STORE-007';
  c_code_invalid_locale      CONSTANT core_error_pkg.t_error_code := 'BEX-STORE-008';
  c_code_invalid_timezone    CONSTANT core_error_pkg.t_error_code := 'BEX-STORE-009';
  c_code_invalid_status      CONSTANT core_error_pkg.t_error_code := 'BEX-STORE-010';
  c_code_invalid_transition  CONSTANT core_error_pkg.t_error_code := 'BEX-STORE-011';
  c_code_empty_patch         CONSTANT core_error_pkg.t_error_code := 'BEX-STORE-012';
  c_code_slug_not_editable   CONSTANT core_error_pkg.t_error_code := 'BEX-STORE-013';
  c_code_store_closed        CONSTANT core_error_pkg.t_error_code := 'BEX-STORE-014';
  c_code_account_ineligible  CONSTANT core_error_pkg.t_error_code := 'BEX-STORE-015';
  c_code_slug_already_used   CONSTANT core_error_pkg.t_error_code := 'BEX-STORE-016';

  e_name_required       EXCEPTION;
  e_invalid_name        EXCEPTION;
  e_slug_required       EXCEPTION;
  e_invalid_slug        EXCEPTION;
  e_invalid_description EXCEPTION;
  e_invalid_logo_url    EXCEPTION;
  e_invalid_cover_url   EXCEPTION;
  e_invalid_locale      EXCEPTION;
  e_invalid_timezone    EXCEPTION;
  e_invalid_status      EXCEPTION;
  e_invalid_transition  EXCEPTION;
  e_empty_patch         EXCEPTION;
  e_slug_not_editable   EXCEPTION;
  e_store_closed        EXCEPTION;
  e_account_ineligible  EXCEPTION;
  e_slug_already_used   EXCEPTION;

  TYPE t_store_patch IS RECORD (
    set_name          BOOLEAN := FALSE,
    name_value        BEX_STORE.STR_NAME%TYPE,
    set_slug          BOOLEAN := FALSE,
    slug_value        BEX_STORE.STR_SLUG%TYPE,
    set_description   BOOLEAN := FALSE,
    description_value BEX_STORE.STR_DESCRIPTION%TYPE,
    set_logo_url      BOOLEAN := FALSE,
    logo_url_value    BEX_STORE.STR_LOGO_URL%TYPE,
    set_cover_url     BOOLEAN := FALSE,
    cover_url_value   BEX_STORE.STR_COVER_URL%TYPE,
    set_locale_code   BOOLEAN := FALSE,
    locale_code_value BEX_STORE.STR_LOCALE_CODE%TYPE,
    set_timezone_name BOOLEAN := FALSE,
    timezone_value    BEX_STORE.STR_TIMEZONE_NAME%TYPE
  );

  TYPE t_store_creation IS RECORD (
    name_value        BEX_STORE.STR_NAME%TYPE,
    slug_value        BEX_STORE.STR_SLUG%TYPE,
    description_value BEX_STORE.STR_DESCRIPTION%TYPE,
    logo_url_value    BEX_STORE.STR_LOGO_URL%TYPE,
    cover_url_value   BEX_STORE.STR_COVER_URL%TYPE,
    locale_code_value BEX_STORE.STR_LOCALE_CODE%TYPE,
    timezone_value    BEX_STORE.STR_TIMEZONE_NAME%TYPE,
    status_value      BEX_STORE.STR_STATUS%TYPE
  );

  FUNCTION normalize_name(p_name IN VARCHAR2) RETURN VARCHAR2;
  FUNCTION normalize_slug(p_slug IN VARCHAR2) RETURN VARCHAR2;
  FUNCTION normalize_optional_text(p_value IN VARCHAR2) RETURN VARCHAR2;
  FUNCTION normalize_url(p_url IN VARCHAR2) RETURN VARCHAR2;
  FUNCTION normalize_status(p_status IN VARCHAR2) RETURN VARCHAR2;

  PROCEDURE validate_name(p_name IN VARCHAR2);
  PROCEDURE validate_slug(p_slug IN VARCHAR2);
  PROCEDURE validate_description(p_description IN VARCHAR2);
  PROCEDURE validate_logo_url(p_logo_url IN VARCHAR2);
  PROCEDURE validate_cover_url(p_cover_url IN VARCHAR2);
  PROCEDURE validate_locale_code(p_locale_code IN VARCHAR2);
  PROCEDURE validate_timezone_name(p_timezone_name IN VARCHAR2);
  PROCEDURE validate_status(p_status IN VARCHAR2);
  PROCEDURE validate_status_transition(
    p_current_status IN VARCHAR2,
    p_new_status     IN VARCHAR2
  );
  PROCEDURE assert_store_editable(p_current_status IN VARCHAR2);
  PROCEDURE validate_slug_change(
    p_current_status IN VARCHAR2,
    p_slug_present   IN BOOLEAN,
    p_current_slug   IN VARCHAR2,
    p_new_slug       IN VARCHAR2
  );
  PROCEDURE validate_patch_not_empty(p_patch IN t_store_patch);
  PROCEDURE normalize_and_validate_patch(
    p_current_status IN VARCHAR2,
    p_current_slug   IN VARCHAR2,
    io_patch         IN OUT NOCOPY t_store_patch
  );
  PROCEDURE normalize_and_validate_creation(
    io_creation IN OUT NOCOPY t_store_creation
  );
  PROCEDURE assert_account_eligible(
    p_account_exists IN BOOLEAN,
    p_account_status IN VARCHAR2
  );
  PROCEDURE build_known_error(
    p_code         IN core_error_pkg.t_error_code,
    o_public_error OUT NOCOPY core_error_pkg.t_public_error,
    o_error_policy OUT NOCOPY core_error_pkg.t_error_policy
  );
END str_rule_pkg;
/
