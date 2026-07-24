WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE OFF
PROMPT Installing PRODUCT_QUESTION structure...
@@upgrade_product_question_support.sql
@@bex_product_question.sql
PROMPT PRODUCT_QUESTION structure installed successfully.
