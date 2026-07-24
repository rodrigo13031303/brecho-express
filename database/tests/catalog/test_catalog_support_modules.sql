SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE
PROMPT Testing catalog support modules...
@@test_product_image_module.sql
@@test_product_question_module.sql
PROMPT Catalog support modules: PASSED
