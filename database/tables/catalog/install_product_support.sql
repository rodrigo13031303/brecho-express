WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE OFF
PROMPT Installing PRODUCT support structures...
@@install_product_image.sql
@@install_product_question.sql
PROMPT PRODUCT support structures installed successfully.
