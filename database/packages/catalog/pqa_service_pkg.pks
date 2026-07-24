CREATE OR REPLACE PACKAGE pqa_service_pkg AS
  TYPE t_record IS RECORD(
    question_public_id BEX_PRODUCT_QUESTION.PQA_PUBLIC_ID%TYPE,
    product_public_id BEX_PRODUCT.PRD_PUBLIC_ID%TYPE,
    question_by_public_id BEX_PROFILE.PFL_PUBLIC_ID%TYPE,
    answered_by_public_id BEX_PROFILE.PFL_PUBLIC_ID%TYPE,
    question_text BEX_PRODUCT_QUESTION.PQA_QUESTION_TEXT%TYPE,
    answer_text BEX_PRODUCT_QUESTION.PQA_ANSWER_TEXT%TYPE,
    asked_at BEX_PRODUCT_QUESTION.PQA_ASKED_AT%TYPE,
    answered_at BEX_PRODUCT_QUESTION.PQA_ANSWERED_AT%TYPE,
    status BEX_PRODUCT_QUESTION.PQA_STATUS%TYPE);
  TYPE t_table IS TABLE OF t_record INDEX BY PLS_INTEGER;
  e_question_not_found EXCEPTION;e_invalid_question EXCEPTION;
  e_invalid_answer EXCEPTION;e_invalid_status EXCEPTION;
  e_product_not_active EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_question_not_found,-20794);
  PRAGMA EXCEPTION_INIT(e_invalid_question,-20795);
  PRAGMA EXCEPTION_INIT(e_invalid_answer,-20796);
  PRAGMA EXCEPTION_INIT(e_invalid_status,-20797);
  PRAGMA EXCEPTION_INIT(e_product_not_active,-20798);
  FUNCTION ask_question(p_product_public_id VARCHAR2,p_text VARCHAR2,p_actor_id NUMBER) RETURN t_record;
  FUNCTION get_question(p_public_id VARCHAR2) RETURN t_record;
  FUNCTION list_questions(p_product_public_id VARCHAR2) RETURN t_table;
  FUNCTION answer_question(p_question_public_id VARCHAR2,p_store_public_id VARCHAR2,
    p_text VARCHAR2,p_actor_id NUMBER) RETURN t_record;
  FUNCTION moderate_question(p_question_public_id VARCHAR2,p_store_public_id VARCHAR2,
    p_status VARCHAR2,p_actor_id NUMBER) RETURN t_record;
END pqa_service_pkg;
/
