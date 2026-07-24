CREATE OR REPLACE PACKAGE BODY pqa_api_pkg AS
  e_bad EXCEPTION;
  FUNCTION json(p pqa_service_pkg.t_record) RETURN JSON_OBJECT_T IS j JSON_OBJECT_T:=JSON_OBJECT_T();
  BEGIN core_json_pkg.put_string(j,'questionPublicId',TRIM(p.question_public_id));
    core_json_pkg.put_string(j,'productPublicId',TRIM(p.product_public_id));
    core_json_pkg.put_string(j,'questionByPublicId',TRIM(p.question_by_public_id));
    IF p.answered_by_public_id IS NULL THEN core_json_pkg.put_null(j,'answeredByPublicId');
    ELSE core_json_pkg.put_string(j,'answeredByPublicId',TRIM(p.answered_by_public_id));END IF;
    core_json_pkg.put_string(j,'questionText',p.question_text);
    IF p.answer_text IS NULL THEN core_json_pkg.put_null(j,'answerText');
    ELSE core_json_pkg.put_string(j,'answerText',p.answer_text);END IF;
    core_json_pkg.put_string(j,'askedAt',core_json_pkg.format_timestamp(p.asked_at));
    IF p.answered_at IS NULL THEN core_json_pkg.put_null(j,'answeredAt');
    ELSE core_json_pkg.put_string(j,'answeredAt',core_json_pkg.format_timestamp(p.answered_at));END IF;
    core_json_pkg.put_string(j,'status',p.status);RETURN j;END;
  FUNCTION arr(p pqa_service_pkg.t_table) RETURN JSON_ARRAY_T IS a JSON_ARRAY_T:=JSON_ARRAY_T();i PLS_INTEGER:=p.FIRST;
  BEGIN WHILE i IS NOT NULL LOOP core_json_pkg.append_element(a,json(p(i)));i:=p.NEXT(i);END LOOP;RETURN a;END;
  FUNCTION text_body(p CLOB,n VARCHAR2) RETURN VARCHAR2 IS
    e JSON_ELEMENT_T;j JSON_OBJECT_T;k JSON_KEY_LIST;
  BEGIN IF p IS NULL THEN RAISE e_bad;END IF;
    BEGIN e:=JSON_ELEMENT_T.parse(p);EXCEPTION WHEN OTHERS THEN RAISE e_bad;END;
    IF NOT e.is_object THEN RAISE e_bad;END IF;j:=TREAT(e AS JSON_OBJECT_T);
    k:=j.get_keys;
    IF k.COUNT<>1 OR NOT j.has(n) OR j.get(n).is_null
       OR NOT j.get(n).is_string THEN RAISE e_bad;END IF;
    RETURN j.get_string(n);END;
  PROCEDURE required(p VARCHAR2) IS BEGIN IF TRIM(p) IS NULL THEN RAISE e_bad;END IF;END;
  PROCEDURE actor(p NUMBER) IS BEGIN IF p IS NULL OR p<=0 THEN RAISE e_bad;END IF;END;
  PROCEDURE err(s NUMBER,c VARCHAR2,m VARCHAR2,os OUT PLS_INTEGER,ob OUT NOCOPY CLOB) IS
    e core_error_pkg.t_public_error;p core_error_pkg.t_error_policy;
  BEGIN core_error_pkg.build_known_error(c,CASE WHEN s=404 THEN core_error_pkg.c_category_not_found
    WHEN s=403 THEN core_error_pkg.c_category_authorization ELSE core_error_pkg.c_category_validation END,
    m,core_error_pkg.c_severity_warn,FALSE,FALSE,e,p);ob:=core_response_pkg.build_error(e);os:=s;END;
  PROCEDURE ask_question(p_product_public_id VARCHAR2,p_body CLOB,p_actor_id NUMBER,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS r pqa_service_pkg.t_record;t VARCHAR2(4000);
  BEGIN required(p_product_public_id);actor(p_actor_id);
    t:=text_body(p_body,'questionText');r:=pqa_service_pkg.ask_question(p_product_public_id,t,p_actor_id);
    COMMIT;o_body:=core_response_pkg.build_success(json(r));o_status:=201;
  EXCEPTION WHEN e_bad THEN ROLLBACK;err(400,'BEX-REQ-002','Pergunta invalida.',o_status,o_body);
    WHEN pqa_service_pkg.e_invalid_question OR pqa_service_pkg.e_product_not_active THEN ROLLBACK;err(422,'BEX-PQA-002','Pergunta nao permitida.',o_status,o_body);
    WHEN prd_service_pkg.e_product_not_found THEN ROLLBACK;err(404,'BEX-PRD-001','Achado nao encontrado.',o_status,o_body);
    WHEN pfl_service_pkg.e_profile_not_found THEN ROLLBACK;err(404,'BEX-PFL-001','Profile nao encontrado.',o_status,o_body);
    WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=NULL;END;
  PROCEDURE get_question(p_question_public_id VARCHAR2,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS r pqa_service_pkg.t_record;
  BEGIN required(p_question_public_id);r:=pqa_service_pkg.get_question(p_question_public_id);IF r.status<>'ACTIVE' THEN RAISE pqa_service_pkg.e_question_not_found;END IF;
    o_body:=core_response_pkg.build_success(json(r));o_status:=200;
  EXCEPTION WHEN e_bad THEN err(400,'BEX-REQ-004','Identificador obrigatorio.',o_status,o_body);
    WHEN pqa_service_pkg.e_question_not_found THEN err(404,'BEX-PQA-001','Pergunta nao encontrada.',o_status,o_body);
    WHEN OTHERS THEN o_status:=500;o_body:=NULL;END;
  PROCEDURE list_questions(p_product_public_id VARCHAR2,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS r pqa_service_pkg.t_table;
  BEGIN required(p_product_public_id);r:=pqa_service_pkg.list_questions(p_product_public_id);
    o_body:=core_response_pkg.build_success(arr(r));o_status:=200;
  EXCEPTION WHEN e_bad THEN err(400,'BEX-REQ-004','Identificador obrigatorio.',o_status,o_body);
    WHEN prd_service_pkg.e_product_not_found THEN err(404,'BEX-PRD-001','Achado nao encontrado.',o_status,o_body);
    WHEN OTHERS THEN o_status:=500;o_body:=NULL;END;
  PROCEDURE answer_question(p_question_public_id VARCHAR2,p_store_public_id VARCHAR2,
    p_body CLOB,p_actor_id NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS r pqa_service_pkg.t_record;t VARCHAR2(4000);
  BEGIN required(p_question_public_id);required(p_store_public_id);actor(p_actor_id);
    t:=text_body(p_body,'answerText');r:=pqa_service_pkg.answer_question(
    p_question_public_id,p_store_public_id,t,p_actor_id);
    COMMIT;o_body:=core_response_pkg.build_success(json(r));o_status:=200;
  EXCEPTION WHEN e_bad THEN ROLLBACK;err(400,'BEX-REQ-002','Resposta invalida.',o_status,o_body);
    WHEN pqa_service_pkg.e_question_not_found THEN ROLLBACK;err(404,'BEX-PQA-001','Pergunta nao encontrada.',o_status,o_body);
    WHEN pqa_service_pkg.e_invalid_answer THEN ROLLBACK;err(422,'BEX-PQA-003','Resposta invalida.',o_status,o_body);
    WHEN str_service_pkg.e_catalog_forbidden THEN ROLLBACK;err(403,'BEX-PQA-004','Operacao nao autorizada.',o_status,o_body);
    WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=NULL;END;
  PROCEDURE moderate_question(p_question_public_id VARCHAR2,p_store_public_id VARCHAR2,
    p_status VARCHAR2,p_actor_id NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS r pqa_service_pkg.t_record;
  BEGIN required(p_question_public_id);required(p_store_public_id);required(p_status);actor(p_actor_id);
    r:=pqa_service_pkg.moderate_question(p_question_public_id,p_store_public_id,p_status,p_actor_id);
    COMMIT;o_body:=core_response_pkg.build_success(json(r));o_status:=200;
  EXCEPTION WHEN e_bad THEN ROLLBACK;err(400,'BEX-REQ-004','Valores obrigatorios.',o_status,o_body);
    WHEN pqa_service_pkg.e_question_not_found THEN ROLLBACK;err(404,'BEX-PQA-001','Pergunta nao encontrada.',o_status,o_body);
    WHEN pqa_service_pkg.e_invalid_status THEN ROLLBACK;err(422,'BEX-PQA-005','Status invalido.',o_status,o_body);
    WHEN str_service_pkg.e_catalog_forbidden THEN ROLLBACK;err(403,'BEX-PQA-004','Operacao nao autorizada.',o_status,o_body);
    WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=NULL;END;
END pqa_api_pkg;
/
