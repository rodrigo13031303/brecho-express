CREATE OR REPLACE PACKAGE cat_repository_pkg AS
  TYPE t_category_record IS RECORD (
    cat_id          BEX_CATEGORY.CAT_ID%TYPE,
    cat_public_id   BEX_CATEGORY.CAT_PUBLIC_ID%TYPE,
    cat_name        BEX_CATEGORY.CAT_NAME%TYPE,
    cat_slug        BEX_CATEGORY.CAT_SLUG%TYPE,
    cat_description BEX_CATEGORY.CAT_DESCRIPTION%TYPE,
    cat_status      BEX_CATEGORY.CAT_STATUS%TYPE,
    cat_created_at  BEX_CATEGORY.CAT_CREATED_AT%TYPE,
    cat_created_by  BEX_CATEGORY.CAT_CREATED_BY%TYPE,
    cat_updated_at  BEX_CATEGORY.CAT_UPDATED_AT%TYPE,
    cat_updated_by  BEX_CATEGORY.CAT_UPDATED_BY%TYPE
  );

  TYPE t_category_table IS TABLE OF t_category_record
    INDEX BY PLS_INTEGER;

  PROCEDURE insert_category(
    p_public_id   IN BEX_CATEGORY.CAT_PUBLIC_ID%TYPE,
    p_name        IN BEX_CATEGORY.CAT_NAME%TYPE,
    p_slug        IN BEX_CATEGORY.CAT_SLUG%TYPE,
    p_description IN BEX_CATEGORY.CAT_DESCRIPTION%TYPE,
    p_status      IN BEX_CATEGORY.CAT_STATUS%TYPE,
    p_created_by  IN BEX_CATEGORY.CAT_CREATED_BY%TYPE,
    p_updated_by  IN BEX_CATEGORY.CAT_UPDATED_BY%TYPE,
    o_category_id OUT BEX_CATEGORY.CAT_ID%TYPE
  );

  FUNCTION get_by_id(
    p_category_id IN BEX_CATEGORY.CAT_ID%TYPE
  ) RETURN t_category_record;

  FUNCTION get_by_public_id(
    p_public_id IN BEX_CATEGORY.CAT_PUBLIC_ID%TYPE
  ) RETURN t_category_record;

  FUNCTION get_by_slug(
    p_slug IN BEX_CATEGORY.CAT_SLUG%TYPE
  ) RETURN t_category_record;

  PROCEDURE lock_by_id(
    p_category_id IN BEX_CATEGORY.CAT_ID%TYPE
  );

  FUNCTION public_id_exists(
    p_public_id IN BEX_CATEGORY.CAT_PUBLIC_ID%TYPE
  ) RETURN BOOLEAN;

  FUNCTION slug_exists(
    p_slug IN BEX_CATEGORY.CAT_SLUG%TYPE
  ) RETURN BOOLEAN;

  FUNCTION list_all(
    p_status IN BEX_CATEGORY.CAT_STATUS%TYPE DEFAULT NULL
  ) RETURN t_category_table;

  PROCEDURE update_category(
    p_category_id    IN BEX_CATEGORY.CAT_ID%TYPE,
    p_name           IN BEX_CATEGORY.CAT_NAME%TYPE,
    p_slug           IN BEX_CATEGORY.CAT_SLUG%TYPE,
    p_description    IN BEX_CATEGORY.CAT_DESCRIPTION%TYPE,
    p_updated_at     IN BEX_CATEGORY.CAT_UPDATED_AT%TYPE,
    p_updated_by     IN BEX_CATEGORY.CAT_UPDATED_BY%TYPE,
    o_updated        OUT BOOLEAN
  );

  PROCEDURE update_status(
    p_category_id IN BEX_CATEGORY.CAT_ID%TYPE,
    p_status      IN BEX_CATEGORY.CAT_STATUS%TYPE,
    p_updated_at  IN BEX_CATEGORY.CAT_UPDATED_AT%TYPE,
    p_updated_by  IN BEX_CATEGORY.CAT_UPDATED_BY%TYPE,
    o_updated     OUT BOOLEAN
  );
END cat_repository_pkg;
/
