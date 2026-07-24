WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE OFF

PROMPT ============================================================
PROMPT Installing BRAND structure...
PROMPT ============================================================

@@bex_brand.sql

PROMPT BRAND structure installed successfully.
