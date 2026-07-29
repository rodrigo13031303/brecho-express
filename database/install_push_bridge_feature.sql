SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF
SET ECHO ON
SET FEEDBACK ON
WHENEVER OSERROR EXIT FAILURE ROLLBACK
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

SPOOL push_bridge_installation.log

PROMPT ============================================================
PROMPT BRECHO EXPRESS - SELF-HOSTED FIREBASE PUSH BRIDGE
PROMPT ============================================================

DECLARE
  l_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*) INTO l_count
    FROM USER_TABLES
   WHERE TABLE_NAME = 'BEX_PUSH_BRIDGE_CONFIG';

  IF l_count = 0 THEN
    EXECUTE IMMEDIATE q'~
      CREATE TABLE BEX_PUSH_BRIDGE_CONFIG(
        PBC_ID NUMBER(1) NOT NULL,
        PBC_KEY_HASH CHAR(64 CHAR) NOT NULL,
        PBC_STATUS VARCHAR2(20 CHAR) DEFAULT 'ACTIVE' NOT NULL,
        PBC_CREATED_AT TIMESTAMP(6)
          DEFAULT SYSTIMESTAMP NOT NULL,
        PBC_UPDATED_AT TIMESTAMP(6)
          DEFAULT SYSTIMESTAMP NOT NULL,
        CONSTRAINT PK_PUSH_BRIDGE_CONFIG PRIMARY KEY(PBC_ID),
        CONSTRAINT CK_PUSH_BRIDGE_SINGLETON CHECK(PBC_ID = 1),
        CONSTRAINT CK_PUSH_BRIDGE_STATUS
          CHECK(PBC_STATUS IN('ACTIVE','DISABLED'))
      )
    ~';
  END IF;
END;
/

CREATE OR REPLACE PACKAGE BEX_PUSH_BRIDGE_PKG AS
  e_unauthorized EXCEPTION;
  e_invalid_request EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_unauthorized, -20881);
  PRAGMA EXCEPTION_INIT(e_invalid_request, -20882);

  PROCEDURE CONFIGURE_KEY(P_KEY VARCHAR2);
  FUNCTION CLAIM(P_KEY VARCHAR2) RETURN CLOB;
  PROCEDURE ACKNOWLEDGE(P_KEY VARCHAR2, P_BODY CLOB);
END BEX_PUSH_BRIDGE_PKG;
/

