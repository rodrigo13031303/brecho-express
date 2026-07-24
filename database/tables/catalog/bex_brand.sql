WHENEVER SQLERROR EXIT SQL.SQLCODE;

DECLARE
  l_object_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*) INTO l_object_count
    FROM USER_OBJECTS
   WHERE OBJECT_NAME='BEX_BRAND';
  IF l_object_count>0 THEN
    RAISE_APPLICATION_ERROR(
      -20000,
      'BEX_BRAND already exists or conflicts with an existing object'
    );
  END IF;
END;
/

CREATE TABLE BEX_BRAND
(
  BRD_ID          NUMBER(19)
                  GENERATED ALWAYS AS IDENTITY
                  (START WITH 1 INCREMENT BY 1 CACHE 20 NOCYCLE),
  BRD_PUBLIC_ID   CHAR(32 CHAR) NOT NULL,
  BRD_NAME        VARCHAR2(200 CHAR) NOT NULL,
  BRD_SLUG        VARCHAR2(120 CHAR) NOT NULL,
  BRD_DESCRIPTION VARCHAR2(1000 CHAR),
  BRD_STATUS      VARCHAR2(20 CHAR) DEFAULT 'ACTIVE' NOT NULL,
  BRD_CREATED_AT  TIMESTAMP(6) DEFAULT SYSTIMESTAMP NOT NULL,
  BRD_CREATED_BY  NUMBER,
  BRD_UPDATED_AT  TIMESTAMP(6) DEFAULT SYSTIMESTAMP NOT NULL,
  BRD_UPDATED_BY  NUMBER,
  CONSTRAINT PK_BRAND PRIMARY KEY (BRD_ID),
  CONSTRAINT UK_BRAND_PUBLIC_ID UNIQUE (BRD_PUBLIC_ID),
  CONSTRAINT UK_BRAND_SLUG UNIQUE (BRD_SLUG),
  CONSTRAINT CK_BRAND_STATUS
    CHECK (BRD_STATUS IN ('ACTIVE','INACTIVE'))
);

COMMENT ON TABLE BEX_BRAND IS
  'Official brand reference used to classify catalog products';
COMMENT ON COLUMN BEX_BRAND.BRD_ID IS
  'Internal technical identifier generated exclusively by Oracle';
COMMENT ON COLUMN BEX_BRAND.BRD_PUBLIC_ID IS
  'Immutable public identifier assigned by the application service';
COMMENT ON COLUMN BEX_BRAND.BRD_NAME IS
  'Public display name of the brand';
COMMENT ON COLUMN BEX_BRAND.BRD_SLUG IS
  'Unique canonical segment used by brand URLs and filters';
COMMENT ON COLUMN BEX_BRAND.BRD_DESCRIPTION IS
  'Optional public description of the brand';
COMMENT ON COLUMN BEX_BRAND.BRD_STATUS IS
  'Current availability status of the brand';
COMMENT ON COLUMN BEX_BRAND.BRD_CREATED_AT IS
  'Timestamp when the brand record was created';
COMMENT ON COLUMN BEX_BRAND.BRD_CREATED_BY IS
  'Optional technical identifier of the actor that created the brand';
COMMENT ON COLUMN BEX_BRAND.BRD_UPDATED_AT IS
  'Timestamp of the last effective change to the brand record';
COMMENT ON COLUMN BEX_BRAND.BRD_UPDATED_BY IS
  'Optional technical identifier of the actor that last changed the brand';

CREATE INDEX IDX_BRAND_STATUS ON BEX_BRAND(BRD_STATUS);

DECLARE
  l_tables PLS_INTEGER;
  l_columns PLS_INTEGER;
  l_constraints PLS_INTEGER;
  l_indexes PLS_INTEGER;
BEGIN
  SELECT COUNT(*) INTO l_tables FROM USER_TABLES
   WHERE TABLE_NAME='BEX_BRAND';
  SELECT COUNT(*) INTO l_columns FROM USER_TAB_COLUMNS
   WHERE TABLE_NAME='BEX_BRAND';
  SELECT COUNT(*) INTO l_constraints FROM USER_CONSTRAINTS
   WHERE TABLE_NAME='BEX_BRAND'
     AND CONSTRAINT_NAME IN (
       'PK_BRAND','UK_BRAND_PUBLIC_ID',
       'UK_BRAND_SLUG','CK_BRAND_STATUS'
     );
  SELECT COUNT(*) INTO l_indexes FROM USER_INDEXES
   WHERE TABLE_NAME='BEX_BRAND'
     AND INDEX_NAME='IDX_BRAND_STATUS';
  IF l_tables<>1 OR l_columns<>10
     OR l_constraints<>4 OR l_indexes<>1 THEN
    RAISE_APPLICATION_ERROR(
      -20001,
      'BEX_BRAND physical structure validation failed'
    );
  END IF;
END;
/
