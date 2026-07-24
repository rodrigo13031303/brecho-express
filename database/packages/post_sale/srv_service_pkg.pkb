CREATE OR REPLACE PACKAGE BODY srv_service_pkg AS
  FUNCTION create_review(p_order VARCHAR2,p_store VARCHAR2,p_overall NUMBER,p_product NUMBER,p_conservation NUMBER,
    p_service NUMBER,p_delivery NUMBER,p_packaging NUMBER,p_again VARCHAR2,p_comment VARCHAR2,p_actor NUMBER)RETURN t_record IS
    src ord_service_pkg.t_post_sale_source;p BEX_PROFILE%ROWTYPE;r t_record;id NUMBER;
  BEGIN BEGIN srv_rule_pkg.validate_review(p_overall,p_product,p_conservation,p_service,p_delivery,p_packaging,p_again,p_comment);
    EXCEPTION WHEN srv_rule_pkg.e_invalid THEN RAISE e_invalid;END;src:=ord_service_pkg.post_sale_source(p_order,p_store);
    p:=pfl_service_pkg.get_by_account_id(p_actor);IF src.status<>'COMPLETED' OR src.profile_id<>p.pfl_id THEN RAISE e_forbidden;END IF;
    r.srv_public_id:=LOWER(RAWTOHEX(SYS_GUID()));r.ord_id:=src.order_id;r.str_id:=src.store_id;r.pfl_id:=p.pfl_id;
    r.overall_rate:=p_overall;r.product_match_rate:=p_product;r.conservation_rate:=p_conservation;r.service_rate:=p_service;
    r.delivery_rate:=p_delivery;r.packaging_rate:=p_packaging;r.would_buy_again:=UPPER(TRIM(p_again));r.comment_text:=TRIM(p_comment);
    BEGIN srv_repository_pkg.insert_row(r,p.pfl_id,id);EXCEPTION WHEN DUP_VAL_ON_INDEX THEN RAISE e_conflict;END;RETURN srv_repository_pkg.by_id(id);END;
  FUNCTION get_review(p_public VARCHAR2)RETURN t_record IS r t_record;BEGIN BEGIN r:=srv_repository_pkg.by_public(p_public);
    EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_found;END;RETURN r;END;
  FUNCTION list_store(p_store VARCHAR2)RETURN t_records IS BEGIN RETURN srv_repository_pkg.list_store(str_service_pkg.resolve_store_id(p_store));
    EXCEPTION WHEN OTHERS THEN RAISE e_not_found;END;
  FUNCTION reply(p_public VARCHAR2,p_reply VARCHAR2,p_actor NUMBER)RETURN t_record IS r t_record;s str_service_pkg.t_store_record;p BEX_PROFILE%ROWTYPE;
  BEGIN r:=get_review(p_public);s:=str_service_pkg.get_store_by_id(r.str_id);
    IF str_service_pkg.resolve_catalog_store_id(s.store_public_id,p_actor)<>r.str_id OR TRIM(p_reply)IS NULL OR LENGTH(p_reply)>2000 THEN RAISE e_forbidden;END IF;
    p:=pfl_service_pkg.get_by_account_id(p_actor);srv_repository_pkg.reply(r.srv_id,p_reply,p.pfl_id);RETURN srv_repository_pkg.by_id(r.srv_id);END;
END srv_service_pkg;
/
