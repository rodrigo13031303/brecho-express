CREATE OR REPLACE PACKAGE BODY brd_rule_pkg AS
  FUNCTION normalize_name(p_name VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN REGEXP_REPLACE(TRIM(p_name),'[[:space:]]+',' ');
  END;

  FUNCTION normalize_slug(p_slug VARCHAR2) RETURN VARCHAR2 IS
    l_slug VARCHAR2(32767);
  BEGIN
    IF p_slug IS NULL THEN RETURN NULL; END IF;
    l_slug:=TRANSLATE(
      TRIM(p_slug),
      UNISTR(
        '\00E1\00E0\00E2\00E3\00E4\00E9\00E8\00EA\00EB'||
        '\00ED\00EC\00EE\00EF\00F3\00F2\00F4\00F5\00F6'||
        '\00FA\00F9\00FB\00FC\00E7\00F1'||
        '\00C1\00C0\00C2\00C3\00C4\00C9\00C8\00CA\00CB'||
        '\00CD\00CC\00CE\00CF\00D3\00D2\00D4\00D5\00D6'||
        '\00DA\00D9\00DB\00DC\00C7\00D1'
      ),
      'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN'
    );
    l_slug:=LOWER(l_slug);
    l_slug:=REGEXP_REPLACE(l_slug,'[[:space:]]+','-');
    l_slug:=REGEXP_REPLACE(l_slug,'[^a-z0-9-]','');
    l_slug:=REGEXP_REPLACE(l_slug,'-+','-');
    RETURN REGEXP_REPLACE(l_slug,'^-+|-+$','');
  END;

  FUNCTION normalize_description(p_description VARCHAR2) RETURN VARCHAR2 IS
  BEGIN RETURN TRIM(p_description); END;
  FUNCTION normalize_status(p_status VARCHAR2) RETURN VARCHAR2 IS
  BEGIN RETURN UPPER(TRIM(p_status)); END;

  PROCEDURE validate_name(p_name VARCHAR2) IS
    l_value VARCHAR2(32767):=normalize_name(p_name);
  BEGIN
    IF l_value IS NULL THEN RAISE e_name_required;
    ELSIF LENGTH(l_value)>200 THEN RAISE e_invalid_name; END IF;
  END;
  PROCEDURE validate_slug(p_slug VARCHAR2) IS
    l_value VARCHAR2(32767):=normalize_slug(p_slug);
  BEGIN
    IF l_value IS NULL THEN RAISE e_slug_required;
    ELSIF LENGTH(l_value)>120
       OR NOT REGEXP_LIKE(l_value,'^[a-z0-9]+(-[a-z0-9]+)*$')
    THEN RAISE e_invalid_slug; END IF;
  END;
  PROCEDURE validate_description(p_description VARCHAR2) IS
  BEGIN
    IF normalize_description(p_description) IS NOT NULL
       AND LENGTH(normalize_description(p_description))>1000
    THEN RAISE e_invalid_description; END IF;
  END;
  PROCEDURE validate_status(p_status VARCHAR2) IS
    l_value VARCHAR2(32767):=normalize_status(p_status);
  BEGIN
    IF l_value IS NULL OR l_value NOT IN (
      c_status_active,c_status_inactive
    ) THEN RAISE e_invalid_status; END IF;
  END;
  PROCEDURE validate_status_transition(
    p_current_status VARCHAR2,p_new_status VARCHAR2
  ) IS
  BEGIN
    validate_status(p_current_status);
    validate_status(p_new_status);
    IF normalize_status(p_current_status)=normalize_status(p_new_status) THEN
      RAISE e_invalid_transition;
    END IF;
  END;
  PROCEDURE normalize_and_validate_creation(
    io_creation IN OUT NOCOPY t_brand_creation
  ) IS
  BEGIN
    io_creation.name_value:=normalize_name(io_creation.name_value);
    io_creation.slug_value:=normalize_slug(io_creation.slug_value);
    io_creation.description_value:=
      normalize_description(io_creation.description_value);
    io_creation.status_value:=normalize_status(io_creation.status_value);
    validate_name(io_creation.name_value);
    validate_slug(io_creation.slug_value);
    validate_description(io_creation.description_value);
    validate_status(io_creation.status_value);
  END;
END brd_rule_pkg;
/
