SET FEEDBACK ON
SET VERIFY OFF
SET LINESIZE 240
SET PAGESIZE 100
WHENEVER OSERROR EXIT FAILURE ROLLBACK
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

PROMPT ============================================================
PROMPT BRECHO EXPRESS - CONFIGURE GOOGLE OAUTH PRESENTERS
PROMPT ============================================================

MERGE INTO BEX_BUSINESS_CONFIGURATION target
USING (
  SELECT
    'GOOGLE_OAUTH_ALLOWED_PRESENTERS' AS code,
    'ACCOUNT' AS module_code,
    'Apresentadores Google OAuth permitidos' AS name,
    'Lista separada por virgula de Client IDs Android e iOS aceitos no campo azp.' AS description,
    '77055318166-aai2lpnk0otaq18235qbt69b7h8e7i9j.apps.googleusercontent.com,77055318166-815viv1t22035m50v00htkvklqhqvg18.apps.googleusercontent.com' AS value_text,
    'client_ids' AS unit_code
  FROM DUAL
) source
ON (target.BCF_CODE = source.code)
WHEN MATCHED THEN
  UPDATE SET
    target.BCF_MODULE = source.module_code,
    target.BCF_NAME = source.name,
    target.BCF_DESCRIPTION = source.description,
    target.BCF_VALUE_TEXT = source.value_text,
    target.BCF_VALUE_NUMBER = NULL,
    target.BCF_UNIT = source.unit_code,
    target.BCF_STATUS = 'ACTIVE',
    target.BCF_UPDATED_AT = SYSTIMESTAMP
WHEN NOT MATCHED THEN
  INSERT (
    BCF_PUBLIC_ID,
    BCF_CODE,
    BCF_MODULE,
    BCF_NAME,
    BCF_DESCRIPTION,
    BCF_VALUE_TEXT,
    BCF_UNIT
  )
  VALUES (
    LOWER(RAWTOHEX(SYS_GUID())),
    source.code,
    source.module_code,
    source.name,
    source.description,
    source.value_text,
    source.unit_code
  );

COMMIT;

SELECT
  BCF_CODE,
  BCF_VALUE_TEXT,
  BCF_STATUS
FROM BEX_BUSINESS_CONFIGURATION
WHERE BCF_CODE = 'GOOGLE_OAUTH_ALLOWED_PRESENTERS';

PROMPT Google OAuth presenters configured successfully.
