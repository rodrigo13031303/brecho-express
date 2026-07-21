CREATE OR REPLACE PACKAGE BODY acc_password_pkg AS
  ------------------------------------------------------------------------------
  -- Constantes privadas
  ------------------------------------------------------------------------------

  c_format_version        CONSTANT VARCHAR2(10) := 'v1';
  c_algorithm             CONSTANT VARCHAR2(30) := 'SHA512';
  c_hash_type             CONSTANT PLS_INTEGER := DBMS_CRYPTO.HASH_SH512;
  c_salt_bytes            CONSTANT PLS_INTEGER := 16;
  c_hash_bytes            CONSTANT PLS_INTEGER := 64;
  c_separator             CONSTANT VARCHAR2(1) := '$';
  c_serialized_max_length CONSTANT PLS_INTEGER := 255;
  c_hex_chars_per_byte    CONSTANT PLS_INTEGER := 2;

  TYPE t_credential IS RECORD (
    format_version VARCHAR2(10),
    algorithm      VARCHAR2(30),
    salt           RAW(32767),
    hash_value     RAW(32767)
  );

  ------------------------------------------------------------------------------
  -- Helpers privados
  ------------------------------------------------------------------------------

  FUNCTION generate_salt
    RETURN RAW IS
  BEGIN
    RETURN DBMS_CRYPTO.RANDOMBYTES(c_salt_bytes);
  END generate_salt;

  FUNCTION calculate_hash(
    p_password IN VARCHAR2,
    p_salt     IN RAW
  ) RETURN RAW IS
  BEGIN
    RETURN DBMS_CRYPTO.HASH(
      src => UTL_RAW.CONCAT(
        UTL_I18N.STRING_TO_RAW(p_password, 'AL32UTF8'),
        p_salt
      ),
      typ => c_hash_type
    );
  END calculate_hash;

  FUNCTION serialize_credential(
    p_algorithm  IN VARCHAR2,
    p_salt       IN RAW,
    p_hash_value IN RAW
  ) RETURN VARCHAR2 IS
    l_credential VARCHAR2(32767);
  BEGIN
    l_credential := c_format_version
      || c_separator || p_algorithm
      || c_separator || RAWTOHEX(p_salt)
      || c_separator || RAWTOHEX(p_hash_value);

    IF LENGTH(l_credential) > c_serialized_max_length THEN
      RAISE VALUE_ERROR;
    END IF;

    RETURN l_credential;
  END serialize_credential;

  FUNCTION is_valid_hex(
    p_value           IN VARCHAR2,
    p_expected_length IN PLS_INTEGER
  ) RETURN BOOLEAN IS
  BEGIN
    RETURN p_value IS NOT NULL
       AND LENGTH(p_value) = p_expected_length
       AND REGEXP_LIKE(p_value, '^[0-9A-F]+$', 'c');
  END is_valid_hex;

  FUNCTION parse_credential(
    p_credential IN VARCHAR2,
    p_parsed     OUT t_credential
  ) RETURN BOOLEAN IS
    l_first_separator  PLS_INTEGER;
    l_second_separator PLS_INTEGER;
    l_third_separator  PLS_INTEGER;
    l_format_version   VARCHAR2(10);
    l_algorithm        VARCHAR2(30);
    l_salt_hex         VARCHAR2(32767);
    l_hash_hex         VARCHAR2(32767);
  BEGIN
    IF p_credential IS NULL
       OR LENGTH(p_credential) > c_serialized_max_length THEN
      RETURN FALSE;
    END IF;

    l_first_separator := INSTR(p_credential, c_separator, 1, 1);
    l_second_separator := INSTR(p_credential, c_separator, 1, 2);
    l_third_separator := INSTR(p_credential, c_separator, 1, 3);

    IF l_first_separator <= 1
       OR l_second_separator <= l_first_separator + 1
       OR l_third_separator <= l_second_separator + 1
       OR l_third_separator >= LENGTH(p_credential)
       OR INSTR(p_credential, c_separator, 1, 4) > 0 THEN
      RETURN FALSE;
    END IF;

    l_format_version := SUBSTR(p_credential, 1, l_first_separator - 1);
    l_algorithm := SUBSTR(
      p_credential,
      l_first_separator + 1,
      l_second_separator - l_first_separator - 1
    );
    l_salt_hex := SUBSTR(
      p_credential,
      l_second_separator + 1,
      l_third_separator - l_second_separator - 1
    );
    l_hash_hex := SUBSTR(p_credential, l_third_separator + 1);

    IF l_format_version <> c_format_version THEN
      RETURN FALSE;
    END IF;

    IF l_algorithm <> c_algorithm THEN
      RETURN FALSE;
    END IF;

    IF NOT is_valid_hex(
             l_salt_hex,
             c_salt_bytes * c_hex_chars_per_byte
           )
       OR NOT is_valid_hex(
                l_hash_hex,
                c_hash_bytes * c_hex_chars_per_byte
              ) THEN
      RETURN FALSE;
    END IF;

    p_parsed.format_version := l_format_version;
    p_parsed.algorithm := l_algorithm;
    p_parsed.salt := HEXTORAW(l_salt_hex);
    p_parsed.hash_value := HEXTORAW(l_hash_hex);

    RETURN TRUE;
  END parse_credential;

  FUNCTION raw_byte_value(
    p_value IN RAW,
    p_index IN PLS_INTEGER
  ) RETURN PLS_INTEGER IS
  BEGIN
    IF p_index > NVL(UTL_RAW.LENGTH(p_value), 0) THEN
      RETURN 0;
    END IF;

    RETURN TO_NUMBER(
      RAWTOHEX(UTL_RAW.SUBSTR(p_value, p_index, 1)),
      'XX'
    );
  END raw_byte_value;

  FUNCTION constant_time_equals(
    p_left  IN RAW,
    p_right IN RAW
  ) RETURN BOOLEAN IS
    l_left_length  PLS_INTEGER := NVL(UTL_RAW.LENGTH(p_left), 0);
    l_right_length PLS_INTEGER := NVL(UTL_RAW.LENGTH(p_right), 0);
    l_max_length   PLS_INTEGER;
    l_difference   PLS_INTEGER;
  BEGIN
    l_max_length := GREATEST(l_left_length, l_right_length);
    l_difference := ABS(l_left_length - l_right_length);

    FOR l_index IN 1 .. l_max_length LOOP
      l_difference := l_difference + ABS(
        raw_byte_value(p_left, l_index) - raw_byte_value(p_right, l_index)
      );
    END LOOP;

    CASE l_difference
      WHEN 0 THEN
        RETURN TRUE;
      ELSE
        RETURN FALSE;
    END CASE;
  END constant_time_equals;

  ------------------------------------------------------------------------------
  -- Operacoes publicas
  ------------------------------------------------------------------------------

  FUNCTION hash_password(
    p_password IN VARCHAR2
  ) RETURN VARCHAR2 IS
    l_salt       RAW(32767);
    l_hash_value RAW(32767);
  BEGIN
    IF p_password IS NULL THEN
      RAISE VALUE_ERROR;
    END IF;

    l_salt := generate_salt;
    l_hash_value := calculate_hash(p_password, l_salt);

    RETURN serialize_credential(c_algorithm, l_salt, l_hash_value);
  END hash_password;

  FUNCTION verify_password(
    p_password   IN VARCHAR2,
    p_credential IN VARCHAR2
  ) RETURN BOOLEAN IS
    l_parsed     t_credential;
    l_actual_hash RAW(32767);
  BEGIN
    IF p_password IS NULL OR p_credential IS NULL THEN
      RETURN FALSE;
    END IF;

    IF NOT parse_credential(p_credential, l_parsed) THEN
      RETURN FALSE;
    END IF;

    l_actual_hash := calculate_hash(p_password, l_parsed.salt);

    RETURN constant_time_equals(l_actual_hash, l_parsed.hash_value);
  END verify_password;
END acc_password_pkg;
/
