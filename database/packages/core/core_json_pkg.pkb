CREATE OR REPLACE PACKAGE BODY core_json_pkg AS
  FUNCTION parse_object(
    p_request_body IN CLOB
  ) RETURN JSON_OBJECT_T IS
    l_element JSON_ELEMENT_T;
  BEGIN
    IF p_request_body IS NULL
       OR DBMS_LOB.GETLENGTH(p_request_body) = 0 THEN
      RAISE e_request_body_required;
    END IF;

    BEGIN
      l_element := JSON_ELEMENT_T.parse(p_request_body);
    EXCEPTION
      WHEN OTHERS THEN
        RAISE e_invalid_json;
    END;

    IF l_element IS NULL OR NOT l_element.is_object THEN
      RAISE e_json_object_required;
    END IF;

    RETURN TREAT(l_element AS JSON_OBJECT_T);
  END parse_object;

  FUNCTION required_element(
    p_object         IN JSON_OBJECT_T,
    p_attribute_name IN t_attribute_name
  ) RETURN JSON_ELEMENT_T IS
    l_element JSON_ELEMENT_T;
  BEGIN
    IF p_object IS NULL THEN
      RAISE e_json_object_required;
    END IF;

    IF p_attribute_name IS NULL
       OR TRIM(p_attribute_name) IS NULL THEN
      RAISE e_invalid_attribute_name;
    END IF;

    IF NOT p_object.has(p_attribute_name) THEN
      RAISE e_required_attribute;
    END IF;

    l_element := p_object.get(p_attribute_name);

    IF l_element IS NULL OR l_element.is_null THEN
      RAISE e_required_attribute;
    END IF;

    RETURN l_element;
  END required_element;

  FUNCTION required_string(
    p_object         IN JSON_OBJECT_T,
    p_attribute_name IN t_attribute_name
  ) RETURN VARCHAR2 IS
    l_element JSON_ELEMENT_T;
  BEGIN
    l_element := required_element(p_object, p_attribute_name);

    IF NOT l_element.is_string THEN
      RAISE e_invalid_attribute_type;
    END IF;

    RETURN p_object.get_string(p_attribute_name);
  END required_string;

  FUNCTION required_number(
    p_object         IN JSON_OBJECT_T,
    p_attribute_name IN t_attribute_name
  ) RETURN NUMBER IS
    l_element JSON_ELEMENT_T;
  BEGIN
    l_element := required_element(p_object, p_attribute_name);

    IF NOT l_element.is_number THEN
      RAISE e_invalid_attribute_type;
    END IF;

    RETURN p_object.get_number(p_attribute_name);
  END required_number;

  FUNCTION required_boolean(
    p_object         IN JSON_OBJECT_T,
    p_attribute_name IN t_attribute_name
  ) RETURN BOOLEAN IS
    l_element JSON_ELEMENT_T;
  BEGIN
    l_element := required_element(p_object, p_attribute_name);

    IF NOT l_element.is_boolean THEN
      RAISE e_invalid_attribute_type;
    END IF;

    RETURN p_object.get_boolean(p_attribute_name);
  END required_boolean;

  FUNCTION optional_string(
    p_object         IN JSON_OBJECT_T,
    p_attribute_name IN t_attribute_name
  ) RETURN VARCHAR2 IS
    l_element JSON_ELEMENT_T;
  BEGIN
    IF p_object IS NULL THEN
      RAISE e_json_object_required;
    END IF;

    IF p_attribute_name IS NULL
       OR TRIM(p_attribute_name) IS NULL THEN
      RAISE e_invalid_attribute_name;
    END IF;

    IF NOT p_object.has(p_attribute_name) THEN
      RETURN NULL;
    END IF;

    l_element := p_object.get(p_attribute_name);

    IF l_element IS NULL OR l_element.is_null THEN
      RETURN NULL;
    END IF;

    IF NOT l_element.is_string THEN
      RAISE e_invalid_attribute_type;
    END IF;

    RETURN p_object.get_string(p_attribute_name);
  END optional_string;

  FUNCTION required_array(
    p_object         IN JSON_OBJECT_T,
    p_attribute_name IN t_attribute_name
  ) RETURN JSON_ARRAY_T IS
    l_element JSON_ELEMENT_T;
  BEGIN
    l_element := required_element(p_object, p_attribute_name);

    IF NOT l_element.is_array THEN
      RAISE e_invalid_attribute_type;
    END IF;

    RETURN TREAT(l_element AS JSON_ARRAY_T);
  END required_array;

  PROCEDURE assert_allowed_attributes(
    p_object      IN JSON_OBJECT_T,
    p_allowed_csv IN VARCHAR2
  ) IS
    l_keys JSON_KEY_LIST;
  BEGIN
    IF p_object IS NULL THEN
      RAISE e_json_object_required;
    END IF;

    IF p_allowed_csv IS NULL OR TRIM(p_allowed_csv) IS NULL THEN
      IF p_object.get_size > 0 THEN
        RAISE e_unknown_attribute;
      END IF;
      RETURN;
    END IF;

    l_keys := p_object.get_keys;

    IF l_keys.COUNT > 0 THEN
      FOR l_index IN 1 .. l_keys.COUNT LOOP
        IF INSTR(
             ',' || p_allowed_csv || ',',
             ',' || l_keys(l_index) || ','
           ) = 0 THEN
          RAISE e_unknown_attribute;
        END IF;
      END LOOP;
    END IF;
  END assert_allowed_attributes;

  FUNCTION required_timestamp(
    p_object         IN JSON_OBJECT_T,
    p_attribute_name IN t_attribute_name,
    p_format         IN VARCHAR2
  ) RETURN TIMESTAMP IS
    l_value           VARCHAR2(32767);
    l_format          VARCHAR2(32767);
    l_fraction        VARCHAR2(10);
    l_fraction_digits PLS_INTEGER;
  BEGIN
    l_value := required_string(p_object, p_attribute_name);
    l_format := p_format;

    IF REGEXP_LIKE(p_format, 'FF([^0-9]|$)') THEN
      l_fraction := REGEXP_SUBSTR(l_value, '\.[0-9]+');

      IF l_fraction IS NULL THEN
        RAISE e_invalid_temporal_value;
      END IF;

      l_fraction_digits := LENGTH(l_fraction) - 1;

      IF l_fraction_digits < 1 OR l_fraction_digits > 9 THEN
        RAISE e_invalid_temporal_value;
      END IF;

      l_format := REPLACE(
        p_format,
        'FF',
        'FF' || TO_CHAR(l_fraction_digits, 'FM0')
      );
    END IF;

    BEGIN
      RETURN TO_TIMESTAMP(l_value, 'FX' || l_format);
    EXCEPTION
      WHEN OTHERS THEN
        RAISE e_invalid_temporal_value;
    END;
  END required_timestamp;

  FUNCTION required_timestamp_tz(
    p_object         IN JSON_OBJECT_T,
    p_attribute_name IN t_attribute_name,
    p_format         IN VARCHAR2
  ) RETURN TIMESTAMP WITH TIME ZONE IS
    l_value VARCHAR2(32767);
  BEGIN
    l_value := required_string(p_object, p_attribute_name);

    BEGIN
      RETURN TO_TIMESTAMP_TZ(l_value, 'FX' || p_format);
    EXCEPTION
      WHEN OTHERS THEN
        RAISE e_invalid_temporal_value;
    END;
  END required_timestamp_tz;

  PROCEDURE assert_valid_attribute_name(
    p_attribute_name IN t_attribute_name
  ) IS
  BEGIN
    IF p_attribute_name IS NULL
       OR TRIM(p_attribute_name) IS NULL THEN
      RAISE e_invalid_attribute_name;
    END IF;
  END assert_valid_attribute_name;

  PROCEDURE assert_object_required(
    p_object IN JSON_OBJECT_T
  ) IS
  BEGIN
    IF p_object IS NULL THEN
      RAISE e_json_object_required;
    END IF;
  END assert_object_required;

  PROCEDURE assert_array_required(
    p_array IN JSON_ARRAY_T
  ) IS
  BEGIN
    IF p_array IS NULL THEN
      RAISE e_json_array_required;
    END IF;
  END assert_array_required;

  PROCEDURE assert_element_required(
    p_element IN JSON_ELEMENT_T
  ) IS
  BEGIN
    IF p_element IS NULL THEN
      RAISE e_invalid_json_element;
    END IF;
  END assert_element_required;

  PROCEDURE put_string(
    io_object        IN OUT NOCOPY JSON_OBJECT_T,
    p_attribute_name IN t_attribute_name,
    p_value          IN VARCHAR2
  ) IS
  BEGIN
    assert_object_required(io_object);
    assert_valid_attribute_name(p_attribute_name);

    IF p_value IS NULL THEN
      RAISE e_invalid_json_element;
    END IF;

    io_object.put(p_attribute_name, p_value);
  END put_string;

  PROCEDURE put_number(
    io_object        IN OUT NOCOPY JSON_OBJECT_T,
    p_attribute_name IN t_attribute_name,
    p_value          IN NUMBER
  ) IS
  BEGIN
    assert_object_required(io_object);
    assert_valid_attribute_name(p_attribute_name);

    IF p_value IS NULL THEN
      RAISE e_invalid_json_element;
    END IF;

    io_object.put(p_attribute_name, p_value);
  END put_number;

  PROCEDURE put_boolean(
    io_object        IN OUT NOCOPY JSON_OBJECT_T,
    p_attribute_name IN t_attribute_name,
    p_value          IN BOOLEAN
  ) IS
  BEGIN
    assert_object_required(io_object);
    assert_valid_attribute_name(p_attribute_name);

    IF p_value IS NULL THEN
      RAISE e_invalid_json_element;
    END IF;

    io_object.put(p_attribute_name, p_value);
  END put_boolean;

  PROCEDURE put_null(
    io_object        IN OUT NOCOPY JSON_OBJECT_T,
    p_attribute_name IN t_attribute_name
  ) IS
  BEGIN
    assert_object_required(io_object);
    assert_valid_attribute_name(p_attribute_name);

    io_object.put_null(p_attribute_name);
  END put_null;

  PROCEDURE put_element(
    io_object        IN OUT NOCOPY JSON_OBJECT_T,
    p_attribute_name IN t_attribute_name,
    p_value          IN JSON_ELEMENT_T
  ) IS
  BEGIN
    assert_object_required(io_object);
    assert_valid_attribute_name(p_attribute_name);
    assert_element_required(p_value);

    io_object.put(p_attribute_name, p_value);
  END put_element;

  PROCEDURE append_string(
    io_array IN OUT NOCOPY JSON_ARRAY_T,
    p_value  IN VARCHAR2
  ) IS
  BEGIN
    assert_array_required(io_array);

    IF p_value IS NULL THEN
      RAISE e_invalid_json_element;
    END IF;

    io_array.append(p_value);
  END append_string;

  PROCEDURE append_number(
    io_array IN OUT NOCOPY JSON_ARRAY_T,
    p_value  IN NUMBER
  ) IS
  BEGIN
    assert_array_required(io_array);

    IF p_value IS NULL THEN
      RAISE e_invalid_json_element;
    END IF;

    io_array.append(p_value);
  END append_number;

  PROCEDURE append_boolean(
    io_array IN OUT NOCOPY JSON_ARRAY_T,
    p_value  IN BOOLEAN
  ) IS
  BEGIN
    assert_array_required(io_array);

    IF p_value IS NULL THEN
      RAISE e_invalid_json_element;
    END IF;

    io_array.append(p_value);
  END append_boolean;

  PROCEDURE append_null(
    io_array IN OUT NOCOPY JSON_ARRAY_T
  ) IS
  BEGIN
    assert_array_required(io_array);

    io_array.append_null;
  END append_null;

  PROCEDURE append_element(
    io_array IN OUT NOCOPY JSON_ARRAY_T,
    p_value  IN JSON_ELEMENT_T
  ) IS
  BEGIN
    assert_array_required(io_array);
    assert_element_required(p_value);

    io_array.append(p_value);
  END append_element;

  FUNCTION serialize(
    p_element IN JSON_ELEMENT_T
  ) RETURN CLOB IS
  BEGIN
    assert_element_required(p_element);

    BEGIN
      RETURN p_element.to_clob;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE e_serialization_failed;
    END;
  END serialize;

  FUNCTION format_timestamp(
    p_value IN TIMESTAMP
  ) RETURN t_iso8601_value IS
  BEGIN
    IF p_value IS NULL THEN
      RAISE e_invalid_temporal_value;
    END IF;

    RETURN TO_CHAR(
             p_value,
             'YYYY-MM-DD"T"HH24:MI:SS.FF6'
           );
  END format_timestamp;

  FUNCTION format_timestamp_tz(
    p_value IN TIMESTAMP WITH TIME ZONE
  ) RETURN t_iso8601_value IS
  BEGIN
    IF p_value IS NULL THEN
      RAISE e_invalid_temporal_value;
    END IF;

    RETURN TO_CHAR(
             p_value,
             'YYYY-MM-DD"T"HH24:MI:SS.FF6TZH:TZM'
           );
  END format_timestamp_tz;
END core_json_pkg;
/
