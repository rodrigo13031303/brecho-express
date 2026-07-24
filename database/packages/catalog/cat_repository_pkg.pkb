CREATE OR REPLACE PACKAGE BODY cat_repository_pkg AS
  FUNCTION select_by_id(
    p_category_id IN BEX_CATEGORY.CAT_ID%TYPE
  ) RETURN t_category_record IS
    l_record t_category_record;
  BEGIN
    SELECT CAT_ID, CAT_PUBLIC_ID, CAT_NAME, CAT_SLUG, CAT_DESCRIPTION,
           CAT_STATUS, CAT_CREATED_AT, CAT_CREATED_BY, CAT_UPDATED_AT,
           CAT_UPDATED_BY
      INTO l_record
      FROM BEX_CATEGORY
     WHERE CAT_ID = p_category_id;
    RETURN l_record;
  END select_by_id;

  PROCEDURE insert_category(
    p_public_id IN BEX_CATEGORY.CAT_PUBLIC_ID%TYPE,
    p_name IN BEX_CATEGORY.CAT_NAME%TYPE,
    p_slug IN BEX_CATEGORY.CAT_SLUG%TYPE,
    p_description IN BEX_CATEGORY.CAT_DESCRIPTION%TYPE,
    p_status IN BEX_CATEGORY.CAT_STATUS%TYPE,
    p_created_by IN BEX_CATEGORY.CAT_CREATED_BY%TYPE,
    p_updated_by IN BEX_CATEGORY.CAT_UPDATED_BY%TYPE,
    o_category_id OUT BEX_CATEGORY.CAT_ID%TYPE
  ) IS
  BEGIN
    INSERT INTO BEX_CATEGORY(
      CAT_PUBLIC_ID, CAT_NAME, CAT_SLUG, CAT_DESCRIPTION, CAT_STATUS,
      CAT_CREATED_BY, CAT_UPDATED_BY
    ) VALUES (
      p_public_id, p_name, p_slug, p_description, p_status,
      p_created_by, p_updated_by
    ) RETURNING CAT_ID INTO o_category_id;
  END insert_category;

  FUNCTION get_by_id(
    p_category_id IN BEX_CATEGORY.CAT_ID%TYPE
  ) RETURN t_category_record IS
  BEGIN
    RETURN select_by_id(p_category_id);
  END get_by_id;

  FUNCTION get_by_public_id(
    p_public_id IN BEX_CATEGORY.CAT_PUBLIC_ID%TYPE
  ) RETURN t_category_record IS
    l_record t_category_record;
  BEGIN
    SELECT CAT_ID, CAT_PUBLIC_ID, CAT_NAME, CAT_SLUG, CAT_DESCRIPTION,
           CAT_STATUS, CAT_CREATED_AT, CAT_CREATED_BY, CAT_UPDATED_AT,
           CAT_UPDATED_BY
      INTO l_record
      FROM BEX_CATEGORY
     WHERE CAT_PUBLIC_ID = p_public_id;
    RETURN l_record;
  END get_by_public_id;

  FUNCTION get_by_slug(
    p_slug IN BEX_CATEGORY.CAT_SLUG%TYPE
  ) RETURN t_category_record IS
    l_record t_category_record;
  BEGIN
    SELECT CAT_ID, CAT_PUBLIC_ID, CAT_NAME, CAT_SLUG, CAT_DESCRIPTION,
           CAT_STATUS, CAT_CREATED_AT, CAT_CREATED_BY, CAT_UPDATED_AT,
           CAT_UPDATED_BY
      INTO l_record
      FROM BEX_CATEGORY
     WHERE CAT_SLUG = p_slug;
    RETURN l_record;
  END get_by_slug;

  PROCEDURE lock_by_id(
    p_category_id IN BEX_CATEGORY.CAT_ID%TYPE
  ) IS
    l_id BEX_CATEGORY.CAT_ID%TYPE;
  BEGIN
    SELECT CAT_ID INTO l_id
      FROM BEX_CATEGORY
     WHERE CAT_ID = p_category_id
       FOR UPDATE;
  END lock_by_id;

  FUNCTION public_id_exists(
    p_public_id IN BEX_CATEGORY.CAT_PUBLIC_ID%TYPE
  ) RETURN BOOLEAN IS
    l_count PLS_INTEGER;
  BEGIN
    SELECT COUNT(*) INTO l_count FROM BEX_CATEGORY
     WHERE CAT_PUBLIC_ID = p_public_id;
    RETURN l_count > 0;
  END public_id_exists;

  FUNCTION slug_exists(
    p_slug IN BEX_CATEGORY.CAT_SLUG%TYPE
  ) RETURN BOOLEAN IS
    l_count PLS_INTEGER;
  BEGIN
    SELECT COUNT(*) INTO l_count FROM BEX_CATEGORY WHERE CAT_SLUG = p_slug;
    RETURN l_count > 0;
  END slug_exists;

  FUNCTION list_all(
    p_status IN BEX_CATEGORY.CAT_STATUS%TYPE DEFAULT NULL
  ) RETURN t_category_table IS
    l_rows t_category_table;
  BEGIN
    SELECT CAT_ID, CAT_PUBLIC_ID, CAT_NAME, CAT_SLUG, CAT_DESCRIPTION,
           CAT_STATUS, CAT_CREATED_AT, CAT_CREATED_BY, CAT_UPDATED_AT,
           CAT_UPDATED_BY
      BULK COLLECT INTO l_rows
      FROM BEX_CATEGORY
     WHERE p_status IS NULL OR CAT_STATUS = p_status
     ORDER BY CAT_NAME, CAT_ID;
    RETURN l_rows;
  END list_all;

  PROCEDURE update_category(
    p_category_id IN BEX_CATEGORY.CAT_ID%TYPE,
    p_name IN BEX_CATEGORY.CAT_NAME%TYPE,
    p_slug IN BEX_CATEGORY.CAT_SLUG%TYPE,
    p_description IN BEX_CATEGORY.CAT_DESCRIPTION%TYPE,
    p_updated_at IN BEX_CATEGORY.CAT_UPDATED_AT%TYPE,
    p_updated_by IN BEX_CATEGORY.CAT_UPDATED_BY%TYPE,
    o_updated OUT BOOLEAN
  ) IS
  BEGIN
    UPDATE BEX_CATEGORY
       SET CAT_NAME = p_name,
           CAT_SLUG = p_slug,
           CAT_DESCRIPTION = p_description,
           CAT_UPDATED_AT = p_updated_at,
           CAT_UPDATED_BY = p_updated_by
     WHERE CAT_ID = p_category_id;
    o_updated := SQL%ROWCOUNT = 1;
  END update_category;

  PROCEDURE update_status(
    p_category_id IN BEX_CATEGORY.CAT_ID%TYPE,
    p_status IN BEX_CATEGORY.CAT_STATUS%TYPE,
    p_updated_at IN BEX_CATEGORY.CAT_UPDATED_AT%TYPE,
    p_updated_by IN BEX_CATEGORY.CAT_UPDATED_BY%TYPE,
    o_updated OUT BOOLEAN
  ) IS
  BEGIN
    UPDATE BEX_CATEGORY
       SET CAT_STATUS = p_status,
           CAT_UPDATED_AT = p_updated_at,
           CAT_UPDATED_BY = p_updated_by
     WHERE CAT_ID = p_category_id;
    o_updated := SQL%ROWCOUNT = 1;
  END update_status;
END cat_repository_pkg;
/
