CREATE OR REPLACE PACKAGE BODY prd_repository_pkg AS
  FUNCTION get_by_id(p_product_id BEX_PRODUCT.PRD_ID%TYPE)
    RETURN t_product_record IS l_row t_product_record;
  BEGIN
    SELECT PRD_ID,PRD_PUBLIC_ID,STR_ID,CAT_ID,BRD_ID,PRD_TITLE,PRD_SLUG,
      PRD_DESCRIPTION,PRD_PRICE,PRD_QUANTITY,PRD_CONDITION,PRD_WEIGHT,
      PRD_WIDTH,PRD_HEIGHT,PRD_LENGTH,PRD_STATUS,PRD_CREATED_AT,
      PRD_CREATED_BY,PRD_UPDATED_AT,PRD_UPDATED_BY
      INTO l_row FROM BEX_PRODUCT WHERE PRD_ID=p_product_id;
    RETURN l_row;
  END;

  PROCEDURE insert_product(
    p_product t_product_record,o_product_id OUT BEX_PRODUCT.PRD_ID%TYPE
  ) IS
  BEGIN
    INSERT INTO BEX_PRODUCT(
      PRD_PUBLIC_ID,STR_ID,CAT_ID,BRD_ID,PRD_TITLE,PRD_SLUG,
      PRD_DESCRIPTION,PRD_PRICE,PRD_QUANTITY,PRD_CONDITION,PRD_WEIGHT,
      PRD_WIDTH,PRD_HEIGHT,PRD_LENGTH,PRD_STATUS,PRD_CREATED_BY,PRD_UPDATED_BY
    ) VALUES(
      p_product.prd_public_id,p_product.str_id,p_product.cat_id,p_product.brd_id,
      p_product.prd_title,p_product.prd_slug,p_product.prd_description,
      p_product.prd_price,p_product.prd_quantity,p_product.prd_condition,
      p_product.prd_weight,p_product.prd_width,p_product.prd_height,
      p_product.prd_length,p_product.prd_status,p_product.prd_created_by,
      p_product.prd_updated_by
    ) RETURNING PRD_ID INTO o_product_id;
  END;

  FUNCTION get_by_public_id(p_public_id BEX_PRODUCT.PRD_PUBLIC_ID%TYPE)
    RETURN t_product_record IS l_row t_product_record;
  BEGIN
    SELECT PRD_ID,PRD_PUBLIC_ID,STR_ID,CAT_ID,BRD_ID,PRD_TITLE,PRD_SLUG,
      PRD_DESCRIPTION,PRD_PRICE,PRD_QUANTITY,PRD_CONDITION,PRD_WEIGHT,
      PRD_WIDTH,PRD_HEIGHT,PRD_LENGTH,PRD_STATUS,PRD_CREATED_AT,
      PRD_CREATED_BY,PRD_UPDATED_AT,PRD_UPDATED_BY
      INTO l_row FROM BEX_PRODUCT WHERE PRD_PUBLIC_ID=p_public_id;
    RETURN l_row;
  END;

  FUNCTION get_by_store_slug(
    p_store_id BEX_PRODUCT.STR_ID%TYPE,p_slug BEX_PRODUCT.PRD_SLUG%TYPE
  ) RETURN t_product_record IS l_row t_product_record;
  BEGIN
    SELECT PRD_ID,PRD_PUBLIC_ID,STR_ID,CAT_ID,BRD_ID,PRD_TITLE,PRD_SLUG,
      PRD_DESCRIPTION,PRD_PRICE,PRD_QUANTITY,PRD_CONDITION,PRD_WEIGHT,
      PRD_WIDTH,PRD_HEIGHT,PRD_LENGTH,PRD_STATUS,PRD_CREATED_AT,
      PRD_CREATED_BY,PRD_UPDATED_AT,PRD_UPDATED_BY
      INTO l_row FROM BEX_PRODUCT
     WHERE STR_ID=p_store_id AND PRD_SLUG=p_slug;
    RETURN l_row;
  END;

  PROCEDURE lock_by_id(p_product_id BEX_PRODUCT.PRD_ID%TYPE) IS
    l_id BEX_PRODUCT.PRD_ID%TYPE;
  BEGIN
    SELECT PRD_ID INTO l_id FROM BEX_PRODUCT
     WHERE PRD_ID=p_product_id FOR UPDATE;
  END;

  FUNCTION public_id_exists(p_public_id BEX_PRODUCT.PRD_PUBLIC_ID%TYPE)
    RETURN BOOLEAN IS l_count PLS_INTEGER;
  BEGIN
    SELECT COUNT(*) INTO l_count FROM BEX_PRODUCT
     WHERE PRD_PUBLIC_ID=p_public_id;
    RETURN l_count>0;
  END;

  FUNCTION slug_exists(
    p_store_id BEX_PRODUCT.STR_ID%TYPE,
    p_slug BEX_PRODUCT.PRD_SLUG%TYPE,
    p_exclude_product_id BEX_PRODUCT.PRD_ID%TYPE DEFAULT NULL
  ) RETURN BOOLEAN IS l_count PLS_INTEGER;
  BEGIN
    SELECT COUNT(*) INTO l_count FROM BEX_PRODUCT
     WHERE STR_ID=p_store_id AND PRD_SLUG=p_slug
       AND (p_exclude_product_id IS NULL OR PRD_ID<>p_exclude_product_id);
    RETURN l_count>0;
  END;

  FUNCTION list_by_store(
    p_store_id BEX_PRODUCT.STR_ID%TYPE,
    p_status BEX_PRODUCT.PRD_STATUS%TYPE DEFAULT NULL
  ) RETURN t_product_table IS l_rows t_product_table;
  BEGIN
    SELECT PRD_ID,PRD_PUBLIC_ID,STR_ID,CAT_ID,BRD_ID,PRD_TITLE,PRD_SLUG,
      PRD_DESCRIPTION,PRD_PRICE,PRD_QUANTITY,PRD_CONDITION,PRD_WEIGHT,
      PRD_WIDTH,PRD_HEIGHT,PRD_LENGTH,PRD_STATUS,PRD_CREATED_AT,
      PRD_CREATED_BY,PRD_UPDATED_AT,PRD_UPDATED_BY
      BULK COLLECT INTO l_rows FROM BEX_PRODUCT
     WHERE STR_ID=p_store_id AND (p_status IS NULL OR PRD_STATUS=p_status)
     ORDER BY PRD_UPDATED_AT DESC,PRD_ID DESC;
    RETURN l_rows;
  END;

  FUNCTION list_public(
    p_category_id BEX_PRODUCT.CAT_ID%TYPE DEFAULT NULL,
    p_brand_id BEX_PRODUCT.BRD_ID%TYPE DEFAULT NULL,
    p_condition BEX_PRODUCT.PRD_CONDITION%TYPE DEFAULT NULL
  ) RETURN t_product_table IS l_rows t_product_table;
  BEGIN
    SELECT PRD_ID,PRD_PUBLIC_ID,STR_ID,CAT_ID,BRD_ID,PRD_TITLE,PRD_SLUG,
      PRD_DESCRIPTION,PRD_PRICE,PRD_QUANTITY,PRD_CONDITION,PRD_WEIGHT,
      PRD_WIDTH,PRD_HEIGHT,PRD_LENGTH,PRD_STATUS,PRD_CREATED_AT,
      PRD_CREATED_BY,PRD_UPDATED_AT,PRD_UPDATED_BY
      BULK COLLECT INTO l_rows FROM BEX_PRODUCT
     WHERE PRD_STATUS='ACTIVE' AND PRD_QUANTITY>0
       AND (p_category_id IS NULL OR CAT_ID=p_category_id)
       AND (p_brand_id IS NULL OR BRD_ID=p_brand_id)
       AND (p_condition IS NULL OR PRD_CONDITION=p_condition)
     ORDER BY PRD_UPDATED_AT DESC,PRD_ID DESC;
    RETURN l_rows;
  END;

  PROCEDURE update_product(
    p_product t_product_record,o_updated OUT BOOLEAN
  ) IS
  BEGIN
    UPDATE BEX_PRODUCT SET CAT_ID=p_product.cat_id,BRD_ID=p_product.brd_id,
      PRD_TITLE=p_product.prd_title,PRD_SLUG=p_product.prd_slug,
      PRD_DESCRIPTION=p_product.prd_description,PRD_PRICE=p_product.prd_price,
      PRD_QUANTITY=p_product.prd_quantity,
      PRD_CONDITION=p_product.prd_condition,PRD_WEIGHT=p_product.prd_weight,
      PRD_WIDTH=p_product.prd_width,PRD_HEIGHT=p_product.prd_height,
      PRD_LENGTH=p_product.prd_length,PRD_UPDATED_AT=p_product.prd_updated_at,
      PRD_UPDATED_BY=p_product.prd_updated_by
     WHERE PRD_ID=p_product.prd_id;
    o_updated:=SQL%ROWCOUNT=1;
  END;

  PROCEDURE update_status(
    p_product_id BEX_PRODUCT.PRD_ID%TYPE,
    p_status BEX_PRODUCT.PRD_STATUS%TYPE,
    p_updated_at BEX_PRODUCT.PRD_UPDATED_AT%TYPE,
    p_updated_by BEX_PRODUCT.PRD_UPDATED_BY%TYPE,
    o_updated OUT BOOLEAN
  ) IS
  BEGIN
    UPDATE BEX_PRODUCT SET PRD_STATUS=p_status,PRD_UPDATED_AT=p_updated_at,
      PRD_UPDATED_BY=p_updated_by WHERE PRD_ID=p_product_id;
    o_updated:=SQL%ROWCOUNT=1;
  END;
END prd_repository_pkg;
/
