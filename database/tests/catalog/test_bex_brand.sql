SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  l_count PLS_INTEGER;
  l_id BEX_BRAND.BRD_ID%TYPE;
  l_public BEX_BRAND.BRD_PUBLIC_ID%TYPE;
  l_slug BEX_BRAND.BRD_SLUG%TYPE;
  l_status BEX_BRAND.BRD_STATUS%TYPE;
  l_created BEX_BRAND.BRD_CREATED_AT%TYPE;
  l_updated BEX_BRAND.BRD_UPDATED_AT%TYPE;
  l_condition USER_CONSTRAINTS.SEARCH_CONDITION_VC%TYPE;

  PROCEDURE fail(p_message VARCHAR2) IS
  BEGIN RAISE_APPLICATION_ERROR(-20999,p_message); END;
  PROCEDURE assert_true(p_condition BOOLEAN,p_message VARCHAR2) IS
  BEGIN IF p_condition IS NULL OR NOT p_condition THEN fail(p_message); END IF; END;
BEGIN
  SELECT COUNT(*) INTO l_count FROM USER_TABLES
   WHERE TABLE_NAME='BEX_BRAND';
  assert_true(l_count=1,'BEX_BRAND deve existir.');

  SELECT COUNT(*) INTO l_count FROM USER_TAB_COLUMNS
   WHERE TABLE_NAME='BEX_BRAND';
  assert_true(l_count=10,'BEX_BRAND deve possuir 10 colunas.');

  SELECT COUNT(*) INTO l_count FROM USER_TAB_COLUMNS
   WHERE TABLE_NAME='BEX_BRAND'
     AND (
       (COLUMN_NAME='BRD_ID' AND DATA_TYPE='NUMBER'
        AND DATA_PRECISION=19 AND NULLABLE='N')
       OR (COLUMN_NAME='BRD_PUBLIC_ID' AND DATA_TYPE='CHAR'
        AND CHAR_LENGTH=32 AND CHAR_USED='C' AND NULLABLE='N')
       OR (COLUMN_NAME='BRD_NAME' AND DATA_TYPE='VARCHAR2'
        AND CHAR_LENGTH=200 AND CHAR_USED='C' AND NULLABLE='N')
       OR (COLUMN_NAME='BRD_SLUG' AND DATA_TYPE='VARCHAR2'
        AND CHAR_LENGTH=120 AND CHAR_USED='C' AND NULLABLE='N')
       OR (COLUMN_NAME='BRD_DESCRIPTION' AND DATA_TYPE='VARCHAR2'
        AND CHAR_LENGTH=1000 AND CHAR_USED='C' AND NULLABLE='Y')
       OR (COLUMN_NAME='BRD_STATUS' AND DATA_TYPE='VARCHAR2'
        AND CHAR_LENGTH=20 AND CHAR_USED='C' AND NULLABLE='N')
       OR (COLUMN_NAME IN ('BRD_CREATED_AT','BRD_UPDATED_AT')
        AND DATA_TYPE='TIMESTAMP(6)' AND DATA_SCALE=6 AND NULLABLE='N')
       OR (COLUMN_NAME IN ('BRD_CREATED_BY','BRD_UPDATED_BY')
        AND DATA_TYPE='NUMBER' AND NULLABLE='Y')
     );
  assert_true(l_count=10,'Tipos ou nulabilidade de BRAND divergentes.');

  SELECT COUNT(*) INTO l_count FROM USER_TAB_IDENTITY_COLS
   WHERE TABLE_NAME='BEX_BRAND' AND COLUMN_NAME='BRD_ID'
     AND GENERATION_TYPE='ALWAYS';
  assert_true(l_count=1,'BRD_ID deve ser identity ALWAYS.');

  SELECT COUNT(*) INTO l_count FROM USER_CONSTRAINTS
   WHERE TABLE_NAME='BEX_BRAND'
     AND CONSTRAINT_NAME IN (
       'PK_BRAND','UK_BRAND_PUBLIC_ID',
       'UK_BRAND_SLUG','CK_BRAND_STATUS'
     )
     AND STATUS='ENABLED' AND VALIDATED='VALIDATED';
  assert_true(l_count=4,'Constraints de BRAND divergentes.');

  SELECT SEARCH_CONDITION_VC INTO l_condition FROM USER_CONSTRAINTS
   WHERE TABLE_NAME='BEX_BRAND'
     AND CONSTRAINT_NAME='CK_BRAND_STATUS';
  assert_true(
    INSTR(UPPER(l_condition),'''ACTIVE''')>0
    AND INSTR(UPPER(l_condition),'''INACTIVE''')>0,
    'Status oficiais ausentes.'
  );

  SELECT COUNT(*) INTO l_count FROM USER_INDEXES
   WHERE TABLE_NAME='BEX_BRAND'
     AND INDEX_NAME IN (
       'PK_BRAND','UK_BRAND_PUBLIC_ID',
       'UK_BRAND_SLUG','IDX_BRAND_STATUS'
     );
  assert_true(l_count=4,'Indices de BRAND divergentes.');

  SELECT COUNT(*) INTO l_count FROM USER_CONSTRAINTS
   WHERE TABLE_NAME='BEX_BRAND' AND CONSTRAINT_TYPE='R';
  assert_true(l_count=0,'BRAND nao deve possuir foreign keys.');

  SELECT COUNT(*) INTO l_count FROM USER_TRIGGERS
   WHERE TABLE_NAME='BEX_BRAND';
  assert_true(l_count=0,'BRAND nao deve possuir triggers.');

  SELECT COUNT(*) INTO l_count FROM USER_COL_COMMENTS
   WHERE TABLE_NAME='BEX_BRAND' AND COMMENTS IS NOT NULL;
  assert_true(l_count=10,'Todas as colunas devem possuir comentario.');

  l_public:=LOWER(RAWTOHEX(SYS_GUID()));
  l_slug:='brand-'||LOWER(SUBSTR(RAWTOHEX(SYS_GUID()),1,12));
  INSERT INTO BEX_BRAND(BRD_PUBLIC_ID,BRD_NAME,BRD_SLUG)
  VALUES(l_public,'Brand Physical Test',l_slug)
  RETURNING BRD_ID,BRD_STATUS,BRD_CREATED_AT,BRD_UPDATED_AT
       INTO l_id,l_status,l_created,l_updated;
  assert_true(
    l_id IS NOT NULL AND l_status='ACTIVE'
    AND l_created IS NOT NULL AND l_updated IS NOT NULL,
    'Defaults de BRAND divergentes.'
  );

  BEGIN
    INSERT INTO BEX_BRAND(BRD_PUBLIC_ID,BRD_NAME,BRD_SLUG)
    VALUES(l_public,'Duplicate Public',l_slug||'-public');
    fail('Public ID duplicado deveria falhar.');
  EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
    assert_true(
      INSTR(UPPER(SQLERRM),'UK_BRAND_PUBLIC_ID')>0,
      'Constraint de Public ID incorreta.'
    );
  END;

  BEGIN
    INSERT INTO BEX_BRAND(BRD_PUBLIC_ID,BRD_NAME,BRD_SLUG)
    VALUES(LOWER(RAWTOHEX(SYS_GUID())),'Duplicate Slug',l_slug);
    fail('Slug duplicado deveria falhar.');
  EXCEPTION WHEN DUP_VAL_ON_INDEX THEN
    assert_true(
      INSTR(UPPER(SQLERRM),'UK_BRAND_SLUG')>0,
      'Constraint de slug incorreta.'
    );
  END;

  BEGIN
    INSERT INTO BEX_BRAND(
      BRD_PUBLIC_ID,BRD_NAME,BRD_SLUG,BRD_STATUS
    ) VALUES(
      LOWER(RAWTOHEX(SYS_GUID())),'Invalid Status',
      l_slug||'-invalid','BLOCKED'
    );
    fail('Status invalido deveria falhar.');
  EXCEPTION WHEN OTHERS THEN
    assert_true(
      SQLCODE=-2290
      AND INSTR(UPPER(SQLERRM),'CK_BRAND_STATUS')>0,
      'CK_BRAND_STATUS nao foi aplicada.'
    );
  END;

  DBMS_OUTPUT.PUT_LINE('BEX_BRAND physical contract: PASSED');
  ROLLBACK;
EXCEPTION WHEN OTHERS THEN
  ROLLBACK;
  RAISE;
END;
/
