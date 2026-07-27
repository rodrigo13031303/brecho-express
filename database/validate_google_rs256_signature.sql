SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK ON
SET VERIFY OFF
SET LINESIZE 240
SET PAGESIZE 200
WHENEVER OSERROR EXIT FAILURE ROLLBACK
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

SPOOL google_rs256_signature_validation.log

PROMPT ============================================================
PROMPT BRECHO EXPRESS - GOOGLE RS256 SIGNATURE CAPABILITY
PROMPT Read-only validation with a synthetic public test vector.
PROMPT No Google credential or production secret is used.
PROMPT ============================================================

DECLARE
    c_modulus_base64url CONSTANT VARCHAR2(4000) :=
        'wVKc6USMg3vCc2Sn7hb9sqd3pZDBGVFw0W8TeEYmRjdYAVSnMPfmz6mPDWn7WH80fbizQL6Fg9tVSreIoxAzxvEtEkSpxrjBWpDrsS0J8CdJWbSxDQcx-dxicGhbu5hxqiTmSX7ribjGTFEKQh5lyYOimjYD5sPW3Ni2grd4cs3REUjzN-_CwIXJIhD_vYDw6Dk-I6HlkKd0bz3U_A9mwgBh8o6XNpSM_FhwE3_s7D5ats4F3ccbWD9Xew3GSlzMT-g0UEGQUa3uWmuyTfppbz1LPG7fuTMdyFj8ZHa9Ql0D96VCYnr7P6GwRK4IZg6Dy7D6ewnSMFCFMcuqbqV4jw';
    c_exponent_base64url CONSTANT VARCHAR2(100) := 'AQAB';
    c_signing_input CONSTANT VARCHAR2(4000) :=
        'eyJhbGciOiJSUzI1NiIsImtpZCI6ImJyZWNoby10ZXN0In0.eyJzdWIiOiJyc2EyNTYtY2FwYWJpbGl0eS10ZXN0IiwiaXNzIjoiYnJlY2hvLWV4cHJlc3MtdGVzdCJ9';
    c_signature_base64url CONSTANT VARCHAR2(4000) :=
        'j0S2gPu-Lr12P3FABV7kUeueXFmTfo6dQ7tO5WSX-Q28pZa6fSMu4ZygcnE3yD3V0iBBiHZxmns7ju0jyDp0RhT0Ae6_n3Ph-VhD8sblJXkNl02nuzbr_aozXHpaxRP5R8FfhgGKUsGvND8Y8X1aEr-RHpymTyjltLs09luh9sAi7_x3pIbcANSqTfC_Llbg41lEoH9wDPRfynltElvODx88SWi8Efge9D6lScoaBC2bTMTQco_LXI8jK2iFyfwvVnjM3JIZ0-HCJ2OocGoBHfyrB3Ngj_yFXQUZl-oU6ja-WvgWcuj1BfIgcw0oSVsJPbPDJdugLE4wsx2Dg1qwww';
    c_expected_spki_hex CONSTANT VARCHAR2(4000) :=
        '30820122300D06092A864886F70D01010105000382010F003082010A0282010100C1529CE9448C837BC27364A7EE16FDB2A777A590C1195170D16F137846264637580154A730F7E6CFA98F0D69FB587F347DB8B340BE8583DB554AB788A31033C6F12D1244A9C6B8C15A90EBB12D09F0274959B4B10D0731F9DC6270685BBB9871AA24E6497EEB89B8C64C510A421E65C983A29A3603E6C3D6DCD8B682B77872CDD11148F337EFC2C085C92210FFBD80F0E8393E23A1E590A7746F3DD4FC0F66C20061F28E9736948CFC5870137FECEC3E5AB6CE05DDC71B583F577B0DC64A5CCC4FE83450419051ADEE5A6BB24DFA696F3D4B3C6EDFB9331DC858FC6476BD425D03F7A542627AFB3FA1B044AE08660E83CBB0FA7B09D230508531CBAA6EA5788F0203010001';

    l_public_key RAW(32767);
    l_pkcs1_key  RAW(32767);
    l_signature  RAW(32767);
    l_verified   BOOLEAN;
    l_successes  PLS_INTEGER := 0;
    l_working_key RAW(32767);

    FUNCTION base64url_decode(
        p_value IN VARCHAR2
    ) RETURN RAW IS
        l_value VARCHAR2(32767);
    BEGIN
        l_value := REPLACE(REPLACE(p_value, '-', '+'), '_', '/');
        l_value := l_value || RPAD('=', MOD(4 - MOD(LENGTH(l_value), 4), 4), '=');
        RETURN UTL_ENCODE.base64_decode(UTL_RAW.cast_to_raw(l_value));
    END base64url_decode;

    FUNCTION der_length(
        p_length IN PLS_INTEGER
    ) RETURN RAW IS
        l_binary RAW(4);
        l_hex    VARCHAR2(8);
    BEGIN
        l_binary := UTL_RAW.cast_from_binary_integer(
            p_length,
            UTL_RAW.big_endian
        );
        l_hex := RAWTOHEX(l_binary);

        IF p_length < 128 THEN
            RETURN HEXTORAW(SUBSTR(l_hex, 7, 2));
        ELSIF p_length <= 255 THEN
            RETURN HEXTORAW('81' || SUBSTR(l_hex, 7, 2));
        ELSE
            RETURN HEXTORAW('82' || SUBSTR(l_hex, 5, 4));
        END IF;
    END der_length;

    FUNCTION der_integer(
        p_value IN RAW
    ) RETURN RAW IS
        l_value RAW(32767) := p_value;
    BEGIN
        IF TO_NUMBER(SUBSTR(RAWTOHEX(l_value), 1, 2), 'XX') >= 128 THEN
            l_value := UTL_RAW.concat(HEXTORAW('00'), l_value);
        END IF;

        RETURN UTL_RAW.concat(
            HEXTORAW('02'),
            der_length(UTL_RAW.length(l_value)),
            l_value
        );
    END der_integer;

    FUNCTION rsa_spki(
        p_modulus IN RAW,
        p_exponent IN RAW
    ) RETURN RAW IS
        l_rsa_public_key RAW(32767);
        l_bit_string     RAW(32767);
        l_spki_body      RAW(32767);
    BEGIN
        l_rsa_public_key := UTL_RAW.concat(
            der_integer(p_modulus),
            der_integer(p_exponent)
        );
        l_rsa_public_key := UTL_RAW.concat(
            HEXTORAW('30'),
            der_length(UTL_RAW.length(l_rsa_public_key)),
            l_rsa_public_key
        );

        l_bit_string := UTL_RAW.concat(
            HEXTORAW('00'),
            l_rsa_public_key
        );
        l_bit_string := UTL_RAW.concat(
            HEXTORAW('03'),
            der_length(UTL_RAW.length(l_bit_string)),
            l_bit_string
        );

        l_spki_body := UTL_RAW.concat(
            HEXTORAW('300D06092A864886F70D0101010500'),
            l_bit_string
        );

        RETURN UTL_RAW.concat(
            HEXTORAW('30'),
            der_length(UTL_RAW.length(l_spki_body)),
            l_spki_body
        );
    END rsa_spki;

    FUNCTION raw_to_pem(
        p_key        IN RAW,
        p_label      IN VARCHAR2,
        p_line_break IN VARCHAR2
    ) RETURN RAW IS
        l_base64 VARCHAR2(32767);
        l_pem    VARCHAR2(32767);
        l_offset PLS_INTEGER := 1;
    BEGIN
        l_base64 := UTL_RAW.cast_to_varchar2(
            UTL_ENCODE.base64_encode(p_key)
        );
        l_base64 := REPLACE(REPLACE(l_base64, CHR(13), NULL), CHR(10), NULL);

        l_pem := '-----BEGIN ' || p_label || '-----' || p_line_break;
        WHILE l_offset <= LENGTH(l_base64) LOOP
            l_pem := l_pem
                || SUBSTR(l_base64, l_offset, 64)
                || p_line_break;
            l_offset := l_offset + 64;
        END LOOP;
        l_pem := l_pem
            || '-----END ' || p_label || '-----'
            || p_line_break;

        RETURN UTL_I18N.string_to_raw(l_pem, 'AL32UTF8');
    END raw_to_pem;

    PROCEDURE try_key_format(
        p_name IN VARCHAR2,
        p_key  IN RAW
    ) IS
        l_result BOOLEAN;
    BEGIN
        l_result := DBMS_CRYPTO.verify(
            src        => UTL_RAW.cast_to_raw(c_signing_input),
            sign       => l_signature,
            pub_key    => p_key,
            pubkey_alg => DBMS_CRYPTO.KEY_TYPE_RSA,
            sign_alg   => DBMS_CRYPTO.SIGN_SHA256_RSA
        );

        IF l_result THEN
            l_successes := l_successes + 1;
            IF l_working_key IS NULL THEN
                l_working_key := p_key;
            END IF;
            DBMS_OUTPUT.put_line('[PASS] ' || RPAD(p_name, 24) || ' valid signature accepted');
        ELSE
            DBMS_OUTPUT.put_line('[FAIL] ' || RPAD(p_name, 24) || ' signature returned FALSE');
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.put_line('[FAIL] ' || RPAD(p_name, 24) || ' ' || SQLERRM);
    END try_key_format;

