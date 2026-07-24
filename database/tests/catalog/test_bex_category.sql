SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  l_count        PLS_INTEGER;
  l_status       BEX_CATEGORY.CAT_STATUS%TYPE;
  l_created_at   BEX_CATEGORY.CAT_CREATED_AT%TYPE;
  l_updated_at   BEX_CATEGORY.CAT_UPDATED_AT%TYPE;
  l_public_id    BEX_CATEGORY.CAT_PUBLIC_ID%TYPE;
  l_other_public BEX_CATEGORY.CAT_PUBLIC_ID%TYPE;
  l_slug         BEX_CATEGORY.CAT_SLUG%TYPE;
  l_condition    USER_CONSTRAINTS.SEARCH_CONDITION_VC%TYPE;

  PROCEDURE fail(p_message IN VARCHAR2) IS
  BEGIN
    RAISE_APPLICATION_ERROR(-20999, p_message);
  END fail;

  PROCEDURE assert_true(
    p_condition IN BOOLEAN,
    p_message   IN VARCHAR2
  ) IS
  BEGIN
    IF p_condition IS NULL OR NOT p_condition THEN
      fail(p_message);
    END IF;
  END assert_true;
BEGIN
  SELECT COUNT(*) INTO l_count
    FROM USER_TABLES
   WHERE TABLE_NAME = 'BEX_CATEGORY';
  assert_true(l_count = 1, 'BEX_CATEGORY deve existir.');

  SELECT COUNT(*) INTO l_count
    FROM USER_TAB_COLUMNS
   WHERE TABLE_NAME = 'BEX_CATEGORY';
  assert_true(l_count = 10, 'BEX_CATEGORY deve possuir 10 colunas.');

  SELECT COUNT(*) INTO l_count
    FROM USER_TAB_COLUMNS
   WHERE TABLE_NAME = 'BEX_CATEGORY'
     AND (
       (COLUMN_NAME = 'CAT_ID' AND DATA_TYPE = 'NUMBER'
        AND DATA_PRECISION = 19 AND NULLABLE = 'N')
       OR (COLUMN_NAME = 'CAT_PUBLIC_ID' AND DATA_TYPE = 'CHAR'
        AND CHAR_LENGTH = 32 AND CHAR_USED = 'C' AND NULLABLE = 'N')
       OR (COLUMN_NAME = 'CAT_NAME' AND DATA_TYPE = 'VARCHAR2'
        AND CHAR_LENGTH = 200 AND CHAR_USED = 'C' AND NULLABLE = 'N')
       OR (COLUMN_NAME = 'CAT_SLUG' AND DATA_TYPE = 'VARCHAR2'
        AND CHAR_LENGTH = 120 AND CHAR_USED = 'C' AND NULLABLE = 'N')
       OR (COLUMN_NAME = 'CAT_DESCRIPTION' AND DATA_TYPE = 'VARCHAR2'
        AND CHAR_LENGTH = 1000 AND CHAR_USED = 'C' AND NULLABLE = 'Y')
       OR (COLUMN_NAME = 'CAT_STATUS' AND DATA_TYPE = 'VARCHAR2'
        AND CHAR_LENGTH = 20 AND CHAR_USED = 'C' AND NULLABLE = 'N')
       OR (COLUMN_NAME IN ('CAT_CREATED_AT', 'CAT_UPDATED_AT')
        AND DATA_TYPE = 'TIMESTAMP(6)' AND DATA_SCALE = 6
        AND NULLABLE = 'N')
       OR (COLUMN_NAME IN ('CAT_CREATED_BY', 'CAT_UPDATED_BY')
        AND DATA_TYPE = 'NUMBER' AND NULLABLE = 'Y')
     );
  assert_true(l_count = 10, 'Tipos ou nulabilidade de CATEGORY divergentes.');

  SELECT COUNT(*) INTO l_count
    FROM USER_TAB_IDENTITY_COLS
   WHERE TABLE_NAME = 'BEX_CATEGORY'
     AND COLUMN_NAME = 'CAT_ID'
     AND GENERATION_TYPE = 'ALWAYS';
  assert_true(l_count = 1, 'CAT_ID deve ser identity ALWAYS.');

  SELECT COUNT(*) INTO l_count
    FROM USER_CONSTRAINTS
   WHERE TABLE_NAME = 'BEX_CATEGORY'
     AND CONSTRAINT_NAME IN (
       'PK_CATEGORY',
       'UK_CATEGORY_PUBLIC_ID',
       'UK_CATEGORY_SLUG',
       'CK_CATEGORY_STATUS'
     )
     AND STATUS = 'ENABLED'
     AND VALIDATED = 'VALIDATED';
  assert_true(l_count = 4, 'Constraints de CATEGORY divergentes.');

  SELECT SEARCH_CONDITION_VC INTO l_condition
    FROM USER_CONSTRAINTS
   WHERE TABLE_NAME = 'BEX_CATEGORY'
     AND CONSTRAINT_NAME = 'CK_CATEGORY_STATUS';
  assert_true(
    INSTR(UPPER(l_condition), '''ACTIVE''') > 0
    AND INSTR(UPPER(l_condition), '''INACTIVE''') > 0,
    'CK_CATEGORY_STATUS deve conter ACTIVE e INACTIVE.'
  );

  SELECT COUNT(*) INTO l_count
    FROM USER_INDEXES
   WHERE TABLE_NAME = 'BEX_CATEGORY'
     AND INDEX_NAME IN (
       'PK_CATEGORY',
       'UK_CATEGORY_PUBLIC_ID',
       'UK_CATEGORY_SLUG',
       'IDX_CATEGORY_STATUS'
     );
  assert_true(l_count = 4, 'Indices de CATEGORY divergentes.');

  SELECT COUNT(*) INTO l_count
    FROM USER_TRIGGERS
   WHERE TABLE_NAME = 'BEX_CATEGORY';
  assert_true(l_count = 0, 'CATEGORY nao deve possuir triggers.');

  SELECT COUNT(*) INTO l_count
    FROM USER_CONSTRAINTS
   WHERE TABLE_NAME = 'BEX_CATEGORY'
     AND CONSTRAINT_TYPE = 'R';
  assert_true(l_count = 0, 'CATEGORY nao deve possuir foreign keys.');

  SELECT COUNT(*) INTO l_count
    FROM USER_COL_COMMENTS
   WHERE TABLE_NAME = 'BEX_CATEGORY'
     AND COMMENTS IS NOT NULL;
  assert_true(l_count = 10, 'Todas as colunas devem possuir comentario.');

  l_public_id := LOWER(RAWTOHEX(SYS_GUID()));
  l_other_public := LOWER(RAWTOHEX(SYS_GUID()));
  l_slug := 'category-' || LOWER(SUBSTR(RAWTOHEX(SYS_GUID()), 1, 12));

  INSERT INTO BEX_CATEGORY(
    CAT_PUBLIC_ID,
    CAT_NAME,
    CAT_SLUG
  ) VALUES (
    l_public_id,
    'Category Physical Test',
    l_slug
  )
  RETURNING CAT_STATUS, CAT_CREATED_AT, CAT_UPDATED_AT
       INTO l_status, l_created_at, l_updated_at;

  assert_true(
    l_status = 'ACTIVE'
    AND l_created_at IS NOT NULL
    AND l_updated_at IS NOT NULL,
    'Defaults de CATEGORY divergentes.'
  );

  BEGIN
    INSERT INTO BEX_CATEGORY(CAT_PUBLIC_ID, CAT_NAME, CAT_SLUG)
    VALUES(l_public_id, 'Duplicate Public', l_slug || '-public');
    fail('Public ID duplicado deveria falhar.');
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      assert_true(
        INSTR(UPPER(SQLERRM), 'UK_CATEGORY_PUBLIC_ID') > 0,
        'Constraint incorreta para Public ID duplicado.'
      );
  END;

  BEGIN
    INSERT INTO BEX_CATEGORY(CAT_PUBLIC_ID, CAT_NAME, CAT_SLUG)
    VALUES(l_other_public, 'Duplicate Slug', l_slug);
    fail('Slug duplicado deveria falhar.');
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      assert_true(
        INSTR(UPPER(SQLERRM), 'UK_CATEGORY_SLUG') > 0,
        'Constraint incorreta para slug duplicado.'
      );
  END;

  BEGIN
    INSERT INTO BEX_CATEGORY(
      CAT_PUBLIC_ID,
      CAT_NAME,
      CAT_SLUG,
      CAT_STATUS
    ) VALUES (
      LOWER(RAWTOHEX(SYS_GUID())),
      'Invalid Status',
      l_slug || '-invalid',
      'BLOCKED'
    );
    fail('Status invalido deveria falhar.');
  EXCEPTION
    WHEN OTHERS THEN
      assert_true(
        SQLCODE = -2290
        AND INSTR(UPPER(SQLERRM), 'CK_CATEGORY_STATUS') > 0,
        'CK_CATEGORY_STATUS nao foi aplicada.'
      );
  END;

  DBMS_OUTPUT.PUT_LINE('BEX_CATEGORY physical contract: PASSED');
  ROLLBACK;
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END;
/
