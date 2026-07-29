SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF
SET ECHO ON
SET FEEDBACK ON
WHENEVER OSERROR EXIT FAILURE ROLLBACK
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

SPOOL push_notifications_installation.log

PROMPT ============================================================
PROMPT BRECHO EXPRESS - PUSH NOTIFICATIONS FEATURE
PROMPT ============================================================

DECLARE
  l_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*) INTO l_count
    FROM USER_TABLES WHERE TABLE_NAME = 'BEX_PUSH_DEVICE';
  IF l_count = 0 THEN
    EXECUTE IMMEDIATE q'~
      CREATE TABLE BEX_PUSH_DEVICE(
        PUD_ID NUMBER(19) GENERATED ALWAYS AS IDENTITY,
        PUD_PUBLIC_ID CHAR(32 CHAR) NOT NULL,
        PFL_ID NUMBER(19) NOT NULL,
        PUD_TOKEN VARCHAR2(512 CHAR) NOT NULL,
        PUD_PLATFORM VARCHAR2(20 CHAR) NOT NULL,
        PUD_STATUS VARCHAR2(20 CHAR) DEFAULT 'ACTIVE' NOT NULL,
        PUD_CREATED_AT TIMESTAMP(6) DEFAULT SYSTIMESTAMP NOT NULL,
        PUD_UPDATED_AT TIMESTAMP(6) DEFAULT SYSTIMESTAMP NOT NULL,
        CONSTRAINT PK_PUSH_DEVICE PRIMARY KEY(PUD_ID),
        CONSTRAINT UK_PUSH_DEVICE_PUBLIC UNIQUE(PUD_PUBLIC_ID),
        CONSTRAINT UK_PUSH_DEVICE_TOKEN UNIQUE(PUD_TOKEN),
        CONSTRAINT FK_PUSH_DEVICE_PROFILE FOREIGN KEY(PFL_ID)
          REFERENCES BEX_PROFILE(PFL_ID),
        CONSTRAINT CK_PUSH_DEVICE_PLATFORM
          CHECK(PUD_PLATFORM IN('ANDROID','IOS')),
        CONSTRAINT CK_PUSH_DEVICE_STATUS
          CHECK(PUD_STATUS IN('ACTIVE','REVOKED'))
      )
    ~';
    EXECUTE IMMEDIATE
      'CREATE INDEX IDX_PUSH_DEVICE_PROFILE '||
      'ON BEX_PUSH_DEVICE(PFL_ID,PUD_STATUS)';
  END IF;

  SELECT COUNT(*) INTO l_count
    FROM USER_TABLES WHERE TABLE_NAME = 'BEX_PUSH_OUTBOX';
  IF l_count = 0 THEN
    EXECUTE IMMEDIATE q'~
      CREATE TABLE BEX_PUSH_OUTBOX(
        PBO_ID NUMBER(19) GENERATED ALWAYS AS IDENTITY,
        PBO_PUBLIC_ID CHAR(32 CHAR) NOT NULL,
        PFL_ID NUMBER(19) NOT NULL,
        PBO_TYPE VARCHAR2(80 CHAR) NOT NULL,
        PBO_TITLE VARCHAR2(200 CHAR) NOT NULL,
        PBO_BODY VARCHAR2(2000 CHAR) NOT NULL,
        PBO_DATA CLOB,
        PBO_STATUS VARCHAR2(20 CHAR) DEFAULT 'PENDING' NOT NULL,
        PBO_ATTEMPTS NUMBER(5) DEFAULT 0 NOT NULL,
        PBO_NEXT_ATTEMPT_AT TIMESTAMP(6) DEFAULT SYSTIMESTAMP NOT NULL,
        PBO_SENT_AT TIMESTAMP(6),
        PBO_LAST_ERROR VARCHAR2(2000 CHAR),
        PBO_CREATED_AT TIMESTAMP(6) DEFAULT SYSTIMESTAMP NOT NULL,
        PBO_UPDATED_AT TIMESTAMP(6) DEFAULT SYSTIMESTAMP NOT NULL,
        CONSTRAINT PK_PUSH_OUTBOX PRIMARY KEY(PBO_ID),
        CONSTRAINT UK_PUSH_OUTBOX_PUBLIC UNIQUE(PBO_PUBLIC_ID),
        CONSTRAINT FK_PUSH_OUTBOX_PROFILE FOREIGN KEY(PFL_ID)
          REFERENCES BEX_PROFILE(PFL_ID),
        CONSTRAINT CK_PUSH_OUTBOX_STATUS
          CHECK(PBO_STATUS IN('PENDING','PROCESSING','SENT','FAILED')),
        CONSTRAINT CK_PUSH_OUTBOX_DATA CHECK(PBO_DATA IS JSON)
      )
    ~';
    EXECUTE IMMEDIATE
      'CREATE INDEX IDX_PUSH_OUTBOX_PENDING '||
      'ON BEX_PUSH_OUTBOX(PBO_STATUS,PBO_NEXT_ATTEMPT_AT,PBO_ID)';
  END IF;
