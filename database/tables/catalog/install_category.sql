WHENEVER SQLERROR EXIT SQL.SQLCODE

SET DEFINE OFF

PROMPT ============================================================
PROMPT Installing CATEGORY structure...
PROMPT ============================================================

@@bex_category.sql

PROMPT CATEGORY structure installed successfully.
