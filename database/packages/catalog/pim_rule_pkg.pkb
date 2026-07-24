CREATE OR REPLACE PACKAGE BODY pim_rule_pkg AS
  FUNCTION yes(p BOOLEAN) RETURN BOOLEAN IS
  BEGIN RETURN p IS NOT NULL AND p; END;
  FUNCTION normalize_url(p VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN TRIM(p); END;
  FUNCTION normalize_alt_text(p VARCHAR2) RETURN VARCHAR2 IS
  BEGIN RETURN REGEXP_REPLACE(TRIM(p),'[[:space:]]+',' '); END;
  FUNCTION normalize_status(p VARCHAR2) RETURN VARCHAR2 IS
  BEGIN RETURN UPPER(TRIM(p)); END;
  PROCEDURE validate_status(p VARCHAR2) IS s VARCHAR2(30):=normalize_status(p);
  BEGIN IF s IS NULL OR s NOT IN(c_status_active,c_status_inactive)
    THEN RAISE e_invalid_status; END IF; END;
  PROCEDURE validate_data(io_data IN OUT NOCOPY t_image_data) IS
  BEGIN
    io_data.url_value:=normalize_url(io_data.url_value);
    io_data.alt_text_value:=normalize_alt_text(io_data.alt_text_value);
    io_data.status_value:=NVL(normalize_status(io_data.status_value),c_status_active);
    IF io_data.url_value IS NULL OR LENGTH(io_data.url_value)>1000
       OR NOT REGEXP_LIKE(io_data.url_value,'^https?://[^[:space:]]+$','i')
    THEN RAISE e_invalid_url; END IF;
    IF io_data.alt_text_value IS NOT NULL AND LENGTH(io_data.alt_text_value)>200
    THEN RAISE e_invalid_alt_text; END IF;
    IF io_data.sort_order_value IS NULL OR io_data.sort_order_value<0
       OR io_data.sort_order_value<>TRUNC(io_data.sort_order_value)
    THEN RAISE e_invalid_sort_order; END IF;
    IF io_data.is_primary_value IS NULL OR io_data.is_primary_value NOT IN(0,1)
    THEN RAISE e_invalid_primary; END IF;
    validate_status(io_data.status_value);
  END;
  PROCEDURE validate_patch(io_patch IN OUT NOCOPY t_image_patch) IS
  BEGIN
    IF NOT yes(io_patch.set_url) AND NOT yes(io_patch.set_alt_text)
       AND NOT yes(io_patch.set_sort_order) AND NOT yes(io_patch.set_is_primary)
    THEN RAISE e_empty_patch; END IF;
    IF yes(io_patch.set_url) THEN
      io_patch.url_value:=normalize_url(io_patch.url_value);
      IF io_patch.url_value IS NULL OR LENGTH(io_patch.url_value)>1000
         OR NOT REGEXP_LIKE(io_patch.url_value,'^https?://[^[:space:]]+$','i')
      THEN RAISE e_invalid_url; END IF;
    END IF;
    IF yes(io_patch.set_alt_text) THEN
      io_patch.alt_text_value:=normalize_alt_text(io_patch.alt_text_value);
      IF io_patch.alt_text_value IS NOT NULL AND LENGTH(io_patch.alt_text_value)>200
      THEN RAISE e_invalid_alt_text; END IF;
    END IF;
    IF yes(io_patch.set_sort_order) AND (io_patch.sort_order_value IS NULL
       OR io_patch.sort_order_value<0
       OR io_patch.sort_order_value<>TRUNC(io_patch.sort_order_value))
    THEN RAISE e_invalid_sort_order; END IF;
    IF yes(io_patch.set_is_primary)
       AND (io_patch.is_primary_value IS NULL OR io_patch.is_primary_value NOT IN(0,1))
    THEN RAISE e_invalid_primary; END IF;
  END;
END pim_rule_pkg;
/
