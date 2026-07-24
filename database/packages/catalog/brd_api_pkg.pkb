CREATE OR REPLACE PACKAGE BODY brd_api_pkg AS
  e_required EXCEPTION;
  FUNCTION to_json(p brd_service_pkg.t_brand_record) RETURN JSON_OBJECT_T IS
    j JSON_OBJECT_T:=JSON_OBJECT_T();
  BEGIN
    core_json_pkg.put_string(j,'brandPublicId',TRIM(p.brand_public_id));
    core_json_pkg.put_string(j,'brandName',p.brand_name);
    core_json_pkg.put_string(j,'brandSlug',p.brand_slug);
    IF p.description IS NULL THEN core_json_pkg.put_null(j,'description');
    ELSE core_json_pkg.put_string(j,'description',p.description); END IF;
    core_json_pkg.put_string(j,'status',p.status);
    core_json_pkg.put_string(j,'createdAt',core_json_pkg.format_timestamp(p.created_at));
    core_json_pkg.put_string(j,'updatedAt',core_json_pkg.format_timestamp(p.updated_at));
    RETURN j;
  END;
  FUNCTION to_array(p brd_service_pkg.t_brand_table) RETURN JSON_ARRAY_T IS
    a JSON_ARRAY_T:=JSON_ARRAY_T(); i PLS_INTEGER:=p.FIRST;
  BEGIN
    WHILE i IS NOT NULL LOOP core_json_pkg.append_element(a,to_json(p(i))); i:=p.NEXT(i); END LOOP;
    RETURN a;
  END;
  PROCEDURE error_response(p_status PLS_INTEGER,p_code VARCHAR2,p_message VARCHAR2,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS
    e core_error_pkg.t_public_error; pol core_error_pkg.t_error_policy;
  BEGIN
    core_error_pkg.build_known_error(p_code,CASE WHEN p_status=404 THEN core_error_pkg.c_category_not_found ELSE core_error_pkg.c_category_validation END,p_message,core_error_pkg.c_severity_warn,FALSE,FALSE,e,pol);
    o_body:=core_response_pkg.build_error(e); o_status:=p_status;
  END;
  PROCEDURE get_brand(p_brand_public_id VARCHAR2,o_status_code OUT PLS_INTEGER,o_response_body OUT NOCOPY CLOB) IS r brd_service_pkg.t_brand_record;
  BEGIN
    IF TRIM(p_brand_public_id) IS NULL THEN RAISE e_required; END IF;
    r:=brd_service_pkg.require_by_public_id(p_brand_public_id);
    IF r.status<>'ACTIVE' THEN RAISE brd_service_pkg.e_brand_not_found; END IF;
    o_response_body:=core_response_pkg.build_success(to_json(r)); o_status_code:=200;
  EXCEPTION
    WHEN e_required THEN error_response(400,'BEX-REQ-004','Um identificador publico obrigatorio nao foi informado.',o_status_code,o_response_body);
    WHEN brd_service_pkg.e_brand_not_found THEN error_response(404,'BEX-BRD-001','A marca informada nao foi encontrada.',o_status_code,o_response_body);
    WHEN OTHERS THEN o_status_code:=500; o_response_body:=NULL;
  END;
  PROCEDURE get_brand_by_slug(p_slug VARCHAR2,o_status_code OUT PLS_INTEGER,o_response_body OUT NOCOPY CLOB) IS r brd_service_pkg.t_brand_record;
  BEGIN
    IF TRIM(p_slug) IS NULL THEN RAISE e_required; END IF;
    r:=brd_service_pkg.require_by_slug(p_slug);
    IF r.status<>'ACTIVE' THEN RAISE brd_service_pkg.e_brand_not_found; END IF;
    o_response_body:=core_response_pkg.build_success(to_json(r)); o_status_code:=200;
  EXCEPTION
    WHEN e_required THEN error_response(400,'BEX-REQ-004','Um slug obrigatorio nao foi informado.',o_status_code,o_response_body);
    WHEN brd_service_pkg.e_brand_not_found THEN error_response(404,'BEX-BRD-001','A marca informada nao foi encontrada.',o_status_code,o_response_body);
    WHEN OTHERS THEN o_status_code:=500; o_response_body:=NULL;
  END;
  PROCEDURE list_brands(o_status_code OUT PLS_INTEGER,o_response_body OUT NOCOPY CLOB) IS r brd_service_pkg.t_brand_table;
  BEGIN r:=brd_service_pkg.list_brands('ACTIVE'); o_response_body:=core_response_pkg.build_success(to_array(r)); o_status_code:=200;
  EXCEPTION WHEN OTHERS THEN o_status_code:=500; o_response_body:=NULL; END;
END brd_api_pkg;
/
