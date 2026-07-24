CREATE OR REPLACE PACKAGE BODY brd_service_pkg AS
  FUNCTION map_record(p brd_repository_pkg.t_brand_record)
    RETURN t_brand_record IS r t_brand_record;
  BEGIN
    IF p.brd_id IS NULL THEN RETURN r; END IF;
    r.brand_public_id:=p.brd_public_id; r.brand_name:=p.brd_name;
    r.brand_slug:=p.brd_slug; r.description:=p.brd_description;
    r.status:=p.brd_status; r.created_at:=p.brd_created_at;
    r.updated_at:=p.brd_updated_at; RETURN r;
  END;
  FUNCTION get_by_public_id(p_public_id BEX_BRAND.BRD_PUBLIC_ID%TYPE)
    RETURN t_brand_record IS p brd_repository_pkg.t_brand_record;
    r t_brand_record;
  BEGIN
    p:=brd_repository_pkg.get_by_public_id(p_public_id); RETURN map_record(p);
  EXCEPTION WHEN NO_DATA_FOUND THEN RETURN r; END;
  FUNCTION require_by_public_id(p_public_id BEX_BRAND.BRD_PUBLIC_ID%TYPE)
    RETURN t_brand_record IS r t_brand_record;
  BEGIN
    r:=get_by_public_id(p_public_id);
    IF r.brand_public_id IS NULL THEN RAISE e_brand_not_found; END IF;
    RETURN r;
  END;
  FUNCTION get_by_slug(p_slug BEX_BRAND.BRD_SLUG%TYPE)
    RETURN t_brand_record IS p brd_repository_pkg.t_brand_record;
    r t_brand_record; l_slug VARCHAR2(32767);
  BEGIN
    l_slug:=brd_rule_pkg.normalize_slug(p_slug);
    brd_rule_pkg.validate_slug(l_slug);
    p:=brd_repository_pkg.get_by_slug(l_slug); RETURN map_record(p);
  EXCEPTION
    WHEN brd_rule_pkg.e_slug_required OR brd_rule_pkg.e_invalid_slug
      THEN RETURN r;
    WHEN NO_DATA_FOUND THEN RETURN r;
  END;
  FUNCTION require_by_slug(p_slug BEX_BRAND.BRD_SLUG%TYPE)
    RETURN t_brand_record IS r t_brand_record;
  BEGIN
    r:=get_by_slug(p_slug);
    IF r.brand_public_id IS NULL THEN RAISE e_brand_not_found; END IF;
    RETURN r;
  END;
  FUNCTION list_brands(p_status BEX_BRAND.BRD_STATUS%TYPE DEFAULT NULL)
    RETURN t_brand_table IS l_status VARCHAR2(32767);
    p brd_repository_pkg.t_brand_table; r t_brand_table;
    i PLS_INTEGER;
  BEGIN
    IF p_status IS NOT NULL THEN
      l_status:=brd_rule_pkg.normalize_status(p_status);
      BEGIN brd_rule_pkg.validate_status(l_status);
      EXCEPTION WHEN brd_rule_pkg.e_invalid_status THEN
        RAISE e_invalid_status;
      END;
    END IF;
    p:=brd_repository_pkg.list_all(l_status); i:=p.FIRST;
    WHILE i IS NOT NULL LOOP
      r(r.COUNT+1):=map_record(p(i)); i:=p.NEXT(i);
    END LOOP;
    RETURN r;
  END;
  FUNCTION resolve_active_brand_id(p_public_id BEX_BRAND.BRD_PUBLIC_ID%TYPE)
    RETURN BEX_BRAND.BRD_ID%TYPE IS p brd_repository_pkg.t_brand_record;
  BEGIN
    BEGIN p:=brd_repository_pkg.get_by_public_id(p_public_id);
    EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_brand_not_found; END;
    IF p.brd_status<>brd_rule_pkg.c_status_active THEN
      RAISE e_brand_inactive;
    END IF;
    RETURN p.brd_id;
  END;
  FUNCTION resolve_brand_public_id(p_brand_id BEX_BRAND.BRD_ID%TYPE)
    RETURN BEX_BRAND.BRD_PUBLIC_ID%TYPE IS
    p brd_repository_pkg.t_brand_record;
  BEGIN
    BEGIN p:=brd_repository_pkg.get_by_id(p_brand_id);
    EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_brand_not_found; END;
    RETURN p.brd_public_id;
  END;
END brd_service_pkg;
/
