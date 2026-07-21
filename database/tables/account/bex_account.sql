WHENEVER SQLERROR EXIT SQL.SQLCODE;

DECLARE
    l_object_count PLS_INTEGER;
BEGIN
    SELECT COUNT(*)
      INTO l_object_count
      FROM USER_OBJECTS
     WHERE OBJECT_NAME = 'BEX_ACCOUNT';

    IF l_object_count > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20000,
            'BEX_ACCOUNT already exists or conflicts with an existing object'
        );
    END IF;
END;
/

CREATE TABLE BEX_ACCOUNT
(
    ACC_ID                  NUMBER
                            GENERATED ALWAYS AS IDENTITY
                            (
                                START WITH 1
                                INCREMENT BY 1
                                CACHE 20
                                NOCYCLE
                            ),
    ACC_PUBLIC_ID           CHAR(32 CHAR) NOT NULL,
    ACC_EMAIL               VARCHAR2(255 CHAR) NOT NULL,
    ACC_EMAIL_VERIFIED_AT   TIMESTAMP(6),
    ACC_PASSWORD_HASH       VARCHAR2(255 CHAR) NOT NULL,
    ACC_PASSWORD_CHANGED_AT TIMESTAMP(6),
    ACC_STATUS              VARCHAR2(30 CHAR) NOT NULL,
    ACC_LAST_LOGIN_AT       TIMESTAMP(6),
    ACC_CREATED_AT          TIMESTAMP(6) DEFAULT SYSTIMESTAMP NOT NULL,
    ACC_UPDATED_AT          TIMESTAMP(6) DEFAULT SYSTIMESTAMP NOT NULL,
    ACC_CREATED_BY          NUMBER,
    ACC_UPDATED_BY          NUMBER,
    CONSTRAINT PK_ACC
        PRIMARY KEY (ACC_ID),
    CONSTRAINT UK_ACC_PUBLIC_ID
        UNIQUE (ACC_PUBLIC_ID),
    CONSTRAINT UK_ACC_EMAIL
        UNIQUE (ACC_EMAIL),
    CONSTRAINT CK_ACC_STATUS
        CHECK
        (
            ACC_STATUS IN
            (
                'PENDING_EMAIL_VERIFICATION',
                'ACTIVE',
                'BLOCKED',
                'DISABLED'
            )
        )
);

COMMENT ON TABLE BEX_ACCOUNT IS
    'Technical account identity, credentials and access state';

COMMENT ON COLUMN BEX_ACCOUNT.ACC_ID IS
    'Internal technical identifier generated exclusively by Oracle';

COMMENT ON COLUMN BEX_ACCOUNT.ACC_PUBLIC_ID IS
    'Immutable public identifier used by upper application layers';

COMMENT ON COLUMN BEX_ACCOUNT.ACC_EMAIL IS
    'Normalized unique email associated with the account';

COMMENT ON COLUMN BEX_ACCOUNT.ACC_EMAIL_VERIFIED_AT IS
    'Timestamp when the current account email was verified';

COMMENT ON COLUMN BEX_ACCOUNT.ACC_PASSWORD_HASH IS
    'Secure representation of the account password';

COMMENT ON COLUMN BEX_ACCOUNT.ACC_PASSWORD_CHANGED_AT IS
    'Timestamp when the account password was last defined or changed';

COMMENT ON COLUMN BEX_ACCOUNT.ACC_STATUS IS
    'Current lifecycle and access status of the account';

COMMENT ON COLUMN BEX_ACCOUNT.ACC_LAST_LOGIN_AT IS
    'Timestamp of the last login registered for the account';

COMMENT ON COLUMN BEX_ACCOUNT.ACC_CREATED_AT IS
    'Timestamp when the account record was created';

COMMENT ON COLUMN BEX_ACCOUNT.ACC_UPDATED_AT IS
    'Timestamp of the last effective change to the account record';

COMMENT ON COLUMN BEX_ACCOUNT.ACC_CREATED_BY IS
    'Optional technical identifier of the actor that created the record';

COMMENT ON COLUMN BEX_ACCOUNT.ACC_UPDATED_BY IS
    'Optional technical identifier of the actor that last changed the record';

DECLARE
    l_table_count      PLS_INTEGER;
    l_column_count     PLS_INTEGER;
    l_constraint_count PLS_INTEGER;
BEGIN
    SELECT COUNT(*)
      INTO l_table_count
      FROM USER_TABLES
     WHERE TABLE_NAME = 'BEX_ACCOUNT';

    SELECT COUNT(*)
      INTO l_column_count
      FROM USER_TAB_COLUMNS
     WHERE TABLE_NAME = 'BEX_ACCOUNT';

    SELECT COUNT(*)
      INTO l_constraint_count
      FROM USER_CONSTRAINTS
     WHERE TABLE_NAME = 'BEX_ACCOUNT'
       AND (
               (CONSTRAINT_NAME = 'PK_ACC' AND CONSTRAINT_TYPE = 'P')
            OR (CONSTRAINT_NAME = 'UK_ACC_PUBLIC_ID' AND CONSTRAINT_TYPE = 'U')
            OR (CONSTRAINT_NAME = 'UK_ACC_EMAIL' AND CONSTRAINT_TYPE = 'U')
            OR (CONSTRAINT_NAME = 'CK_ACC_STATUS' AND CONSTRAINT_TYPE = 'C')
       );

    IF l_table_count <> 1 THEN
        RAISE_APPLICATION_ERROR(-20001, 'BEX_ACCOUNT was not created');
    END IF;

    IF l_column_count <> 12 THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'BEX_ACCOUNT does not contain the 12 approved columns'
        );
    END IF;

    IF l_constraint_count <> 4 THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'BEX_ACCOUNT does not contain the approved constraints'
        );
    END IF;
END;
/
