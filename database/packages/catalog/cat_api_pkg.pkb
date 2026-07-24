CREATE OR REPLACE PACKAGE BODY cat_api_pkg AS
  e_required_value EXCEPTION;

  c_code_required  CONSTANT core_error_pkg.t_error_code := 'BEX-REQ-004';
  c_code_not_found CONSTANT core_error_pkg.t_error_code := 'BEX-CAT-001';
  c_code_internal  CONSTANT core_error_pkg.t_error_code := 'BEX-SYS-001';

  FUNCTION category_to_json(
    p_category IN cat_service_pkg.t_category_record
  ) RETURN JSON_OBJECT_T IS
    l_data JSON_OBJECT_T := JSON_OBJECT_T();
  BEGIN
    core_json_pkg.put_string(
      l_data,
      'categoryPublicId',
      TRIM(p_category.category_public_id)
    );
    core_json_pkg.put_string(l_data,'categoryName',p_category.category_name);
    core_json_pkg.put_string(l_data,'categorySlug',p_category.category_slug);
    IF p_category.description IS NULL THEN
      core_json_pkg.put_null(l_data,'description');
    ELSE
      core_json_pkg.put_string(l_data,'description',p_category.description);
    END IF;
    core_json_pkg.put_string(l_data,'status',p_category.status);
    core_json_pkg.put_string(
      l_data,'createdAt',
      core_json_pkg.format_timestamp(p_category.created_at)
    );
    core_json_pkg.put_string(
      l_data,'updatedAt',
      core_json_pkg.format_timestamp(p_category.updated_at)
    );
    RETURN l_data;
  END category_to_json;

  FUNCTION categories_to_json(
    p_categories IN cat_service_pkg.t_category_table
  ) RETURN JSON_ARRAY_T IS
    l_data JSON_ARRAY_T := JSON_ARRAY_T();
    l_index PLS_INTEGER := p_categories.FIRST;
  BEGIN
    WHILE l_index IS NOT NULL LOOP
      core_json_pkg.append_element(
        l_data,
        category_to_json(p_categories(l_index))
      );
      l_index := p_categories.NEXT(l_index);
    END LOOP;
    RETURN l_data;
  END categories_to_json;

  PROCEDURE build_error(
    p_status   IN PLS_INTEGER,
    p_code     IN core_error_pkg.t_error_code,
    p_category IN core_error_pkg.t_category,
    p_message  IN core_error_pkg.t_external_message,
    o_status_code OUT PLS_INTEGER,
    o_response_body OUT NOCOPY CLOB
  ) IS
    l_error core_error_pkg.t_public_error;
    l_policy core_error_pkg.t_error_policy;
  BEGIN
    core_error_pkg.build_known_error(
      p_code,p_category,p_message,core_error_pkg.c_severity_warn,
      FALSE,FALSE,l_error,l_policy
    );
    o_response_body:=core_response_pkg.build_error(l_error);
    o_status_code:=p_status;
  EXCEPTION WHEN OTHERS THEN
    o_status_code:=500;
    o_response_body:=NULL;
  END build_error;

  PROCEDURE technical_error(
    o_status_code OUT PLS_INTEGER,
    o_response_body OUT NOCOPY CLOB
  ) IS
    l_error core_error_pkg.t_public_error;
    l_policy core_error_pkg.t_error_policy;
  BEGIN
    core_error_pkg.build_technical_error(
      c_code_internal,'Nao foi possivel concluir a requisicao.',
      FALSE,l_error,l_policy
    );
    o_response_body:=core_response_pkg.build_error(l_error);
    o_status_code:=500;
  EXCEPTION WHEN OTHERS THEN
    o_status_code:=500;
    o_response_body:=NULL;
  END technical_error;

  PROCEDURE assert_required(p_value IN VARCHAR2) IS
  BEGIN
    IF TRIM(p_value) IS NULL THEN RAISE e_required_value; END IF;
  END assert_required;

  PROCEDURE assert_publicly_visible(
    p_category IN cat_service_pkg.t_category_record
  ) IS
  BEGIN
    IF p_category.status <> 'ACTIVE' THEN
      RAISE cat_service_pkg.e_category_not_found;
    END IF;
  END assert_publicly_visible;

  PROCEDURE get_category(
    p_category_public_id IN VARCHAR2,
    o_status_code OUT PLS_INTEGER,
    o_response_body OUT NOCOPY CLOB
  ) IS
    l_category cat_service_pkg.t_category_record;
  BEGIN
    o_status_code:=500; o_response_body:=NULL;
    assert_required(p_category_public_id);
    l_category:=cat_service_pkg.require_by_public_id(
      p_category_public_id
    );
    assert_publicly_visible(l_category);
    o_response_body:=core_response_pkg.build_success(
      category_to_json(l_category)
    );
    o_status_code:=200;
  EXCEPTION
    WHEN e_required_value THEN
      build_error(400,c_code_required,core_error_pkg.c_category_validation,
        'Um identificador publico obrigatorio nao foi informado.',
        o_status_code,o_response_body);
    WHEN cat_service_pkg.e_category_not_found THEN
      build_error(404,c_code_not_found,core_error_pkg.c_category_not_found,
        'A categoria informada nao foi encontrada.',
        o_status_code,o_response_body);
    WHEN OTHERS THEN technical_error(o_status_code,o_response_body);
  END get_category;

  PROCEDURE get_category_by_slug(
    p_slug IN VARCHAR2,
    o_status_code OUT PLS_INTEGER,
    o_response_body OUT NOCOPY CLOB
  ) IS
    l_category cat_service_pkg.t_category_record;
  BEGIN
    o_status_code:=500; o_response_body:=NULL;
    assert_required(p_slug);
    l_category:=cat_service_pkg.require_by_slug(p_slug);
    assert_publicly_visible(l_category);
    o_response_body:=core_response_pkg.build_success(
      category_to_json(l_category)
    );
    o_status_code:=200;
  EXCEPTION
    WHEN e_required_value THEN
      build_error(400,c_code_required,core_error_pkg.c_category_validation,
        'Um slug obrigatorio nao foi informado.',
        o_status_code,o_response_body);
    WHEN cat_service_pkg.e_category_not_found THEN
      build_error(404,c_code_not_found,core_error_pkg.c_category_not_found,
        'A categoria informada nao foi encontrada.',
        o_status_code,o_response_body);
    WHEN OTHERS THEN technical_error(o_status_code,o_response_body);
  END get_category_by_slug;

  PROCEDURE list_categories(
    o_status_code OUT PLS_INTEGER,
    o_response_body OUT NOCOPY CLOB
  ) IS
    l_categories cat_service_pkg.t_category_table;
  BEGIN
    o_status_code:=500; o_response_body:=NULL;
    l_categories:=cat_service_pkg.list_categories('ACTIVE');
    o_response_body:=core_response_pkg.build_success(
      categories_to_json(l_categories)
    );
    o_status_code:=200;
  EXCEPTION
    WHEN OTHERS THEN technical_error(o_status_code,o_response_body);
  END list_categories;
END cat_api_pkg;
/
