SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE
PROMPT Validating PRODUCT support structures...
@@test_bex_product.sql
@@test_bex_product_image.sql
@@test_bex_product_question.sql
PROMPT PRODUCT support structures: PASSED
