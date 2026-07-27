CREATE OR REPLACE PACKAGE core_json_pkg AS
  SUBTYPE t_attribute_name IS VARCHAR2(32767);
  SUBTYPE t_iso8601_value  IS VARCHAR2(40);

  e_invalid_attribute_name EXCEPTION;
  e_json_object_required   EXCEPTION;
  e_json_array_required    EXCEPTION;
  e_invalid_json_element   EXCEPTION;
  e_serialization_failed   EXCEPTION;
  e_invalid_temporal_value EXCEPTION;
  e_request_body_required  EXCEPTION;
  e_invalid_json           EXCEPTION;
  e_required_attribute     EXCEPTION;
  e_invalid_attribute_type EXCEPTION;
  e_unknown_attribute      EXCEPTION;

  FUNCTION parse_object(
    p_request_body IN CLOB
  ) RETURN JSON_OBJECT_T;

  FUNCTION required_string(
    p_object         IN JSON_OBJECT_T,
    p_attribute_name IN t_attribute_name
  ) RETURN VARCHAR2;

  FUNCTION required_number(
    p_object         IN JSON_OBJECT_T,
    p_attribute_name IN t_attribute_name
  ) RETURN NUMBER;

  FUNCTION required_boolean(
    p_object         IN JSON_OBJECT_T,
    p_attribute_name IN t_attribute_name
  ) RETURN BOOLEAN;

  FUNCTION optional_string(
    p_object         IN JSON_OBJECT_T,
    p_attribute_name IN t_attribute_name
  ) RETURN VARCHAR2;

  FUNCTION required_array(
    p_object         IN JSON_OBJECT_T,
    p_attribute_name IN t_attribute_name
  ) RETURN JSON_ARRAY_T;

  PROCEDURE assert_allowed_attributes(
    p_object      IN JSON_OBJECT_T,
    p_allowed_csv IN VARCHAR2
  );

  FUNCTION required_timestamp(
    p_object         IN JSON_OBJECT_T,
    p_attribute_name IN t_attribute_name,
    p_format         IN VARCHAR2
  ) RETURN TIMESTAMP;

  FUNCTION required_timestamp_tz(
    p_object         IN JSON_OBJECT_T,
    p_attribute_name IN t_attribute_name,
    p_format         IN VARCHAR2
  ) RETURN TIMESTAMP WITH TIME ZONE;

  PROCEDURE put_string(
    io_object        IN OUT NOCOPY JSON_OBJECT_T,
    p_attribute_name IN t_attribute_name,
    p_value          IN VARCHAR2
  );

  PROCEDURE put_number(
    io_object        IN OUT NOCOPY JSON_OBJECT_T,
    p_attribute_name IN t_attribute_name,
    p_value          IN NUMBER
  );

  PROCEDURE put_boolean(
    io_object        IN OUT NOCOPY JSON_OBJECT_T,
    p_attribute_name IN t_attribute_name,
    p_value          IN BOOLEAN
  );

  PROCEDURE put_null(
    io_object        IN OUT NOCOPY JSON_OBJECT_T,
    p_attribute_name IN t_attribute_name
  );

  PROCEDURE put_element(
    io_object        IN OUT NOCOPY JSON_OBJECT_T,
    p_attribute_name IN t_attribute_name,
    p_value          IN JSON_ELEMENT_T
  );

  PROCEDURE append_string(
    io_array IN OUT NOCOPY JSON_ARRAY_T,
    p_value  IN VARCHAR2
  );

  PROCEDURE append_number(
    io_array IN OUT NOCOPY JSON_ARRAY_T,
    p_value  IN NUMBER
  );

  PROCEDURE append_boolean(
    io_array IN OUT NOCOPY JSON_ARRAY_T,
    p_value  IN BOOLEAN
  );

  PROCEDURE append_null(
    io_array IN OUT NOCOPY JSON_ARRAY_T
  );

  PROCEDURE append_element(
    io_array IN OUT NOCOPY JSON_ARRAY_T,
    p_value  IN JSON_ELEMENT_T
  );

  FUNCTION serialize(
    p_element IN JSON_ELEMENT_T
  ) RETURN CLOB;

  FUNCTION format_timestamp(
    p_value IN TIMESTAMP
  ) RETURN t_iso8601_value;

  FUNCTION format_timestamp_tz(
    p_value IN TIMESTAMP WITH TIME ZONE
  ) RETURN t_iso8601_value;
END core_json_pkg;
/
