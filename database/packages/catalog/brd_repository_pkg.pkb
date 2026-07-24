CREATE OR REPLACE PACKAGE BODY brd_repository_pkg AS
  FUNCTION get_by_id(p_brand_id BEX_BRAND.BRD_ID%TYPE)
    RETURN t_brand_record IS l_record t_brand_record;
  BEGIN
    SELECT BRD_ID,BRD_PUBLIC_ID,BRD_NAME,BRD_SLUG,BRD_DESCRIPTION,
           BRD_STATUS,BRD_CREATED_AT,BRD_CREATED_BY,BRD_UPDATED_AT,
           BRD_UPDATED_BY INTO l_record
      FROM BEX_BRAND WHERE BRD_ID=p_brand_id;
    RETURN l_record;
  END;
  PROCEDURE insert_brand(
    p_public_id BEX_BRAND.BRD_PUBLIC_ID%TYPE,
    p_name BEX_BRAND.BRD_NAME%TYPE,p_slug BEX_BRAND.BRD_SLUG%TYPE,
    p_description BEX_BRAND.BRD_DESCRIPTION%TYPE,
    p_status BEX_BRAND.BRD_STATUS%TYPE,
    p_created_by BEX_BRAND.BRD_CREATED_BY%TYPE,
    p_updated_by BEX_BRAND.BRD_UPDATED_BY%TYPE,
    o_brand_id OUT BEX_BRAND.BRD_ID%TYPE
  ) IS
  BEGIN
    INSERT INTO BEX_BRAND(
      BRD_PUBLIC_ID,BRD_NAME,BRD_SLUG,BRD_DESCRIPTION,BRD_STATUS,
      BRD_CREATED_BY,BRD_UPDATED_BY
    ) VALUES(
      p_public_id,p_name,p_slug,p_description,p_status,
      p_created_by,p_updated_by
    ) RETURNING BRD_ID INTO o_brand_id;
  END;
  FUNCTION get_by_public_id(p_public_id BEX_BRAND.BRD_PUBLIC_ID%TYPE)
    RETURN t_brand_record IS l_record t_brand_record;
  BEGIN
    SELECT BRD_ID,BRD_PUBLIC_ID,BRD_NAME,BRD_SLUG,BRD_DESCRIPTION,
           BRD_STATUS,BRD_CREATED_AT,BRD_CREATED_BY,BRD_UPDATED_AT,
           BRD_UPDATED_BY INTO l_record
      FROM BEX_BRAND WHERE BRD_PUBLIC_ID=p_public_id;
    RETURN l_record;
  END;
  FUNCTION get_by_slug(p_slug BEX_BRAND.BRD_SLUG%TYPE)
    RETURN t_brand_record IS l_record t_brand_record;
  BEGIN
    SELECT BRD_ID,BRD_PUBLIC_ID,BRD_NAME,BRD_SLUG,BRD_DESCRIPTION,
           BRD_STATUS,BRD_CREATED_AT,BRD_CREATED_BY,BRD_UPDATED_AT,
           BRD_UPDATED_BY INTO l_record
      FROM BEX_BRAND WHERE BRD_SLUG=p_slug;
    RETURN l_record;
  END;
  PROCEDURE lock_by_id(p_brand_id BEX_BRAND.BRD_ID%TYPE) IS
    l_id BEX_BRAND.BRD_ID%TYPE;
  BEGIN
    SELECT BRD_ID INTO l_id FROM BEX_BRAND
     WHERE BRD_ID=p_brand_id FOR UPDATE;
  END;
  FUNCTION public_id_exists(p_public_id BEX_BRAND.BRD_PUBLIC_ID%TYPE)
    RETURN BOOLEAN IS l_count PLS_INTEGER;
  BEGIN
    SELECT COUNT(*) INTO l_count FROM BEX_BRAND
     WHERE BRD_PUBLIC_ID=p_public_id;
    RETURN l_count>0;
  END;
  FUNCTION slug_exists(p_slug BEX_BRAND.BRD_SLUG%TYPE)
    RETURN BOOLEAN IS l_count PLS_INTEGER;
  BEGIN
    SELECT COUNT(*) INTO l_count FROM BEX_BRAND WHERE BRD_SLUG=p_slug;
    RETURN l_count>0;
  END;
  FUNCTION list_all(p_status BEX_BRAND.BRD_STATUS%TYPE DEFAULT NULL)
    RETURN t_brand_table IS l_rows t_brand_table;
  BEGIN
    SELECT BRD_ID,BRD_PUBLIC_ID,BRD_NAME,BRD_SLUG,BRD_DESCRIPTION,
           BRD_STATUS,BRD_CREATED_AT,BRD_CREATED_BY,BRD_UPDATED_AT,
           BRD_UPDATED_BY BULK COLLECT INTO l_rows
      FROM BEX_BRAND
     WHERE p_status IS NULL OR BRD_STATUS=p_status
     ORDER BY BRD_NAME,BRD_ID;
    RETURN l_rows;
  END;
  PROCEDURE update_brand(
    p_brand_id BEX_BRAND.BRD_ID%TYPE,p_name BEX_BRAND.BRD_NAME%TYPE,
    p_slug BEX_BRAND.BRD_SLUG%TYPE,
    p_description BEX_BRAND.BRD_DESCRIPTION%TYPE,
    p_updated_at BEX_BRAND.BRD_UPDATED_AT%TYPE,
    p_updated_by BEX_BRAND.BRD_UPDATED_BY%TYPE,o_updated OUT BOOLEAN
  ) IS
  BEGIN
    UPDATE BEX_BRAND SET BRD_NAME=p_name,BRD_SLUG=p_slug,
      BRD_DESCRIPTION=p_description,BRD_UPDATED_AT=p_updated_at,
      BRD_UPDATED_BY=p_updated_by WHERE BRD_ID=p_brand_id;
    o_updated:=SQL%ROWCOUNT=1;
  END;
  PROCEDURE update_status(
    p_brand_id BEX_BRAND.BRD_ID%TYPE,p_status BEX_BRAND.BRD_STATUS%TYPE,
    p_updated_at BEX_BRAND.BRD_UPDATED_AT%TYPE,
    p_updated_by BEX_BRAND.BRD_UPDATED_BY%TYPE,o_updated OUT BOOLEAN
  ) IS
  BEGIN
    UPDATE BEX_BRAND SET BRD_STATUS=p_status,
      BRD_UPDATED_AT=p_updated_at,BRD_UPDATED_BY=p_updated_by
     WHERE BRD_ID=p_brand_id;
    o_updated:=SQL%ROWCOUNT=1;
  END;
END brd_repository_pkg;
/