END;
/

CREATE OR REPLACE PACKAGE BEX_PUSH_PKG AS
  PROCEDURE REGISTER_DEVICE(
    P_ACCOUNT_ID NUMBER,
    P_TOKEN VARCHAR2,
    P_PLATFORM VARCHAR2
  );
  PROCEDURE ENQUEUE_PROFILE(
    P_PROFILE_ID NUMBER,
    P_TYPE VARCHAR2,
    P_TITLE VARCHAR2,
    P_BODY VARCHAR2,
    P_DATA CLOB DEFAULT NULL
  );
  PROCEDURE ENQUEUE_ACCOUNT(
    P_ACCOUNT_ID NUMBER,
    P_TYPE VARCHAR2,
    P_TITLE VARCHAR2,
    P_BODY VARCHAR2,
    P_DATA CLOB DEFAULT NULL
  );
END BEX_PUSH_PKG;
/

CREATE OR REPLACE PACKAGE BODY BEX_PUSH_PKG AS
  PROCEDURE REGISTER_DEVICE(
    P_ACCOUNT_ID NUMBER,
    P_TOKEN VARCHAR2,
    P_PLATFORM VARCHAR2
  ) IS
    l_profile BEX_PROFILE%ROWTYPE;
    l_token VARCHAR2(512) := TRIM(P_TOKEN);
    l_platform VARCHAR2(20) := UPPER(TRIM(P_PLATFORM));
  BEGIN
    IF LENGTH(l_token) < 20 OR l_platform NOT IN('ANDROID','IOS') THEN
      RAISE_APPLICATION_ERROR(-20871,'Dispositivo push invalido.');
    END IF;
    l_profile := pfl_service_pkg.get_by_account_id(P_ACCOUNT_ID);
    MERGE INTO BEX_PUSH_DEVICE target
    USING(
      SELECT l_token token_value FROM DUAL
    ) source
    ON(target.PUD_TOKEN = source.token_value)
    WHEN MATCHED THEN UPDATE SET
      target.PFL_ID = l_profile.PFL_ID,
      target.PUD_PLATFORM = l_platform,
      target.PUD_STATUS = 'ACTIVE',
      target.PUD_UPDATED_AT = SYSTIMESTAMP
    WHEN NOT MATCHED THEN INSERT(
      PUD_PUBLIC_ID,PFL_ID,PUD_TOKEN,PUD_PLATFORM
    ) VALUES(
      LOWER(RAWTOHEX(SYS_GUID())),l_profile.PFL_ID,l_token,l_platform
    );
  END;

  PROCEDURE ENQUEUE_PROFILE(
    P_PROFILE_ID NUMBER,
    P_TYPE VARCHAR2,
    P_TITLE VARCHAR2,
    P_BODY VARCHAR2,
    P_DATA CLOB DEFAULT NULL
  ) IS
  BEGIN
    INSERT INTO BEX_PUSH_OUTBOX(
      PBO_PUBLIC_ID,PFL_ID,PBO_TYPE,PBO_TITLE,PBO_BODY,PBO_DATA
    ) VALUES(
      LOWER(RAWTOHEX(SYS_GUID())),P_PROFILE_ID,UPPER(TRIM(P_TYPE)),
      TRIM(P_TITLE),TRIM(P_BODY),NVL(P_DATA,'{}')
    );
  END;

  PROCEDURE ENQUEUE_ACCOUNT(
    P_ACCOUNT_ID NUMBER,
    P_TYPE VARCHAR2,
    P_TITLE VARCHAR2,
    P_BODY VARCHAR2,
    P_DATA CLOB DEFAULT NULL
  ) IS
    l_profile BEX_PROFILE%ROWTYPE;
  BEGIN
    l_profile := pfl_service_pkg.get_by_account_id(P_ACCOUNT_ID);
    ENQUEUE_PROFILE(
      l_profile.PFL_ID,P_TYPE,P_TITLE,P_BODY,P_DATA
    );
  EXCEPTION
    WHEN pfl_service_pkg.e_profile_not_found THEN NULL;
  END;
