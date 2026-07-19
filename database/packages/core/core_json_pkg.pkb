CREATE OR REPLACE PACKAGE BODY core_json_pkg AS
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
