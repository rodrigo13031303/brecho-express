WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT Seeding official Brecho Express categories...

MERGE INTO BEX_CATEGORY target
USING (
  SELECT 'roupas' slug, 'Roupas' name,
         'Vestidos, blusas, calcas, saias e outras pecas.' description FROM dual
  UNION ALL
  SELECT 'calcados', 'Calcados',
         'Tenis, sapatos, sandalias, botas e outros calcados' FROM dual
  UNION ALL
  SELECT 'bolsas', 'Bolsas',
         'Bolsas, mochilas, carteiras e similares' FROM dual
  UNION ALL
  SELECT 'acessorios', 'Acessorios',
         'Joias, bijuterias, cintos, chapeus e outros acessorios' FROM dual
) source
ON (target.CAT_SLUG = source.slug)
WHEN MATCHED THEN UPDATE SET
  target.CAT_NAME = source.name,
  target.CAT_DESCRIPTION = source.description,
  target.CAT_STATUS = 'ACTIVE',
  target.CAT_UPDATED_AT = SYSTIMESTAMP
WHEN NOT MATCHED THEN INSERT (
  CAT_PUBLIC_ID, CAT_NAME, CAT_SLUG, CAT_DESCRIPTION, CAT_STATUS
) VALUES (
  LOWER(RAWTOHEX(SYS_GUID())), source.name, source.slug,
  source.description, 'ACTIVE'
);

COMMIT;
PROMPT Official categories seeded.
