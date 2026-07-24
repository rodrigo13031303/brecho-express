CREATE OR REPLACE PACKAGE BODY cat_service_pkg AS
  FUNCTION to_public_record(
    p_record IN cat_repository_pkg.t_category_record
  ) RETURN t_category_record IS
    l_result t_category_record;
  BEGIN
    IF p_record.cat_id IS NULL THEN
      RETURN l_result;
    END IF;
    l_result.category_public_id := p_record.cat_public_id;
    l_result.category_name := p_record.cat_name;
    l_result.category_slug := p_record.cat_slug;
    l_result.description := p_record.cat_description;
    l_result.status := p_record.cat_status;
    l_result.created_at := p_record.cat_created_at;
    l_result.updated_at := p_record.cat_updated_at;
    RETURN l_result;
  END to_public_record;

  FUNCTION get_by_public_id(
    p_public_id IN BEX_CATEGORY.CAT_PUBLIC_ID%TYPE
  ) RETURN t_category_record IS
    l_record cat_repository_pkg.t_category_record;
    l_empty  t_category_record;
  BEGIN
    l_record := cat_repository_pkg.get_by_public_id(p_public_id);
    RETURN to_public_record(l_record);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN l_empty;
  END get_by_public_id;

  FUNCTION require_by_public_id(
    p_public_id IN BEX_CATEGORY.CAT_PUBLIC_ID%TYPE
  ) RETURN t_category_record IS
    l_result t_category_record;
  BEGIN
    l_result := get_by_public_id(p_public_id);
    IF l_result.category_public_id IS NULL THEN
      RAISE e_category_not_found;
    END IF;
    RETURN l_result;
  END require_by_public_id;

  FUNCTION get_by_slug(
    p_slug IN BEX_CATEGORY.CAT_SLUG%TYPE
  ) RETURN t_category_record IS
    l_slug   VARCHAR2(32767);
    l_record cat_repository_pkg.t_category_record;
    l_empty  t_category_record;
  BEGIN
    l_slug := cat_rule_pkg.normalize_slug(p_slug);
    cat_rule_pkg.validate_slug(l_slug);
    l_record := cat_repository_pkg.get_by_slug(l_slug);
    RETURN to_public_record(l_record);
  EXCEPTION
    WHEN cat_rule_pkg.e_slug_required
      OR cat_rule_pkg.e_invalid_slug THEN
      RETURN l_empty;
    WHEN NO_DATA_FOUND THEN
      RETURN l_empty;
  END get_by_slug;

  FUNCTION require_by_slug(
    p_slug IN BEX_CATEGORY.CAT_SLUG%TYPE
  ) RETURN t_category_record IS
    l_result t_category_record;
  BEGIN
    l_result := get_by_slug(p_slug);
    IF l_result.category_public_id IS NULL THEN
      RAISE e_category_not_found;
    END IF;
    RETURN l_result;
  END require_by_slug;

  FUNCTION list_categories(
    p_status IN BEX_CATEGORY.CAT_STATUS%TYPE DEFAULT NULL
  ) RETURN t_category_table IS
    l_status   VARCHAR2(32767);
    l_internal cat_repository_pkg.t_category_table;
    l_result   t_category_table;
    l_index    PLS_INTEGER;
  BEGIN
    IF p_status IS NOT NULL THEN
      l_status := cat_rule_pkg.normalize_status(p_status);
      BEGIN
        cat_rule_pkg.validate_status(l_status);
      EXCEPTION
        WHEN cat_rule_pkg.e_invalid_status THEN
          RAISE e_invalid_status;
      END;
    END IF;

    l_internal := cat_repository_pkg.list_all(l_status);
    l_index := l_internal.FIRST;
    WHILE l_index IS NOT NULL LOOP
      l_result(l_result.COUNT + 1) := to_public_record(l_internal(l_index));
      l_index := l_internal.NEXT(l_index);
    END LOOP;
    RETURN l_result;
  END list_categories;

  FUNCTION resolve_active_category_id(
    p_public_id IN BEX_CATEGORY.CAT_PUBLIC_ID%TYPE
  ) RETURN BEX_CATEGORY.CAT_ID%TYPE IS
    l_record cat_repository_pkg.t_category_record;
  BEGIN
    BEGIN
      l_record := cat_repository_pkg.get_by_public_id(p_public_id);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        RAISE e_category_not_found;
    END;

    IF l_record.cat_status <> cat_rule_pkg.c_status_active THEN
      RAISE e_category_inactive;
    END IF;
    RETURN l_record.cat_id;
  END resolve_active_category_id;

  FUNCTION resolve_category_public_id(
    p_category_id IN BEX_CATEGORY.CAT_ID%TYPE
  ) RETURN BEX_CATEGORY.CAT_PUBLIC_ID%TYPE IS
    l_record cat_repository_pkg.t_category_record;
  BEGIN
    BEGIN
      l_record := cat_repository_pkg.get_by_id(p_category_id);
    EXCEPTION
      WHEN NO_DATA_FOUND THEN RAISE e_category_not_found;
    END;
    RETURN l_record.cat_public_id;
  END resolve_category_public_id;
END cat_service_pkg;
/
