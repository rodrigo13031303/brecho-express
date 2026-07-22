WHENEVER SQLERROR EXIT SQL.SQLCODE;

DECLARE
    l_object_count  PLS_INTEGER;
    l_account_count PLS_INTEGER;
BEGIN
    SELECT COUNT(*)
      INTO l_object_count
      FROM USER_OBJECTS
     WHERE OBJECT_NAME = 'BEX_STORE';

    IF l_object_count > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20000,
            'BEX_STORE already exists or conflicts with an existing object'
        );
    END IF;

    SELECT COUNT(*)
      INTO l_account_count
      FROM USER_TABLES
     WHERE TABLE_NAME = 'BEX_ACCOUNT';

    IF l_account_count <> 1 THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'BEX_ACCOUNT must exist before BEX_STORE is created'
        );
    END IF;
END;
/

CREATE TABLE BEX_STORE
(
    STR_ID            NUMBER
                      GENERATED ALWAYS AS IDENTITY
                      (
                          START WITH 1
                          INCREMENT BY 1
                          CACHE 20
                          NOCYCLE
                      ),
    STR_PUBLIC_ID     CHAR(32 CHAR) NOT NULL,
    ACC_ID            NUMBER NOT NULL,
    STR_NAME          VARCHAR2(200 CHAR) NOT NULL,
    STR_SLUG          VARCHAR2(100 CHAR) NOT NULL,
    STR_DESCRIPTION   VARCHAR2(1000 CHAR),
    STR_STATUS        VARCHAR2(20 CHAR) DEFAULT 'DRAFT' NOT NULL,
    STR_LOGO_URL      VARCHAR2(1000 CHAR),
    STR_COVER_URL     VARCHAR2(1000 CHAR),
    STR_LOCALE_CODE   VARCHAR2(10 CHAR) DEFAULT 'pt-BR' NOT NULL,
    STR_TIMEZONE_NAME VARCHAR2(64 CHAR)
                      DEFAULT 'America/Sao_Paulo' NOT NULL,
    STR_CREATED_AT    TIMESTAMP(6) DEFAULT SYSTIMESTAMP NOT NULL,
    STR_CREATED_BY    NUMBER,
    STR_UPDATED_AT    TIMESTAMP(6) DEFAULT SYSTIMESTAMP NOT NULL,
    STR_UPDATED_BY    NUMBER,
    CONSTRAINT PK_STORE
        PRIMARY KEY (STR_ID),
    CONSTRAINT UK_STORE_PUBLIC_ID
        UNIQUE (STR_PUBLIC_ID),
    CONSTRAINT UK_STORE_SLUG
        UNIQUE (STR_SLUG),
    CONSTRAINT FK_STR_ACC
        FOREIGN KEY (ACC_ID)
        REFERENCES BEX_ACCOUNT (ACC_ID),
    CONSTRAINT CK_STR_STATUS
        CHECK
        (
            STR_STATUS IN
            (
                'DRAFT',
                'ACTIVE',
                'SUSPENDED',
                'CLOSED'
            )
        )
);

COMMENT ON TABLE BEX_STORE IS
    'Store or commercial sales operation structurally owned by an account';

COMMENT ON COLUMN BEX_STORE.STR_ID IS
    'Internal technical identifier generated exclusively by Oracle';

COMMENT ON COLUMN BEX_STORE.STR_PUBLIC_ID IS
    'Immutable public identifier assigned by the application service';

COMMENT ON COLUMN BEX_STORE.ACC_ID IS
    'Internal identifier of the account that structurally owns the store';

COMMENT ON COLUMN BEX_STORE.STR_NAME IS
    'Public display name of the store';

COMMENT ON COLUMN BEX_STORE.STR_SLUG IS
    'Unique canonical segment used in friendly store URLs';

COMMENT ON COLUMN BEX_STORE.STR_DESCRIPTION IS
    'Optional public presentation of the store';

COMMENT ON COLUMN BEX_STORE.STR_STATUS IS
    'Current lifecycle status of the store';

COMMENT ON COLUMN BEX_STORE.STR_LOGO_URL IS
    'Optional reference to the store logo';

COMMENT ON COLUMN BEX_STORE.STR_COVER_URL IS
    'Optional reference to the store cover image';

COMMENT ON COLUMN BEX_STORE.STR_LOCALE_CODE IS
    'Locale code used to present localized store content';

COMMENT ON COLUMN BEX_STORE.STR_TIMEZONE_NAME IS
    'IANA time-zone name used by the store';

COMMENT ON COLUMN BEX_STORE.STR_CREATED_AT IS
    'Timestamp when the store record was created';

COMMENT ON COLUMN BEX_STORE.STR_CREATED_BY IS
    'Optional technical identifier of the actor that created the store';

COMMENT ON COLUMN BEX_STORE.STR_UPDATED_AT IS
    'Timestamp of the last effective change to the store record';

COMMENT ON COLUMN BEX_STORE.STR_UPDATED_BY IS
    'Optional technical identifier of the actor that last changed the store';

CREATE INDEX IDX_STORE_ACCOUNT
    ON BEX_STORE (ACC_ID);

CREATE INDEX IDX_STORE_STATUS
    ON BEX_STORE (STR_STATUS);

DECLARE
    l_table_count      PLS_INTEGER;
    l_column_count     PLS_INTEGER;
    l_constraint_count PLS_INTEGER;
    l_index_count      PLS_INTEGER;
BEGIN
    SELECT COUNT(*)
      INTO l_table_count
      FROM USER_TABLES
     WHERE TABLE_NAME = 'BEX_STORE';

    SELECT COUNT(*)
      INTO l_column_count
      FROM USER_TAB_COLUMNS
     WHERE TABLE_NAME = 'BEX_STORE';

    SELECT COUNT(*)
      INTO l_constraint_count
      FROM USER_CONSTRAINTS
     WHERE TABLE_NAME = 'BEX_STORE'
       AND (
               (CONSTRAINT_NAME = 'PK_STORE' AND CONSTRAINT_TYPE = 'P')
            OR (CONSTRAINT_NAME = 'UK_STORE_PUBLIC_ID' AND CONSTRAINT_TYPE = 'U')
            OR (CONSTRAINT_NAME = 'UK_STORE_SLUG' AND CONSTRAINT_TYPE = 'U')
            OR (CONSTRAINT_NAME = 'FK_STR_ACC' AND CONSTRAINT_TYPE = 'R')
            OR (CONSTRAINT_NAME = 'CK_STR_STATUS' AND CONSTRAINT_TYPE = 'C')
       );

    SELECT COUNT(*)
      INTO l_index_count
      FROM USER_INDEXES
     WHERE TABLE_NAME = 'BEX_STORE'
       AND INDEX_NAME IN ('IDX_STORE_ACCOUNT', 'IDX_STORE_STATUS');

    IF l_table_count <> 1 THEN
        RAISE_APPLICATION_ERROR(-20002, 'BEX_STORE was not created');
    END IF;

    IF l_column_count <> 15 THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'BEX_STORE does not contain the 15 approved columns'
        );
    END IF;

    IF l_constraint_count <> 5 THEN
        RAISE_APPLICATION_ERROR(
            -20004,
            'BEX_STORE does not contain the approved constraints'
        );
    END IF;

    IF l_index_count <> 2 THEN
        RAISE_APPLICATION_ERROR(
            -20005,
            'BEX_STORE does not contain the approved additional indexes'
        );
    END IF;
END;
/
