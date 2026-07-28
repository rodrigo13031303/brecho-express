SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

PROMPT ============================================================
PROMPT BRECHO EXPRESS - PRODUCT IMAGE MEDIA
PROMPT ============================================================

DECLARE
  l_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*) INTO l_count
    FROM USER_TABLES
   WHERE TABLE_NAME = 'BEX_PRODUCT_IMAGE_MEDIA';

  IF l_count = 0 THEN
    EXECUTE IMMEDIATE q'~
      CREATE TABLE BEX_PRODUCT_IMAGE_MEDIA (
        PIM_ID           NUMBER(19) NOT NULL,
        PMM_MIME_TYPE    VARCHAR2(100 CHAR) NOT NULL,
        PMM_CONTENT      BLOB NOT NULL,
        PMM_CREATED_AT   TIMESTAMP(6) DEFAULT SYSTIMESTAMP NOT NULL,
        PMM_CREATED_BY   NUMBER NOT NULL,
        CONSTRAINT PK_PRODUCT_IMAGE_MEDIA PRIMARY KEY (PIM_ID),
        CONSTRAINT FK_PMM_IMAGE FOREIGN KEY (PIM_ID)
          REFERENCES BEX_PRODUCT_IMAGE (PIM_ID) ON DELETE CASCADE,
        CONSTRAINT CK_PMM_MIME CHECK (
          PMM_MIME_TYPE IN ('image/jpeg', 'image/png', 'image/webp')
        )
      )
    ~';
  END IF;
END;
/

BEGIN
  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'product-images/:imagePublicId/content',
    p_etag_type => 'NONE',
    p_comments => 'Public product image media'
  );

  ORDS.DEFINE_HANDLER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'product-images/:imagePublicId/content',
    p_method => 'GET',
    p_source_type => ORDS.SOURCE_TYPE_MEDIA,
    p_comments => 'Return active media for a public active product',
    p_source => q'~
SELECT media.PMM_MIME_TYPE, media.PMM_CONTENT
  FROM BEX_PRODUCT_IMAGE_MEDIA media
  JOIN BEX_PRODUCT_IMAGE image_data ON image_data.PIM_ID = media.PIM_ID
  JOIN BEX_PRODUCT product_data ON product_data.PRD_ID = image_data.PRD_ID
 WHERE image_data.PIM_PUBLIC_ID = LOWER(TRIM(:imagePublicId))
   AND image_data.PIM_STATUS = 'ACTIVE'
   AND product_data.PRD_STATUS = 'ACTIVE'
~'
  );

  ORDS.DEFINE_TEMPLATE(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'products/:productPublicId/images/media',
    p_etag_type => 'NONE',
    p_comments => 'Authenticated product image upload'
  );

  ORDS.DEFINE_HANDLER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'products/:productPublicId/images/media',
    p_method => 'POST',
    p_source_type => ORDS.SOURCE_TYPE_PLSQL,
    p_mimes_allowed => 'image/jpeg,image/png,image/webp',
    p_comments => 'Store one product image securely in Oracle',
    p_source => q'~
DECLARE
  l_authenticated BOOLEAN;
  l_account_id NUMBER;
  l_session_public_id VARCHAR2(32);
  l_status PLS_INTEGER;
  l_body CLOB;
  l_product_id NUMBER;
  l_image_count PLS_INTEGER;
  l_image_id NUMBER;
  l_image_public_id VARCHAR2(32);
  l_image_url VARCHAR2(1000);
  l_image BLOB := :body;
  l_mime VARCHAR2(100) := LOWER(TRIM(:content_type));
  l_sort_order PLS_INTEGER := TO_NUMBER(NVL(TRIM(:sort_order), '0'));
  l_is_primary PLS_INTEGER := TO_NUMBER(NVL(TRIM(:is_primary), '0'));
  l_data JSON_OBJECT_T := JSON_OBJECT_T();
