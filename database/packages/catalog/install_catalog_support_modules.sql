WHENEVER SQLERROR EXIT SQL.SQLCODE
SET DEFINE OFF
PROMPT Installing catalog support modules...
@@install_prd_service_pkg.sql
@@install_product_image_module.sql
@@install_product_question_module.sql
@@install_prd_api_pkg.sql
DECLARE
  l_count PLS_INTEGER;
  l_valid PLS_INTEGER;
BEGIN
  SELECT COUNT(*) INTO l_count FROM USER_ERRORS
   WHERE NAME IN(
     'PRD_SERVICE_PKG','PIM_RULE_PKG','PIM_REPOSITORY_PKG',
     'PIM_SERVICE_PKG','PIM_API_PKG','PQA_RULE_PKG',
     'PQA_REPOSITORY_PKG','PQA_SERVICE_PKG','PQA_API_PKG'
   ) AND TYPE IN('PACKAGE','PACKAGE BODY');
  IF l_count>0 THEN
    RAISE_APPLICATION_ERROR(-20999,'Catalog support modules possuem erros.');
  END IF;
  SELECT COUNT(*) INTO l_valid FROM USER_OBJECTS
   WHERE OBJECT_NAME IN(
     'PRD_SERVICE_PKG','PRD_API_PKG','PIM_RULE_PKG',
     'PIM_REPOSITORY_PKG','PIM_SERVICE_PKG','PIM_API_PKG',
     'PQA_RULE_PKG','PQA_REPOSITORY_PKG','PQA_SERVICE_PKG','PQA_API_PKG'
   ) AND OBJECT_TYPE IN('PACKAGE','PACKAGE BODY') AND STATUS='VALID';
  IF l_valid<>20 THEN
    RAISE_APPLICATION_ERROR(-20998,'Catalog support modules possuem objetos invalidos.');
  END IF;
END;
/
PROMPT Catalog support modules installed successfully.