CREATE OR REPLACE PACKAGE BODY BEX_PUSH_BRIDGE_PKG AS
  FUNCTION KEY_HASH(P_KEY VARCHAR2) RETURN VARCHAR2 IS
    l_hash VARCHAR2(64);
  BEGIN
    SELECT LOWER(RAWTOHEX(STANDARD_HASH(TRIM(P_KEY), 'SHA256')))
      INTO l_hash FROM DUAL;
    RETURN l_hash;
  END;

  PROCEDURE ASSERT_KEY(P_KEY VARCHAR2) IS
    l_count PLS_INTEGER;
    l_key_hash VARCHAR2(64);
  BEGIN
    IF LENGTH(TRIM(P_KEY)) < 32 THEN RAISE e_unauthorized; END IF;
    l_key_hash := KEY_HASH(P_KEY);
    SELECT COUNT(*) INTO l_count
      FROM BEX_PUSH_BRIDGE_CONFIG
     WHERE PBC_ID = 1
       AND PBC_STATUS = 'ACTIVE'
       AND PBC_KEY_HASH = l_key_hash;
    IF l_count <> 1 THEN RAISE e_unauthorized; END IF;
  END;

  PROCEDURE CONFIGURE_KEY(P_KEY VARCHAR2) IS
    l_key_hash VARCHAR2(64);
  BEGIN
    IF LENGTH(TRIM(P_KEY)) < 32 THEN RAISE e_invalid_request; END IF;
    l_key_hash := KEY_HASH(P_KEY);
    MERGE INTO BEX_PUSH_BRIDGE_CONFIG target
    USING(SELECT 1 PBC_ID FROM DUAL) source
       ON(target.PBC_ID = source.PBC_ID)
    WHEN MATCHED THEN UPDATE SET
      target.PBC_KEY_HASH = l_key_hash,
      target.PBC_STATUS = 'ACTIVE',
      target.PBC_UPDATED_AT = SYS_EXTRACT_UTC(SYSTIMESTAMP)
    WHEN NOT MATCHED THEN INSERT(PBC_ID, PBC_KEY_HASH, PBC_STATUS)
      VALUES(1, l_key_hash, 'ACTIVE');
  END;

  FUNCTION CLAIM(P_KEY VARCHAR2) RETURN CLOB IS
    l_message JSON_OBJECT_T;
    l_tokens JSON_ARRAY_T;
    l_result CLOB;
  BEGIN
    ASSERT_KEY(P_KEY);

    UPDATE BEX_PUSH_OUTBOX
       SET PBO_STATUS = 'PENDING',
           PBO_NEXT_ATTEMPT_AT = SYS_EXTRACT_UTC(SYSTIMESTAMP),
           PBO_LAST_ERROR = 'Recovered after bridge timeout',
           PBO_UPDATED_AT = SYS_EXTRACT_UTC(SYSTIMESTAMP)
     WHERE PBO_STATUS = 'PROCESSING'
       AND PBO_UPDATED_AT <
           SYS_EXTRACT_UTC(SYSTIMESTAMP) - INTERVAL '2' MINUTE;

    FOR item_data IN(
      SELECT outbox_data.PBO_ID,
             TRIM(outbox_data.PBO_PUBLIC_ID) PBO_PUBLIC_ID,
             outbox_data.PBO_TYPE,
             outbox_data.PBO_TITLE,
             outbox_data.PBO_BODY,
             outbox_data.PBO_DATA
        FROM BEX_PUSH_OUTBOX outbox_data
       WHERE outbox_data.PBO_STATUS = 'PENDING'
         AND outbox_data.PBO_NEXT_ATTEMPT_AT <=
             SYS_EXTRACT_UTC(SYSTIMESTAMP)
         AND EXISTS(
           SELECT 1 FROM BEX_PUSH_DEVICE device_data
            WHERE device_data.PFL_ID = outbox_data.PFL_ID
              AND device_data.PUD_STATUS = 'ACTIVE'
         )
       ORDER BY outbox_data.PBO_ID
       FOR UPDATE SKIP LOCKED
    ) LOOP
      l_message := JSON_OBJECT_T();
      l_tokens := JSON_ARRAY_T();
      core_json_pkg.put_string(
        l_message, 'outboxPublicId', item_data.PBO_PUBLIC_ID
      );
      core_json_pkg.put_string(l_message, 'type', item_data.PBO_TYPE);
      core_json_pkg.put_string(l_message, 'title', item_data.PBO_TITLE);
      core_json_pkg.put_string(l_message, 'body', item_data.PBO_BODY);
      BEGIN
        l_message.put(
          'data',
          JSON_ELEMENT_T.parse(NVL(item_data.PBO_DATA, '{}'))
        );
      EXCEPTION WHEN OTHERS THEN
        l_message.put('data', JSON_OBJECT_T());
      END;

      FOR device_data IN(
        SELECT device.PUD_TOKEN
          FROM BEX_PUSH_DEVICE device
          JOIN BEX_PUSH_OUTBOX outbox_data
            ON outbox_data.PFL_ID = device.PFL_ID
         WHERE outbox_data.PBO_ID = item_data.PBO_ID
           AND device.PUD_STATUS = 'ACTIVE'
         ORDER BY device.PUD_ID
      ) LOOP
        l_tokens.append(device_data.PUD_TOKEN);
      END LOOP;
      l_message.put('tokens', l_tokens);

      UPDATE BEX_PUSH_OUTBOX
         SET PBO_STATUS = 'PROCESSING',
             PBO_ATTEMPTS = PBO_ATTEMPTS + 1,
             PBO_UPDATED_AT = SYS_EXTRACT_UTC(SYSTIMESTAMP)
       WHERE PBO_ID = item_data.PBO_ID;
      l_result := l_message.to_clob();
      EXIT;
    END LOOP;

    COMMIT;
    RETURN l_result;
  END;

  PROCEDURE ACKNOWLEDGE(P_KEY VARCHAR2, P_BODY CLOB) IS
    l_request JSON_OBJECT_T;
    l_public_id VARCHAR2(32);
    l_success BOOLEAN;
    l_error VARCHAR2(2000);
    l_invalid_tokens JSON_ARRAY_T;
  BEGIN
    ASSERT_KEY(P_KEY);
    BEGIN
      l_request := JSON_OBJECT_T.parse(P_BODY);
      l_public_id := LOWER(TRIM(
        l_request.get_string('outboxPublicId')
      ));
      l_success := l_request.get_boolean('success');
      IF l_request.has('error') AND NOT l_request.get('error').is_null THEN
        l_error := SUBSTR(l_request.get_string('error'), 1, 2000);
      END IF;
    EXCEPTION WHEN OTHERS THEN RAISE e_invalid_request;
    END;
    IF LENGTH(l_public_id) <> 32 THEN RAISE e_invalid_request; END IF;

    IF l_request.has('invalidTokens')
       AND l_request.get('invalidTokens').is_array THEN
      l_invalid_tokens := l_request.get_array('invalidTokens');
      IF l_invalid_tokens.get_size() > 0 THEN
        FOR i IN 0 .. l_invalid_tokens.get_size() - 1 LOOP
          UPDATE BEX_PUSH_DEVICE
             SET PUD_STATUS = 'REVOKED',
                 PUD_UPDATED_AT = SYS_EXTRACT_UTC(SYSTIMESTAMP)
           WHERE PUD_TOKEN = l_invalid_tokens.get_string(i);
        END LOOP;
      END IF;
    END IF;

    IF l_success THEN
      UPDATE BEX_PUSH_OUTBOX
         SET PBO_STATUS = 'SENT',
             PBO_SENT_AT = SYS_EXTRACT_UTC(SYSTIMESTAMP),
             PBO_LAST_ERROR = NULL,
             PBO_UPDATED_AT = SYS_EXTRACT_UTC(SYSTIMESTAMP)
       WHERE PBO_PUBLIC_ID = l_public_id
         AND PBO_STATUS = 'PROCESSING';
    ELSE
      UPDATE BEX_PUSH_OUTBOX
         SET PBO_STATUS = CASE
               WHEN PBO_ATTEMPTS >= 5 THEN 'FAILED' ELSE 'PENDING'
             END,
             PBO_NEXT_ATTEMPT_AT =
               SYS_EXTRACT_UTC(SYSTIMESTAMP) +
               NUMTODSINTERVAL(
                 LEAST(60, POWER(2, PBO_ATTEMPTS) * 5), 'SECOND'
               ),
             PBO_LAST_ERROR = NVL(l_error, 'Firebase send failed'),
             PBO_UPDATED_AT = SYS_EXTRACT_UTC(SYSTIMESTAMP)
       WHERE PBO_PUBLIC_ID = l_public_id
         AND PBO_STATUS = 'PROCESSING';
    END IF;
    IF SQL%ROWCOUNT <> 1 THEN RAISE e_invalid_request; END IF;
    COMMIT;
  END;
