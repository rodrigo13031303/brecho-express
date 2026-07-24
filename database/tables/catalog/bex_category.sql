WHENEVER SQLERROR EXIT SQL.SQLCODE;

DECLARE
  l_object_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO l_object_count
    FROM USER_OBJECTS
   WHERE OBJECT_NAME = 'BEX_CATEGORY';

  IF l_object_count > 0 THEN
    RAISE_APPLICATION_ERROR(
      -20000,
      'BEX_CATEGORY already exists or conflicts with an existing object'
    );
  END IF;
END;
/

CREATE TABLE BEX_CATEGORY
(
  CAT_ID          NUMBER(19)
                  GENERATED ALWAYS AS IDENTITY
                  (
                    START WITH 1
                    INCREMENT BY 1
                    CACHE 20
                    NOCYCLE
                  ),
  CAT_PUBLIC_ID   CHAR(32 CHAR) NOT NULL,
  CAT_NAME        VARCHAR2(200 CHAR) NOT NULL,
  CAT_SLUG        VARCHAR2(120 CHAR) NOT NULL,
  CAT_DESCRIPTION VARCHAR2(1000 CHAR),
  CAT_STATUS      VARCHAR2(20 CHAR) DEFAULT 'ACTIVE' NOT NULL,
  CAT_CREATED_AT  TIMESTAMP(6) DEFAULT SYSTIMESTAMP NOT NULL,
  CAT_CREATED_BY  NUMBER,
  CAT_UPDATED_AT  TIMESTAMP(6) DEFAULT SYSTIMESTAMP NOT NULL,
  CAT_UPDATED_BY  NUMBER,
  CONSTRAINT PK_CATEGORY
    PRIMARY KEY (CAT_ID),
  CONSTRAINT UK_CATEGORY_PUBLIC_ID
    UNIQUE (CAT_PUBLIC_ID),
  CONSTRAINT UK_CATEGORY_SLUG
    UNIQUE (CAT_SLUG),
  CONSTRAINT CK_CATEGORY_STATUS
    CHECK (CAT_STATUS IN ('ACTIVE', 'INACTIVE'))
);

COMMENT ON TABLE BEX_CATEGORY IS
  'Official classification used to organize catalog products';
COMMENT ON COLUMN BEX_CATEGORY.CAT_ID IS
  'Internal technical identifier generated exclusively by Oracle';
COMMENT ON COLUMN BEX_CATEGORY.CAT_PUBLIC_ID IS
  'Immutable public identifier assigned by the application service';
COMMENT ON COLUMN BEX_CATEGORY.CAT_NAME IS
  'Public display name of the category';
COMMENT ON COLUMN BEX_CATEGORY.CAT_SLUG IS
  'Unique canonical segment used by category URLs and filters';
COMMENT ON COLUMN BEX_CATEGORY.CAT_DESCRIPTION IS
  'Optional public description of the category';
COMMENT ON COLUMN BEX_CATEGORY.CAT_STATUS IS
  'Current availability status of the category';
COMMENT ON COLUMN BEX_CATEGORY.CAT_CREATED_AT IS
  'Timestamp when the category record was created';
COMMENT ON COLUMN BEX_CATEGORY.CAT_CREATED_BY IS
  'Optional technical identifier of the actor that created the category';
COMMENT ON COLUMN BEX_CATEGORY.CAT_UPDATED_AT IS
  'Timestamp of the last effective change to the category record';
COMMENT ON COLUMN BEX_CATEGORY.CAT_UPDATED_BY IS
  'Optional technical identifier of the actor that last changed the category';

CREATE INDEX IDX_CATEGORY_STATUS
  ON BEX_CATEGORY (CAT_STATUS);

DECLARE
  l_table_count      PLS_INTEGER;
  l_column_count     PLS_INTEGER;
  l_constraint_count PLS_INTEGER;
  l_index_count      PLS_INTEGER;
BEGIN
  SELECT COUNT(*) INTO l_table_count
    FROM USER_TABLES
   WHERE TABLE_NAME = 'BEX_CATEGORY';

  SELECT COUNT(*) INTO l_column_count
    FROM USER_TAB_COLUMNS
   WHERE TABLE_NAME = 'BEX_CATEGORY';

  SELECT COUNT(*) INTO l_constraint_count
    FROM USER_CONSTRAINTS
   WHERE TABLE_NAME = 'BEX_CATEGORY'
     AND (
       (CONSTRAINT_NAME = 'PK_CATEGORY' AND CONSTRAINT_TYPE = 'P')
       OR (CONSTRAINT_NAME = 'UK_CATEGORY_PUBLIC_ID' AND CONSTRAINT_TYPE = 'U')
       OR (CONSTRAINT_NAME = 'UK_CATEGORY_SLUG' AND CONSTRAINT_TYPE = 'U')
       OR (CONSTRAINT_NAME = 'CK_CATEGORY_STATUS' AND CONSTRAINT_TYPE = 'C')
     );

  SELECT COUNT(*) INTO l_index_count
    FROM USER_INDEXES
   WHERE TABLE_NAME = 'BEX_CATEGORY'
     AND INDEX_NAME = 'IDX_CATEGORY_STATUS';

  IF l_table_count <> 1
     OR l_column_count <> 10
     OR l_constraint_count <> 4
     OR l_index_count <> 1 THEN
    RAISE_APPLICATION_ERROR(
      -20001,
      'BEX_CATEGORY physical structure validation failed'
    );
  END IF;
END;
/
