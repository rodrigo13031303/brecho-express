SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

PROMPT ============================================================
PROMPT BRECHO EXPRESS - STORE LOGO MEDIA
PROMPT ============================================================

DECLARE
  l_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*) INTO l_count
    FROM USER_TABLES
   WHERE TABLE_NAME = 'BEX_STORE_LOGO';

  IF l_count = 0 THEN
    EXECUTE IMMEDIATE q'~
      CREATE TABLE BEX_STORE_LOGO (
        STR_ID           NUMBER NOT NULL,
        SLM_MIME_TYPE    VARCHAR2(100 CHAR) NOT NULL,
        SLM_CONTENT      BLOB NOT NULL,
        SLM_UPDATED_AT   TIMESTAMP(6) DEFAULT SYSTIMESTAMP NOT NULL,
        SLM_UPDATED_BY   NUMBER NOT NULL,
        CONSTRAINT PK_STORE_LOGO PRIMARY KEY (STR_ID),
        CONSTRAINT FK_SLM_STORE FOREIGN KEY (STR_ID)
          REFERENCES BEX_STORE (STR_ID) ON DELETE CASCADE,
        CONSTRAINT CK_SLM_MIME CHECK (
          SLM_MIME_TYPE IN ('image/jpeg', 'image/png', 'image/webp')
        )
      )
    ~';
    EXECUTE IMMEDIATE q'~
      COMMENT ON TABLE BEX_STORE_LOGO IS
        'Small optimized logo owned by a store; product media remains external'
    ~';
  END IF;
END;
/

BEGIN
  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'brecho-express-v1',
    p_pattern     => 'stores/:storePublicId/logo',
    p_etag_type   => 'NONE',
    p_comments    => 'Public store logo media'
  );

  ORDS.DEFINE_HANDLER(
    p_module_name => 'brecho-express-v1',
    p_pattern     => 'stores/:storePublicId/logo',
    p_method      => 'GET',
    p_source_type => ORDS.SOURCE_TYPE_MEDIA,
    p_comments    => 'Return the current public store logo',
    p_source      => q'~
SELECT logo.SLM_MIME_TYPE, logo.SLM_CONTENT
  FROM BEX_STORE_LOGO logo
  JOIN BEX_STORE store_data ON store_data.STR_ID = logo.STR_ID
 WHERE store_data.STR_PUBLIC_ID = LOWER(TRIM(:storePublicId))
   AND store_data.STR_STATUS IN ('DRAFT', 'ACTIVE')
~'
  );

  ORDS.DEFINE_HANDLER(
    p_module_name   => 'brecho-express-v1',
    p_pattern       => 'stores/:storePublicId/logo',
    p_method        => 'POST',
    p_source_type   => ORDS.SOURCE_TYPE_PLSQL,
    p_mimes_allowed => 'image/jpeg,image/png,image/webp',
    p_comments      => 'Upload or replace authenticated store logo',
    p_source        => q'~
DECLARE
  l_authenticated BOOLEAN;
  l_account_id NUMBER;
  l_session_public_id VARCHAR2(32);
  l_status PLS_INTEGER;
  l_body CLOB;
  l_store_id NUMBER;
  l_logo BLOB := :body;
  l_mime VARCHAR2(100) := LOWER(TRIM(:content_type));
  l_data JSON_OBJECT_T := JSON_OBJECT_T();
  l_logo_url VARCHAR2(1000);
BEGIN
  ord_runtime_pkg.begin_authenticated_request(
    :authorization, l_authenticated, l_account_id, l_session_public_id,
    l_status, l_body
  );
  :trace_id := core_context_pkg.trace_id();

  IF l_authenticated THEN
    BEGIN
      SELECT STR_ID
        INTO l_store_id
        FROM BEX_STORE
       WHERE STR_PUBLIC_ID = LOWER(TRIM(:storePublicId))
         AND ACC_ID = l_account_id
         AND STR_STATUS IN ('DRAFT', 'ACTIVE')
       FOR UPDATE;

      IF l_mime NOT IN ('image/jpeg', 'image/png', 'image/webp')
         OR l_logo IS NULL
         OR DBMS_LOB.GETLENGTH(l_logo) = 0
         OR DBMS_LOB.GETLENGTH(l_logo) > 1048576 THEN
        l_status := 422;
        l_body := '{"success":false,"error":{"code":"BEX-LOGO-001","message":"Envie uma imagem JPG, PNG ou WebP de ate 1 MB."}}';
      ELSE
        UPDATE BEX_STORE_LOGO
           SET SLM_MIME_TYPE = l_mime,
               SLM_CONTENT = l_logo,
               SLM_UPDATED_AT = SYSTIMESTAMP,
               SLM_UPDATED_BY = l_account_id
         WHERE STR_ID = l_store_id;

        IF SQL%ROWCOUNT = 0 THEN
          INSERT INTO BEX_STORE_LOGO (
            STR_ID, SLM_MIME_TYPE, SLM_CONTENT, SLM_UPDATED_BY
          ) VALUES (
            l_store_id, l_mime, l_logo, l_account_id
          );
        END IF;

        l_logo_url :=
          'https://app.rodrigosburguer.com.br/ords/brechoexpress/api/v1/stores/'
          || LOWER(TRIM(:storePublicId)) || '/logo';

        UPDATE BEX_STORE
           SET STR_LOGO_URL = l_logo_url,
               STR_UPDATED_AT = SYSTIMESTAMP,
               STR_UPDATED_BY = l_account_id
         WHERE STR_ID = l_store_id;

        core_json_pkg.put_string(l_data, 'logoUrl', l_logo_url);
        l_body := core_response_pkg.build_success(l_data);
        l_status := 200;
        COMMIT;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        l_status := 403;
        l_body := '{"success":false,"error":{"code":"BEX-AUTH-004","message":"A conta autenticada nao pode alterar este brecho."}}';
    END;
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
    p_pattern => 'stores/:storePublicId/logo',
    p_method => 'POST',
    p_name => 'Authorization',
    p_bind_variable_name => 'authorization',
    p_source_type => 'HEADER',
    p_param_type => 'STRING',
    p_access_method => 'IN'
  );
  ORDS.DEFINE_PARAMETER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'stores/:storePublicId/logo',
    p_method => 'POST',
    p_name => 'Content-Type',
    p_bind_variable_name => 'content_type',
    p_source_type => 'HEADER',
    p_param_type => 'STRING',
    p_access_method => 'IN'
  );
  ORDS.DEFINE_PARAMETER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'stores/:storePublicId/logo',
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

PROMPT SUCCESS - STORE LOGO MEDIA INSTALLED