END BEX_PUSH_BRIDGE_PKG;
/

BEGIN
  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'notifications/bridge/claim',
    p_etag_type => 'NONE'
  );
  ORDS.DEFINE_HANDLER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'notifications/bridge/claim',
    p_method => 'POST',
    p_source_type => ORDS.SOURCE_TYPE_PLSQL,
    p_mimes_allowed => 'application/json',
    p_source => q'~
DECLARE
  l_message CLOB;
BEGIN
  ord_runtime_pkg.begin_anonymous_request;
  :trace_id := core_context_pkg.trace_id();
  l_message := BEX_PUSH_BRIDGE_PKG.CLAIM(:bridge_key);
  :status_code := 200;
  IF l_message IS NULL THEN
    ord_runtime_pkg.write_json_response(
      '{"success":true,"data":null}'
    );
  ELSE
    ord_runtime_pkg.write_json_response(
      '{"success":true,"data":' || l_message || '}'
    );
  END IF;
  ord_runtime_pkg.clear_request_context;
EXCEPTION
  WHEN BEX_PUSH_BRIDGE_PKG.e_unauthorized THEN
    ROLLBACK; :status_code := 401;
    ord_runtime_pkg.write_json_response(
      '{"success":false,"error":{"code":"BEX-PUSH-401","message":"Bridge key invalida."}}'
    );
    ord_runtime_pkg.clear_request_context;
  WHEN OTHERS THEN
    ROLLBACK; ord_runtime_pkg.clear_request_context; RAISE;
