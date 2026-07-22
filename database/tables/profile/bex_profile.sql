WHENEVER SQLERROR EXIT SQL.SQLCODE;

DECLARE
    l_object_count  PLS_INTEGER;
    l_account_count PLS_INTEGER;
BEGIN
    SELECT COUNT(*)
      INTO l_object_count
      FROM USER_OBJECTS
     WHERE OBJECT_NAME = 'BEX_PROFILE';

    IF l_object_count > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20000,
            'BEX_PROFILE already exists or conflicts with an existing object'
        );
    END IF;

    SELECT COUNT(*)
      INTO l_account_count
      FROM USER_TABLES
     WHERE TABLE_NAME = 'BEX_ACCOUNT';

    IF l_account_count <> 1 THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'BEX_ACCOUNT must exist before BEX_PROFILE is created'
        );
    END IF;
END;
/

CREATE TABLE BEX_PROFILE
(
    PFL_ID            NUMBER
                      GENERATED ALWAYS AS IDENTITY
                      (
                          START WITH 1
                          INCREMENT BY 1
                          CACHE 20
                          NOCYCLE
                      ),
    ACC_ID             NUMBER NOT NULL,
    PFL_PUBLIC_ID      CHAR(32 CHAR) NOT NULL,
    PFL_DISPLAY_NAME   VARCHAR2(100 CHAR) NOT NULL,
    PFL_FULL_NAME      VARCHAR2(200 CHAR),
    PFL_BIRTH_DATE     DATE,
    PFL_BIO            VARCHAR2(500 CHAR),
    PFL_AVATAR_URL     VARCHAR2(1000 CHAR),
    PFL_LOCALE_CODE    VARCHAR2(10 CHAR) DEFAULT 'pt-BR' NOT NULL,
    PFL_TIMEZONE_NAME  VARCHAR2(64 CHAR)
                       DEFAULT 'America/Sao_Paulo' NOT NULL,
    PFL_CREATED_AT     TIMESTAMP(6) DEFAULT SYSTIMESTAMP NOT NULL,
    PFL_UPDATED_AT     TIMESTAMP(6) DEFAULT SYSTIMESTAMP NOT NULL,
    PFL_CREATED_BY     NUMBER,
    PFL_UPDATED_BY     NUMBER,
    CONSTRAINT PK_PFL
        PRIMARY KEY (PFL_ID),
    CONSTRAINT UK_PFL_PUBLIC_ID
        UNIQUE (PFL_PUBLIC_ID),
    CONSTRAINT UK_PFL_ACCOUNT
        UNIQUE (ACC_ID),
    CONSTRAINT FK_PFL_ACC
        FOREIGN KEY (ACC_ID)
        REFERENCES BEX_ACCOUNT (ACC_ID)
);

COMMENT ON TABLE BEX_PROFILE IS
    'Personal and presentation data associated with an account';

COMMENT ON COLUMN BEX_PROFILE.PFL_ID IS
    'Internal technical identifier generated exclusively by Oracle';

COMMENT ON COLUMN BEX_PROFILE.ACC_ID IS
    'Unique account identifier that owns the profile';

COMMENT ON COLUMN BEX_PROFILE.PFL_PUBLIC_ID IS
    'Immutable public identifier assigned by the application service';

COMMENT ON COLUMN BEX_PROFILE.PFL_DISPLAY_NAME IS
    'Required name displayed to other application users';

COMMENT ON COLUMN BEX_PROFILE.PFL_FULL_NAME IS
    'Optional full name of the person represented by the profile';

COMMENT ON COLUMN BEX_PROFILE.PFL_BIRTH_DATE IS
    'Optional birth date validated by the profile domain rules';

COMMENT ON COLUMN BEX_PROFILE.PFL_BIO IS
    'Optional short personal presentation';

COMMENT ON COLUMN BEX_PROFILE.PFL_AVATAR_URL IS
    'Optional reference to the profile image';

COMMENT ON COLUMN BEX_PROFILE.PFL_LOCALE_CODE IS
    'Locale code used to present localized content';

COMMENT ON COLUMN BEX_PROFILE.PFL_TIMEZONE_NAME IS
    'IANA time-zone name used by the profile';

COMMENT ON COLUMN BEX_PROFILE.PFL_CREATED_AT IS
    'Timestamp when the profile record was created';

COMMENT ON COLUMN BEX_PROFILE.PFL_UPDATED_AT IS
    'Timestamp of the last effective change to the profile record';

COMMENT ON COLUMN BEX_PROFILE.PFL_CREATED_BY IS
    'Optional technical identifier of the actor that created the profile';

COMMENT ON COLUMN BEX_PROFILE.PFL_UPDATED_BY IS
    'Optional technical identifier of the actor that last changed the profile';

DECLARE
    l_table_count      PLS_INTEGER;
    l_column_count     PLS_INTEGER;
    l_constraint_count PLS_INTEGER;
    l_index_count      PLS_INTEGER;
BEGIN
    SELECT COUNT(*)
      INTO l_table_count
      FROM USER_TABLES
     WHERE TABLE_NAME = 'BEX_PROFILE';

    SELECT COUNT(*)
      INTO l_column_count
      FROM USER_TAB_COLUMNS
     WHERE TABLE_NAME = 'BEX_PROFILE';

    SELECT COUNT(*)
      INTO l_constraint_count
      FROM USER_CONSTRAINTS
     WHERE TABLE_NAME = 'BEX_PROFILE'
       AND (
               (CONSTRAINT_NAME = 'PK_PFL' AND CONSTRAINT_TYPE = 'P')
            OR (CONSTRAINT_NAME = 'UK_PFL_PUBLIC_ID' AND CONSTRAINT_TYPE = 'U')
            OR (CONSTRAINT_NAME = 'UK_PFL_ACCOUNT' AND CONSTRAINT_TYPE = 'U')
            OR (CONSTRAINT_NAME = 'FK_PFL_ACC' AND CONSTRAINT_TYPE = 'R')
       );

    SELECT COUNT(*)
      INTO l_index_count
      FROM USER_INDEXES
     WHERE TABLE_NAME = 'BEX_PROFILE';

    IF l_table_count <> 1 THEN
        RAISE_APPLICATION_ERROR(-20002, 'BEX_PROFILE was not created');
    END IF;

    IF l_column_count <> 14 THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'BEX_PROFILE does not contain the 14 approved columns'
        );
    END IF;

    IF l_constraint_count <> 4 THEN
        RAISE_APPLICATION_ERROR(
            -20004,
            'BEX_PROFILE does not contain the approved constraints'
        );
    END IF;

    IF l_index_count <> 3 THEN
        RAISE_APPLICATION_ERROR(
            -20005,
            'BEX_PROFILE contains unexpected or missing indexes'
        );
    END IF;
END;
/
