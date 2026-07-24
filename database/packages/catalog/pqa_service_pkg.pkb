CREATE OR REPLACE PACKAGE BODY pqa_service_pkg AS
  FUNCTION map_row(p pqa_repository_pkg.t_row) RETURN t_record IS
    r t_record;q BEX_PROFILE%ROWTYPE;a BEX_PROFILE%ROWTYPE;
  BEGIN
    r.question_public_id:=p.pqa_public_id;
    r.product_public_id:=prd_service_pkg.resolve_product_public_id(p.prd_id);
    q:=pfl_service_pkg.get_by_id(p.pfl_question_by);r.question_by_public_id:=q.pfl_public_id;
    IF p.pfl_answered_by IS NOT NULL THEN a:=pfl_service_pkg.get_by_id(p.pfl_answered_by);
      r.answered_by_public_id:=a.pfl_public_id;END IF;
    r.question_text:=p.pqa_question_text;r.answer_text:=p.pqa_answer_text;
    r.asked_at:=p.pqa_asked_at;r.answered_at:=p.pqa_answered_at;r.status:=p.pqa_status;RETURN r;
  END;
  FUNCTION internal(p VARCHAR2) RETURN pqa_repository_pkg.t_row IS r pqa_repository_pkg.t_row;
  BEGIN BEGIN r:=pqa_repository_pkg.get_by_public_id(p);
    EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_question_not_found;END;RETURN r;END;
  FUNCTION ask_question(p_product_public_id VARCHAR2,p_text VARCHAR2,p_actor_id NUMBER) RETURN t_record IS
    x prd_service_pkg.t_product_identity;p BEX_PROFILE%ROWTYPE;r pqa_repository_pkg.t_row;id NUMBER;
  BEGIN
    x:=prd_service_pkg.resolve_product_identity(p_product_public_id);
    IF x.status<>prd_rule_pkg.c_status_active THEN RAISE e_product_not_active;END IF;
    BEGIN p:=pfl_service_pkg.get_by_account_id(p_actor_id);
    EXCEPTION WHEN pfl_service_pkg.e_profile_not_found THEN RAISE;END;
    r.pqa_question_text:=pqa_rule_pkg.normalize_text(p_text);
    BEGIN pqa_rule_pkg.validate_question(r.pqa_question_text);
    EXCEPTION WHEN pqa_rule_pkg.e_invalid_question THEN RAISE e_invalid_question;END;
    r.pqa_public_id:=LOWER(RAWTOHEX(SYS_GUID()));r.prd_id:=x.product_id;r.str_id:=x.store_id;
    r.pfl_question_by:=p.pfl_id;r.pqa_status:='ACTIVE';r.pqa_created_by:=p_actor_id;r.pqa_updated_by:=p_actor_id;
    pqa_repository_pkg.insert_row(r,id);RETURN map_row(pqa_repository_pkg.get_by_id(id));
  END;
  FUNCTION get_question(p_public_id VARCHAR2) RETURN t_record IS
  BEGIN RETURN map_row(internal(p_public_id));END;
  FUNCTION list_questions(p_product_public_id VARCHAR2) RETURN t_table IS
    x prd_service_pkg.t_product_identity;p pqa_repository_pkg.t_table;r t_table;i PLS_INTEGER;
  BEGIN x:=prd_service_pkg.resolve_product_identity(p_product_public_id);
    p:=pqa_repository_pkg.list_by_product(x.product_id,'ACTIVE');i:=p.FIRST;
    WHILE i IS NOT NULL LOOP r(r.COUNT+1):=map_row(p(i));i:=p.NEXT(i);END LOOP;RETURN r;END;
  FUNCTION answer_question(p_question_public_id VARCHAR2,p_store_public_id VARCHAR2,
    p_text VARCHAR2,p_actor_id NUMBER) RETURN t_record IS r pqa_repository_pkg.t_row;
    x prd_service_pkg.t_product_identity;p BEX_PROFILE%ROWTYPE;ok BOOLEAN;t VARCHAR2(4000);
  BEGIN r:=internal(p_question_public_id);
    x:=prd_service_pkg.resolve_catalog_product_identity(
      prd_service_pkg.resolve_product_public_id(r.prd_id),p_store_public_id,p_actor_id);
    t:=pqa_rule_pkg.normalize_text(p_text);
    BEGIN pqa_rule_pkg.validate_answer(t);EXCEPTION WHEN pqa_rule_pkg.e_invalid_answer
      THEN RAISE e_invalid_answer;END;
    p:=pfl_service_pkg.get_by_account_id(p_actor_id);pqa_repository_pkg.lock_by_id(r.pqa_id);
    pqa_repository_pkg.answer_row(r.pqa_id,p.pfl_id,t,p_actor_id,ok);
    RETURN map_row(pqa_repository_pkg.get_by_id(r.pqa_id));
  END;
  FUNCTION moderate_question(p_question_public_id VARCHAR2,p_store_public_id VARCHAR2,
    p_status VARCHAR2,p_actor_id NUMBER) RETURN t_record IS r pqa_repository_pkg.t_row;
    x prd_service_pkg.t_product_identity;ok BOOLEAN;s VARCHAR2(20);
  BEGIN r:=internal(p_question_public_id);
    x:=prd_service_pkg.resolve_catalog_product_identity(
      prd_service_pkg.resolve_product_public_id(r.prd_id),p_store_public_id,p_actor_id);
    s:=pqa_rule_pkg.normalize_status(p_status);
    BEGIN pqa_rule_pkg.validate_status(s);EXCEPTION WHEN pqa_rule_pkg.e_invalid_status
      THEN RAISE e_invalid_status;END;
    pqa_repository_pkg.lock_by_id(r.pqa_id);pqa_repository_pkg.update_status(r.pqa_id,s,p_actor_id,ok);
    RETURN map_row(pqa_repository_pkg.get_by_id(r.pqa_id));
  END;
END pqa_service_pkg;
/
