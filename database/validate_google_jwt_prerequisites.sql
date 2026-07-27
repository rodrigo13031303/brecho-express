SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK ON
SET VERIFY OFF
SET LINESIZE 240
SET PAGESIZE 200
WHENEVER OSERROR EXIT FAILURE ROLLBACK
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

SPOOL google_jwt_prerequisites_validation.log

PROMPT ============================================================
PROMPT BRECHO EXPRESS - GOOGLE JWT PREREQUISITES
PROMPT Read-only validation. No database object is changed.
PROMPT ============================================================

DECLARE
    l_crypto_ok       BOOLEAN := FALSE;
    l_http_ok         BOOLEAN := FALSE;
    l_key_type_rsa    PLS_INTEGER;
    l_sign_sha256_rsa PLS_INTEGER;
    l_request         UTL_HTTP.req;
    l_response        UTL_HTTP.resp;
    l_body            VARCHAR2(32767);
    l_chunk           VARCHAR2(32767);
    l_cache_control   VARCHAR2(4000);
    l_response_open   BOOLEAN := FALSE;

    PROCEDURE print_failure(
        p_check   IN VARCHAR2,
        p_message IN VARCHAR2
    ) IS
    BEGIN
        DBMS_OUTPUT.put_line('[FAIL] ' || RPAD(p_check, 24) || ' ' || p_message);
    END print_failure;
BEGIN
    DBMS_OUTPUT.put_line('Database: ' || SYS_CONTEXT('USERENV', 'DB_NAME'));
    DBMS_OUTPUT.put_line('Schema  : ' || SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA'));
    DBMS_OUTPUT.put_line('');

    BEGIN
        EXECUTE IMMEDIATE
            'BEGIN
                 :key_type_rsa := DBMS_CRYPTO.KEY_TYPE_RSA;
                 :sign_alg     := DBMS_CRYPTO.SIGN_SHA256_RSA;
             END;'
            USING OUT l_key_type_rsa, OUT l_sign_sha256_rsa;

        l_crypto_ok := TRUE;
        DBMS_OUTPUT.put_line(
            '[PASS] DBMS_CRYPTO RSA/SHA-256'
            || ' KEY_TYPE_RSA=' || l_key_type_rsa
            || ', SIGN_SHA256_RSA=' || l_sign_sha256_rsa
        );
    EXCEPTION
        WHEN OTHERS THEN
            print_failure(
                'DBMS_CRYPTO RSA/SHA-256',
                SQLERRM
            );
    END;

    BEGIN
        SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END
          INTO l_key_type_rsa
          FROM ALL_ARGUMENTS
         WHERE OWNER = 'SYS'
           AND PACKAGE_NAME = 'DBMS_CRYPTO'
           AND OBJECT_NAME = 'VERIFY';

        IF l_key_type_rsa = 1 THEN
            DBMS_OUTPUT.put_line('[PASS] DBMS_CRYPTO.VERIFY     procedure is visible');
        ELSE
            print_failure('DBMS_CRYPTO.VERIFY', 'procedure is not visible');
            l_crypto_ok := FALSE;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            print_failure('DBMS_CRYPTO.VERIFY', SQLERRM);
            l_crypto_ok := FALSE;
    END;

    BEGIN
        UTL_HTTP.set_detailed_excp_support(TRUE);
        UTL_HTTP.set_transfer_timeout(15);

        l_request := UTL_HTTP.begin_request(
            url          => 'https://www.googleapis.com/oauth2/v3/certs',
            method       => 'GET',
            http_version => 'HTTP/1.1'
        );
        UTL_HTTP.set_follow_redirect(l_request, 3);
        UTL_HTTP.set_header(l_request, 'User-Agent', 'BrechoExpress-Oracle-PrerequisiteCheck/1.0');
        UTL_HTTP.set_header(l_request, 'Accept', 'application/json');

        l_response := UTL_HTTP.get_response(l_request);
        l_response_open := TRUE;

        FOR i IN 1 .. UTL_HTTP.get_header_count(l_response) LOOP
            UTL_HTTP.get_header(l_response, i, l_chunk, l_body);
            IF LOWER(l_chunk) = 'cache-control' THEN
                l_cache_control := l_body;
            END IF;
        END LOOP;

        l_body := NULL;
        BEGIN
            LOOP
                UTL_HTTP.read_text(l_response, l_chunk, 8000);
                l_body := l_body || l_chunk;
                EXIT WHEN LENGTH(l_body) >= 16000;
            END LOOP;
        EXCEPTION
            WHEN UTL_HTTP.end_of_body THEN
                NULL;
        END;

        UTL_HTTP.end_response(l_response);
        l_response_open := FALSE;

        IF l_response.status_code = 200
           AND INSTR(l_body, '"keys"') > 0
           AND INSTR(l_body, '"kid"') > 0
           AND INSTR(l_body, '"n"') > 0
           AND INSTR(l_body, '"e"') > 0
        THEN
            l_http_ok := TRUE;
            DBMS_OUTPUT.put_line('[PASS] Google JWKS HTTPS       HTTP 200 with RSA keys');
            DBMS_OUTPUT.put_line('       Cache-Control           ' || NVL(l_cache_control, '(not returned)'));
        ELSE
            print_failure(
                'Google JWKS HTTPS',
                'HTTP ' || l_response.status_code || ' ' || l_response.reason_phrase
            );
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            IF l_response_open THEN
                BEGIN
                    UTL_HTTP.end_response(l_response);
                EXCEPTION
                    WHEN OTHERS THEN NULL;
                END;
            END IF;

            print_failure('Google JWKS HTTPS', SQLERRM);
            BEGIN
                DBMS_OUTPUT.put_line('       Detailed error          ' || UTL_HTTP.get_detailed_sqlerrm);
            EXCEPTION
                WHEN OTHERS THEN NULL;
            END;
    END;

    DBMS_OUTPUT.put_line('');
    DBMS_OUTPUT.put_line('------------------------------------------------------------');
    IF l_crypto_ok AND l_http_ok THEN
        DBMS_OUTPUT.put_line('RESULT: READY');
        DBMS_OUTPUT.put_line('Oracle can verify RS256 and retrieve Google rotating keys.');
    ELSIF l_crypto_ok THEN
        DBMS_OUTPUT.put_line('RESULT: NETWORK_CONFIGURATION_REQUIRED');
        DBMS_OUTPUT.put_line('RS256 is available, but Oracle cannot retrieve Google keys yet.');
        DBMS_OUTPUT.put_line('The failure above identifies ACL, DNS, TLS, or wallet configuration.');
    ELSE
        DBMS_OUTPUT.put_line('RESULT: CRYPTO_CAPABILITY_REQUIRED');
        DBMS_OUTPUT.put_line('Do not implement Google token verification in PL/SQL on this runtime.');
    END IF;
    DBMS_OUTPUT.put_line('------------------------------------------------------------');
END;
/

SPOOL OFF

PROMPT Validation completed.
PROMPT Log: google_jwt_prerequisites_validation.log
