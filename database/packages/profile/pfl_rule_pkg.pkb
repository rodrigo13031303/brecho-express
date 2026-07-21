CREATE OR REPLACE PACKAGE BODY pfl_rule_pkg AS
  ------------------------------------------------------------------------------
  -- Constantes privadas
  ------------------------------------------------------------------------------

  c_display_name_min_length CONSTANT PLS_INTEGER := 2;
  c_display_name_max_length CONSTANT PLS_INTEGER := 100;
  c_full_name_min_length    CONSTANT PLS_INTEGER := 2;
  c_full_name_max_length    CONSTANT PLS_INTEGER := 200;

  c_locale_pt_br CONSTANT VARCHAR2(10) := 'pt-BR';
  c_timezone_sao_paulo CONSTANT VARCHAR2(64) := 'America/Sao_Paulo';

  ------------------------------------------------------------------------------
  -- Helpers privados
  ------------------------------------------------------------------------------

  FUNCTION normalize_name(
    p_name IN VARCHAR2
  ) RETURN VARCHAR2 IS
  BEGIN
    IF p_name IS NULL THEN
      RETURN NULL;
    END IF;

    RETURN REGEXP_REPLACE(TRIM(p_name), '[[:space:]]+', ' ');
  END normalize_name;

  ------------------------------------------------------------------------------
  -- Normalização
  ------------------------------------------------------------------------------

  FUNCTION normalize_display_name(
    p_display_name IN VARCHAR2
  ) RETURN VARCHAR2 IS
  BEGIN
    RETURN normalize_name(p_display_name);
  END normalize_display_name;

  FUNCTION normalize_full_name(
    p_full_name IN VARCHAR2
  ) RETURN VARCHAR2 IS
  BEGIN
    RETURN normalize_name(p_full_name);
  END normalize_full_name;

  ------------------------------------------------------------------------------
  -- Validações
  ------------------------------------------------------------------------------

  PROCEDURE validate_display_name(
    p_display_name IN VARCHAR2
  ) IS
    l_display_name VARCHAR2(32767);
  BEGIN
    l_display_name := normalize_display_name(p_display_name);

    IF l_display_name IS NULL
       OR LENGTH(l_display_name) < c_display_name_min_length
       OR LENGTH(l_display_name) > c_display_name_max_length THEN
      RAISE e_invalid_display_name;
    END IF;
  END validate_display_name;

  PROCEDURE validate_full_name(
    p_full_name IN VARCHAR2
  ) IS
    l_full_name VARCHAR2(32767);
  BEGIN
    l_full_name := normalize_full_name(p_full_name);

    IF l_full_name IS NOT NULL
       AND (
         LENGTH(l_full_name) < c_full_name_min_length
         OR LENGTH(l_full_name) > c_full_name_max_length
       ) THEN
      RAISE e_invalid_full_name;
    END IF;
  END validate_full_name;

  PROCEDURE validate_birth_date(
    p_birth_date IN DATE
  ) IS
  BEGIN
    IF p_birth_date IS NOT NULL
       AND p_birth_date > TRUNC(SYSDATE) THEN
      RAISE e_invalid_birth_date;
    END IF;
  END validate_birth_date;

  PROCEDURE validate_locale_code(
    p_locale_code IN VARCHAR2
  ) IS
    l_locale_code VARCHAR2(32767);
  BEGIN
    l_locale_code := TRIM(p_locale_code);

    IF l_locale_code IS NULL
       OR l_locale_code <> c_locale_pt_br THEN
      RAISE e_invalid_locale_code;
    END IF;
  END validate_locale_code;

  PROCEDURE validate_timezone_name(
    p_timezone_name IN VARCHAR2
  ) IS
    l_timezone_name VARCHAR2(32767);
  BEGIN
    l_timezone_name := TRIM(p_timezone_name);

    IF l_timezone_name IS NULL
       OR l_timezone_name <> c_timezone_sao_paulo THEN
      RAISE e_invalid_timezone_name;
    END IF;
  END validate_timezone_name;
END pfl_rule_pkg;
/