BEGIN
    l_pkcs1_key := UTL_RAW.concat(
        der_integer(base64url_decode(c_modulus_base64url)),
        der_integer(base64url_decode(c_exponent_base64url))
    );
    l_pkcs1_key := UTL_RAW.concat(
        HEXTORAW('30'),
        der_length(UTL_RAW.length(l_pkcs1_key)),
        l_pkcs1_key
    );

    l_public_key := rsa_spki(
        base64url_decode(c_modulus_base64url),
        base64url_decode(c_exponent_base64url)
    );

    IF RAWTOHEX(l_public_key) <> c_expected_spki_hex THEN
        RAISE_APPLICATION_ERROR(
            -20991,
            'Generated SubjectPublicKeyInfo does not match the reference DER.'
        );
    END IF;
    DBMS_OUTPUT.put_line('[PASS] Google JWK n/e converted to RSA SubjectPublicKeyInfo DER');

    l_signature := base64url_decode(c_signature_base64url);

    try_key_format('SPKI DER', l_public_key);
    try_key_format(
        'SPKI PEM LF',
        raw_to_pem(l_public_key, 'PUBLIC KEY', CHR(10))
    );
    try_key_format(
        'SPKI PEM CRLF',
        raw_to_pem(l_public_key, 'PUBLIC KEY', CHR(13) || CHR(10))
    );
    try_key_format('PKCS1 DER', l_pkcs1_key);
    try_key_format(
        'PKCS1 PEM LF',
        raw_to_pem(l_pkcs1_key, 'RSA PUBLIC KEY', CHR(10))
    );
    try_key_format(
        'PKCS1 PEM CRLF',
        raw_to_pem(l_pkcs1_key, 'RSA PUBLIC KEY', CHR(13) || CHR(10))
    );

    IF l_successes = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20992,
            'DBMS_CRYPTO rejected all supported RSA public-key encodings.'
        );
    END IF;

    l_verified := DBMS_CRYPTO.verify(
        src        => UTL_RAW.cast_to_raw(c_signing_input || 'tampered'),
        sign       => l_signature,
        pub_key    => l_working_key,
        pubkey_alg => DBMS_CRYPTO.KEY_TYPE_RSA,
        sign_alg   => DBMS_CRYPTO.SIGN_SHA256_RSA
    );

    IF l_verified THEN
        RAISE_APPLICATION_ERROR(
            -20993,
            'DBMS_CRYPTO accepted a tampered RS256 signing input.'
        );
    END IF;
    DBMS_OUTPUT.put_line('[PASS] DBMS_CRYPTO rejected the tampered signing input');
    DBMS_OUTPUT.put_line('');
    DBMS_OUTPUT.put_line('RESULT: RS256_VERIFICATION_READY');
END;
/

SPOOL OFF

PROMPT Validation completed.
PROMPT Log: google_rs256_signature_validation.log