END BEX_PUSH_PKG;
/

@@packages/purchase/install_pur_service_pkg.sql

BEGIN
  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'notifications/devices',
    p_etag_type => 'NONE'
  );
  ORDS.DEFINE_HANDLER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'notifications/devices',
    p_method => 'POST',
    p_source_type => ORDS.SOURCE_TYPE_PLSQL,
    p_mimes_allowed => 'application/json',
    p_source => q'~
DECLARE
  l_authenticated BOOLEAN; l_account_id NUMBER;
  l_session_public_id VARCHAR2(32); l_status PLS_INTEGER; l_body CLOB;
  l_request JSON_OBJECT_T;
BEGIN
  ord_runtime_pkg.begin_authenticated_request(
    :authorization,l_authenticated,l_account_id,l_session_public_id,
    l_status,l_body
  );
  :trace_id := core_context_pkg.trace_id();
  IF l_authenticated THEN
    l_request := JSON_OBJECT_T.parse(:body_text);
    BEX_PUSH_PKG.REGISTER_DEVICE(
      l_account_id,
      l_request.get_string('token'),
      l_request.get_string('platform')
    );
    COMMIT;
    l_status := 200;
    l_body := '{"success":true,"data":{"registered":true}}';
  END IF;
  :status_code := l_status;
  ord_runtime_pkg.write_json_response(l_body);
  ord_runtime_pkg.clear_request_context;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    ord_runtime_pkg.clear_request_context;
    RAISE;
END;
~'
  );
  ORDS.DEFINE_PARAMETER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'notifications/devices',
    p_method => 'POST',
    p_name => 'Authorization',
    p_bind_variable_name => 'authorization',
    p_source_type => 'HEADER',
    p_param_type => 'STRING',
    p_access_method => 'IN'
  );
  ORDS.DEFINE_PARAMETER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'notifications/devices',
    p_method => 'POST',
    p_name => 'X-Trace-Id',
    p_bind_variable_name => 'trace_id',
    p_source_type => 'HEADER',
    p_param_type => 'STRING',
    p_access_method => 'OUT'
  );
  COMMIT;
END;
/

DECLARE
  l_invalid_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*) INTO l_invalid_count
    FROM USER_OBJECTS
   WHERE OBJECT_NAME = 'BEX_PUSH_PKG'
     AND STATUS <> 'VALID';
  IF l_invalid_count > 0 THEN
    RAISE_APPLICATION_ERROR(-20999,'Push package is invalid.');
  END IF;
  DBMS_OUTPUT.PUT_LINE('SUCCESS - PUSH NOTIFICATIONS FEATURE INSTALLED');
END;
/

SPOOL OFF
EXIT SUCCESS COMMIT
