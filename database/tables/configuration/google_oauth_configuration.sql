WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

MERGE INTO BEX_BUSINESS_CONFIGURATION target
USING (
  SELECT
    'AUTH_SESSION_DURATION_MINUTES' AS code,
    'ACCOUNT' AS module_code,
    'Duracao da sessao autenticada' AS name,
    'Duracao padrao da sessao propria do Brecho Express.' AS description,
    CAST(NULL AS VARCHAR2(4000)) AS value_text,
    1440 AS value_number,
    'minutes' AS unit_code
  FROM DUAL
  UNION ALL
  SELECT
    'GOOGLE_OAUTH_ALLOWED_AUDIENCES',
    'ACCOUNT',
    'Audiences Google OAuth permitidas',
    'Lista separada por virgula de Client IDs aceitos pelo plugin ORDS.',
    '77055318166-jr5lsmj17trmgt651ne3ismc7r7t1tli.apps.googleusercontent.com',
    CAST(NULL AS NUMBER),
    'client_ids'
  FROM DUAL
  UNION ALL
  SELECT
    'GOOGLE_OAUTH_ALLOWED_PRESENTERS',
    'ACCOUNT',
    'Apresentadores Google OAuth permitidos',
    'Lista separada por virgula de Client IDs Android e iOS aceitos no campo azp.',
    '77055318166-aai2lpnk0otaq18235qbt69b7h8e7i9j.apps.googleusercontent.com,77055318166-815viv1t22035m50v00htkvklqhqvg18.apps.googleusercontent.com',
    CAST(NULL AS NUMBER),
    'client_ids'
  FROM DUAL
) source
ON (target.BCF_CODE = source.code)
WHEN NOT MATCHED THEN
  INSERT (
    BCF_PUBLIC_ID,
    BCF_CODE,
    BCF_MODULE,
    BCF_NAME,
    BCF_DESCRIPTION,
    BCF_VALUE_TEXT,
    BCF_VALUE_NUMBER,
    BCF_UNIT
  )
  VALUES (
    LOWER(RAWTOHEX(SYS_GUID())),
    source.code,
    source.module_code,
    source.name,
    source.description,
    source.value_text,
    source.value_number,
    source.unit_code
  );

COMMIT;

PROMPT Google OAuth configuration installed successfully.
