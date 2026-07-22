WHENEVER SQLERROR EXIT SQL.SQLCODE

SET DEFINE OFF

PROMPT ============================================================
PROMPT Installing STORE structure...
PROMPT ============================================================

@@bex_store.sql

PROMPT STORE structure installed successfully.
