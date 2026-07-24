CREATE OR REPLACE PACKAGE pqa_api_pkg AS
  PROCEDURE ask_question(p_product_public_id VARCHAR2,p_body CLOB,p_actor_id NUMBER,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE get_question(p_question_public_id VARCHAR2,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE list_questions(p_product_public_id VARCHAR2,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE answer_question(p_question_public_id VARCHAR2,p_store_public_id VARCHAR2,
    p_body CLOB,p_actor_id NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE moderate_question(p_question_public_id VARCHAR2,p_store_public_id VARCHAR2,
    p_status VARCHAR2,p_actor_id NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
END pqa_api_pkg;
/