END;
~'
  );

  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'notifications/bridge/ack',
    p_etag_type => 'NONE'
  );
  ORDS.DEFINE_HANDLER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'notifications/bridge/ack',
    p_method => 'POST',
    p_source_type => ORDS.SOURCE_TYPE_PLSQL,
    p_mimes_allowed => 'application/json',
    p_source => q'~
DECLARE
  l_body_text CLOB := :body_text;
BEGIN
  ord_runtime_pkg.begin_anonymous_request;
  :trace_id := core_context_pkg.trace_id();
  BEX_PUSH_BRIDGE_PKG.ACKNOWLEDGE(:bridge_key, l_body_text);
  :status_code := 200;
  ord_runtime_pkg.write_json_response(
    '{"success":true,"data":{"acknowledged":true}}'
  );
  ord_runtime_pkg.clear_request_context;
EXCEPTION
  WHEN BEX_PUSH_BRIDGE_PKG.e_unauthorized THEN
    ROLLBACK; :status_code := 401;
    ord_runtime_pkg.write_json_response(
      '{"success":false,"error":{"code":"BEX-PUSH-401","message":"Bridge key invalida."}}'
    );
    ord_runtime_pkg.clear_request_context;
  WHEN BEX_PUSH_BRIDGE_PKG.e_invalid_request THEN
    ROLLBACK; :status_code := 400;
    ord_runtime_pkg.write_json_response(
      '{"success":false,"error":{"code":"BEX-PUSH-400","message":"Confirmacao invalida."}}'
    );
    ord_runtime_pkg.clear_request_context;
  WHEN OTHERS THEN
    ROLLBACK; ord_runtime_pkg.clear_request_context; RAISE;
END;
~'
  );

  FOR endpoint_data IN(
    SELECT 'notifications/bridge/claim' pattern_value FROM DUAL
    UNION ALL
    SELECT 'notifications/bridge/ack' FROM DUAL
  ) LOOP
    ORDS.DEFINE_PARAMETER(
      p_module_name => 'brecho-express-v1',
      p_pattern => endpoint_data.pattern_value,
      p_method => 'POST',
      p_name => 'X-Push-Bridge-Key',
      p_bind_variable_name => 'bridge_key',
      p_source_type => 'HEADER',
      p_param_type => 'STRING',
      p_access_method => 'IN'
    );
    ORDS.DEFINE_PARAMETER(
      p_module_name => 'brecho-express-v1',
      p_pattern => endpoint_data.pattern_value,
      p_method => 'POST',
      p_name => 'X-ORDS-STATUS-CODE',
      p_bind_variable_name => 'status_code',
      p_source_type => 'HEADER',
      p_param_type => 'INT',
      p_access_method => 'OUT'
    );
    ORDS.DEFINE_PARAMETER(
      p_module_name => 'brecho-express-v1',
      p_pattern => endpoint_data.pattern_value,
      p_method => 'POST',
      p_name => 'X-Trace-Id',
      p_bind_variable_name => 'trace_id',
      p_source_type => 'HEADER',
      p_param_type => 'STRING',
      p_access_method => 'OUT'
    );
  END LOOP;
  COMMIT;
END;
/

DECLARE
  l_invalid PLS_INTEGER;
BEGIN
  SELECT COUNT(*) INTO l_invalid
    FROM USER_OBJECTS
   WHERE OBJECT_NAME = 'BEX_PUSH_BRIDGE_PKG'
     AND STATUS <> 'VALID';
  IF l_invalid > 0 THEN
    RAISE_APPLICATION_ERROR(-20999, 'Push bridge package is invalid.');
  END IF;
  DBMS_OUTPUT.PUT_LINE(
    'SUCCESS - SELF-HOSTED PUSH BRIDGE INSTALLED'
  );
END;
/

SPOOL OFF
EXIT SUCCESS COMMIT
