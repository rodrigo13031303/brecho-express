SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK ON
SET VERIFY OFF
SET LINESIZE 240
SET PAGESIZE 200
WHENEVER OSERROR EXIT FAILURE ROLLBACK
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

SPOOL google_x509_crypto_format_validation.log

PROMPT ============================================================
PROMPT BRECHO EXPRESS - GOOGLE X509 CRYPTO FORMAT
PROMPT Read-only validation using Google's current public certificate.
PROMPT The synthetic signature is intentionally from a different key.
PROMPT ============================================================

DECLARE
    c_signing_input CONSTANT VARCHAR2(4000) :=
        'eyJhbGciOiJSUzI1NiIsImtpZCI6ImJyZWNoby10ZXN0In0.eyJzdWIiOiJyc2EyNTYtY2FwYWJpbGl0eS10ZXN0IiwiaXNzIjoiYnJlY2hvLWV4cHJlc3MtdGVzdCJ9';
    c_signature_base64url CONSTANT VARCHAR2(4000) :=
        'j0S2gPu-Lr12P3FABV7kUeueXFmTfo6dQ7tO5WSX-Q28pZa6fSMu4ZygcnE3yD3V0iBBiHZxmns7ju0jyDp0RhT0Ae6_n3Ph-VhD8sblJXkNl02nuzbr_aozXHpaxRP5R8FfhgGKUsGvND8Y8X1aEr-RHpymTyjltLs09luh9sAi7_x3pIbcANSqTfC_Llbg41lEoH9wDPRfynltElvODx88SWi8Efge9D6lScoaBC2bTMTQco_LXI8jK2iFyfwvVnjM3JIZ0-HCJ2OocGoBHfyrB3Ngj_yFXQUZl-oU6ja-WvgWcuj1BfIgcw0oSVsJPbPDJdugLE4wsx2Dg1qwww';

    l_request       UTL_HTTP.req;
    l_response      UTL_HTTP.resp;
    l_body          VARCHAR2(32767);
    l_chunk         VARCHAR2(32767);
    l_json          JSON_OBJECT_T;
    l_keys          JSON_KEY_LIST;
    l_key_id        VARCHAR2(255);
    l_certificate   VARCHAR2(32767);
    l_verified      BOOLEAN;
    l_response_open BOOLEAN := FALSE;

    FUNCTION base64url_decode(
        p_value IN VARCHAR2
    ) RETURN RAW IS
        l_value VARCHAR2(32767);
    BEGIN
        l_value := REPLACE(REPLACE(p_value, '-', '+'), '_', '/');
        l_value := l_value || RPAD('=', MOD(4 - MOD(LENGTH(l_value), 4), 4), '=');
        RETURN UTL_ENCODE.base64_decode(UTL_RAW.cast_to_raw(l_value));
    END base64url_decode;
BEGIN
    UTL_HTTP.set_detailed_excp_support(TRUE);
    UTL_HTTP.set_transfer_timeout(15);

    l_request := UTL_HTTP.begin_request(
        url          => 'https://www.googleapis.com/oauth2/v1/certs',
        method       => 'GET',
        http_version => 'HTTP/1.1'
    );
    UTL_HTTP.set_header(l_request, 'Accept', 'application/json');
    UTL_HTTP.set_header(l_request, 'User-Agent', 'BrechoExpress-Oracle-X509Check/1.0');

    l_response := UTL_HTTP.get_response(l_request);
    l_response_open := TRUE;

    IF l_response.status_code <> 200 THEN
        RAISE_APPLICATION_ERROR(
            -20994,
            'Google certificate endpoint returned HTTP ' || l_response.status_code
        );
    END IF;

    BEGIN
        LOOP
            UTL_HTTP.read_text(l_response, l_chunk, 8000);
            l_body := l_body || l_chunk;
        END LOOP;
    EXCEPTION
        WHEN UTL_HTTP.end_of_body THEN
            NULL;
    END;

    UTL_HTTP.end_response(l_response);
    l_response_open := FALSE;

    l_json := JSON_OBJECT_T.parse(l_body);
    l_keys := l_json.get_keys;

    IF l_keys.COUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20995, 'Google returned no X.509 certificate.');
    END IF;

    l_key_id := l_keys(1);
    l_certificate := l_json.get_string(l_key_id);

    IF INSTR(l_certificate, '-----BEGIN CERTIFICATE-----') <> 1
       OR INSTR(l_certificate, '-----END CERTIFICATE-----') = 0
    THEN
        RAISE_APPLICATION_ERROR(-20996, 'Google X.509 certificate is malformed.');
    END IF;

    DBMS_OUTPUT.put_line('[PASS] Google X.509 certificate retrieved');
    DBMS_OUTPUT.put_line('       kid=' || l_key_id);

    l_verified := DBMS_CRYPTO.verify(
        src        => UTL_RAW.cast_to_raw(c_signing_input),
        sign       => base64url_decode(c_signature_base64url),
        pub_key    => UTL_I18N.string_to_raw(l_certificate, 'AL32UTF8'),
        pubkey_alg => DBMS_CRYPTO.KEY_TYPE_RSA,
        sign_alg   => DBMS_CRYPTO.SIGN_SHA256_RSA
    );

    IF l_verified THEN
        RAISE_APPLICATION_ERROR(
            -20997,
            'Unexpected match between unrelated synthetic and Google keys.'
        );
    END IF;

    DBMS_OUTPUT.put_line('[PASS] DBMS_CRYPTO parsed the Google X.509 certificate');
    DBMS_OUTPUT.put_line('[PASS] Unrelated synthetic signature was rejected');
    DBMS_OUTPUT.put_line('');
    DBMS_OUTPUT.put_line('RESULT: GOOGLE_X509_FORMAT_READY');
EXCEPTION
    WHEN OTHERS THEN
        IF l_response_open THEN
            BEGIN
                UTL_HTTP.end_response(l_response);
            EXCEPTION
                WHEN OTHERS THEN NULL;
            END;
        END IF;
        RAISE;
END;
/

SPOOL OFF

PROMPT Validation completed.
PROMPT Log: google_x509_crypto_format_validation.log

