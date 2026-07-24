CREATE OR REPLACE PACKAGE BODY cat_rule_pkg AS
  c_name_max_length        CONSTANT PLS_INTEGER := 200;
  c_slug_max_length        CONSTANT PLS_INTEGER := 120;
  c_description_max_length CONSTANT PLS_INTEGER := 1000;

  FUNCTION normalize_name(
    p_name IN VARCHAR2
  ) RETURN VARCHAR2 IS
  BEGIN
    IF p_name IS NULL THEN
      RETURN NULL;
    END IF;
    RETURN REGEXP_REPLACE(TRIM(p_name), '[[:space:]]+', ' ');
  END normalize_name;

  FUNCTION normalize_slug(
    p_slug IN VARCHAR2
  ) RETURN VARCHAR2 IS
    l_slug VARCHAR2(32767);
  BEGIN
    IF p_slug IS NULL THEN
      RETURN NULL;
    END IF;
    l_slug := TRIM(p_slug);
    l_slug := TRANSLATE(
      l_slug,
      UNISTR(
        '\00E1\00E0\00E2\00E3\00E4' ||
        '\00E9\00E8\00EA\00EB' ||
        '\00ED\00EC\00EE\00EF' ||
        '\00F3\00F2\00F4\00F5\00F6' ||
        '\00FA\00F9\00FB\00FC' ||
        '\00E7\00F1' ||
        '\00C1\00C0\00C2\00C3\00C4' ||
        '\00C9\00C8\00CA\00CB' ||
        '\00CD\00CC\00CE\00CF' ||
        '\00D3\00D2\00D4\00D5\00D6' ||
        '\00DA\00D9\00DB\00DC' ||
        '\00C7\00D1'
      ),
      'aaaaaeeeeiiiiooooouuuucn' ||
      'AAAAAEEEEIIIIOOOOOUUUUCN'
    );
    l_slug := LOWER(l_slug);
    l_slug := REGEXP_REPLACE(l_slug, '[[:space:]]+', '-');
    l_slug := REGEXP_REPLACE(l_slug, '[^a-z0-9-]', '');
    l_slug := REGEXP_REPLACE(l_slug, '-+', '-');
    RETURN REGEXP_REPLACE(l_slug, '^-+|-+$', '');
  END normalize_slug;

  FUNCTION normalize_description(
    p_description IN VARCHAR2
  ) RETURN VARCHAR2 IS
  BEGIN
    RETURN TRIM(p_description);
  END normalize_description;

  FUNCTION normalize_status(
    p_status IN VARCHAR2
  ) RETURN VARCHAR2 IS
  BEGIN
    RETURN UPPER(TRIM(p_status));
  END normalize_status;

  PROCEDURE validate_name(p_name IN VARCHAR2) IS
    l_name VARCHAR2(32767) := normalize_name(p_name);
  BEGIN
    IF l_name IS NULL THEN
      RAISE e_name_required;
    ELSIF LENGTH(l_name) > c_name_max_length THEN
      RAISE e_invalid_name;
    END IF;
  END validate_name;

  PROCEDURE validate_slug(p_slug IN VARCHAR2) IS
    l_slug VARCHAR2(32767) := normalize_slug(p_slug);
  BEGIN
    IF l_slug IS NULL THEN
      RAISE e_slug_required;
    ELSIF LENGTH(l_slug) > c_slug_max_length
       OR NOT REGEXP_LIKE(l_slug, '^[a-z0-9]+(-[a-z0-9]+)*$') THEN
      RAISE e_invalid_slug;
    END IF;
  END validate_slug;

  PROCEDURE validate_description(p_description IN VARCHAR2) IS
    l_description VARCHAR2(32767) :=
      normalize_description(p_description);
  BEGIN
    IF l_description IS NOT NULL
       AND LENGTH(l_description) > c_description_max_length THEN
      RAISE e_invalid_description;
    END IF;
  END validate_description;

  PROCEDURE validate_status(p_status IN VARCHAR2) IS
    l_status VARCHAR2(32767) := normalize_status(p_status);
  BEGIN
    IF l_status IS NULL
       OR l_status NOT IN (c_status_active, c_status_inactive) THEN
      RAISE e_invalid_status;
    END IF;
  END validate_status;

  PROCEDURE validate_status_transition(
    p_current_status IN VARCHAR2,
    p_new_status     IN VARCHAR2
  ) IS
    l_current BEX_CATEGORY.CAT_STATUS%TYPE;
    l_new     BEX_CATEGORY.CAT_STATUS%TYPE;
  BEGIN
    validate_status(p_current_status);
    validate_status(p_new_status);
    l_current := normalize_status(p_current_status);
    l_new := normalize_status(p_new_status);

    IF l_current = l_new THEN
      RAISE e_invalid_transition;
    END IF;
  END validate_status_transition;

  PROCEDURE normalize_and_validate_creation(
    io_creation IN OUT NOCOPY t_category_creation
  ) IS
  BEGIN
    io_creation.name_value := normalize_name(io_creation.name_value);
    io_creation.slug_value := normalize_slug(io_creation.slug_value);
    io_creation.description_value :=
      normalize_description(io_creation.description_value);
    io_creation.status_value := normalize_status(io_creation.status_value);

    validate_name(io_creation.name_value);
    validate_slug(io_creation.slug_value);
    validate_description(io_creation.description_value);
    validate_status(io_creation.status_value);
  END normalize_and_validate_creation;
END cat_rule_pkg;
/