BEGIN
  ord_runtime_pkg.begin_authenticated_request(
    :authorization, l_authenticated, l_account_id, l_session_public_id,
    l_status, l_body
  );
  :trace_id := core_context_pkg.trace_id();

  IF l_authenticated THEN
    BEGIN
      SELECT product_data.PRD_ID
        INTO l_product_id
        FROM BEX_PRODUCT product_data
        JOIN BEX_STORE store_data ON store_data.STR_ID = product_data.STR_ID
       WHERE product_data.PRD_PUBLIC_ID = LOWER(TRIM(:productPublicId))
         AND store_data.ACC_ID = l_account_id
         AND product_data.PRD_STATUS = 'DRAFT'
       FOR UPDATE OF product_data.PRD_STATUS;

      SELECT COUNT(*)
        INTO l_image_count
        FROM BEX_PRODUCT_IMAGE
       WHERE PRD_ID = l_product_id
         AND PIM_STATUS = 'ACTIVE';

      IF l_mime NOT IN ('image/jpeg', 'image/png', 'image/webp')
         OR l_image IS NULL
         OR DBMS_LOB.GETLENGTH(l_image) = 0
         OR DBMS_LOB.GETLENGTH(l_image) > 5242880
         OR l_sort_order < 0
         OR l_sort_order > 7
         OR l_is_primary NOT IN (0, 1)
         OR l_image_count >= 8 THEN
        l_status := 422;
        l_body := '{"success":false,"error":{"code":"BEX-PIM-002","message":"Envie de 1 a 8 fotos JPG, PNG ou WebP de ate 5 MB cada."}}';
      ELSE
        IF l_image_count = 0 THEN
          l_is_primary := 1;
        ELSIF l_is_primary = 1 THEN
          UPDATE BEX_PRODUCT_IMAGE
             SET PIM_IS_PRIMARY = 0,
                 PIM_UPDATED_AT = SYSTIMESTAMP,
                 PIM_UPDATED_BY = l_account_id
           WHERE PRD_ID = l_product_id
             AND PIM_STATUS = 'ACTIVE';
        END IF;

        l_image_public_id := LOWER(RAWTOHEX(SYS_GUID()));
        l_image_url :=
          'https://app.rodrigosburguer.com.br/ords/brechoexpress/api/v1/product-images/'
          || l_image_public_id || '/content';

        INSERT INTO BEX_PRODUCT_IMAGE (
          PIM_PUBLIC_ID, PRD_ID, PIM_URL, PIM_ALT_TEXT,
          PIM_SORT_ORDER, PIM_IS_PRIMARY, PIM_STATUS,
          PIM_CREATED_BY, PIM_UPDATED_BY
        ) VALUES (
          l_image_public_id, l_product_id, l_image_url, NULL,
          l_sort_order, l_is_primary, 'ACTIVE',
          l_account_id, l_account_id
        ) RETURNING PIM_ID INTO l_image_id;

        INSERT INTO BEX_PRODUCT_IMAGE_MEDIA (
          PIM_ID, PMM_MIME_TYPE, PMM_CONTENT, PMM_CREATED_BY
        ) VALUES (
          l_image_id, l_mime, l_image, l_account_id
        );

        core_json_pkg.put_string(l_data, 'imagePublicId', l_image_public_id);
        core_json_pkg.put_string(l_data, 'imageUrl', l_image_url);
        core_json_pkg.put_number(l_data, 'sortOrder', l_sort_order);
        core_json_pkg.put_boolean(l_data, 'isPrimary', l_is_primary = 1);
        l_body := core_response_pkg.build_success(l_data);
        l_status := 201;
        COMMIT;
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        l_status := 403;
        l_body := '{"success":false,"error":{"code":"BEX-PRD-005","message":"O produto nao pode receber imagens."}}';
      WHEN VALUE_ERROR THEN
        ROLLBACK;
        l_status := 422;
        l_body := '{"success":false,"error":{"code":"BEX-PIM-002","message":"Os dados da imagem sao invalidos."}}';
    END;
  END IF;

  :status_code := l_status;
  ord_runtime_pkg.write_json_response(l_body);
  ord_runtime_pkg.clear_request_context;
EXCEPTION
  WHEN OTHERS THEN
    api_error_log_pkg.capture(
      p_trace_id => core_context_pkg.trace_id(),
      p_component => 'PRODUCT_IMAGE_MEDIA',
      p_operation => 'UPLOAD',
      p_actor_id => l_account_id,
      p_sql_code => SQLCODE,
      p_sql_message => SQLERRM,
      p_backtrace => DBMS_UTILITY.format_error_backtrace
    );
    ROLLBACK;
    l_status := 500;
    l_body := '{"success":false,"error":{"code":"BEX-TECHNICAL-001","message":"Nao foi possivel salvar a imagem agora."}}';
    :status_code := l_status;
    ord_runtime_pkg.write_json_response(l_body);
    ord_runtime_pkg.clear_request_context;
END;
~'
  );

  ORDS.DEFINE_PARAMETER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'products/:productPublicId/images/media',
    p_method => 'POST', p_name => 'Authorization',
    p_bind_variable_name => 'authorization', p_source_type => 'HEADER',
    p_param_type => 'STRING', p_access_method => 'IN'
  );
  ORDS.DEFINE_PARAMETER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'products/:productPublicId/images/media',
    p_method => 'POST', p_name => 'Content-Type',
    p_bind_variable_name => 'content_type', p_source_type => 'HEADER',
    p_param_type => 'STRING', p_access_method => 'IN'
  );
  ORDS.DEFINE_PARAMETER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'products/:productPublicId/images/media',
    p_method => 'POST', p_name => 'X-Image-Sort-Order',
    p_bind_variable_name => 'sort_order', p_source_type => 'HEADER',
    p_param_type => 'STRING', p_access_method => 'IN'
  );
  ORDS.DEFINE_PARAMETER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'products/:productPublicId/images/media',
    p_method => 'POST', p_name => 'X-Image-Primary',
    p_bind_variable_name => 'is_primary', p_source_type => 'HEADER',
    p_param_type => 'STRING', p_access_method => 'IN'
  );
  ORDS.DEFINE_PARAMETER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'products/:productPublicId/images/media',
    p_method => 'POST', p_name => 'X-Trace-Id',
    p_bind_variable_name => 'trace_id', p_source_type => 'HEADER',
    p_param_type => 'STRING', p_access_method => 'OUT'
  );
  ORDS.DEFINE_PARAMETER(
    p_module_name => 'brecho-express-v1',
    p_pattern => 'products/:productPublicId/images/media',
    p_method => 'POST', p_name => 'X-ORDS-STATUS-CODE',
    p_bind_variable_name => 'status_code', p_source_type => 'HEADER',
    p_param_type => 'INT', p_access_method => 'OUT'
  );
  COMMIT;
END;
/

PROMPT SUCCESS - PRODUCT IMAGE MEDIA INSTALLED