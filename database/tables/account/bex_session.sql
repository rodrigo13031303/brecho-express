WHENEVER SQLERROR EXIT SQL.SQLCODE;

DECLARE
    l_object_count  PLS_INTEGER;
    l_account_count PLS_INTEGER;
BEGIN
    SELECT COUNT(*)
      INTO l_object_count
      FROM USER_OBJECTS
     WHERE OBJECT_NAME = 'BEX_SESSION';

    IF l_object_count > 0 THEN
        RAISE_APPLICATION_ERROR(
            -20000,
            'BEX_SESSION already exists or conflicts with an existing object'
        );
    END IF;

    SELECT COUNT(*)
      INTO l_account_count
      FROM USER_TABLES
     WHERE TABLE_NAME = 'BEX_ACCOUNT';

    IF l_account_count <> 1 THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'BEX_ACCOUNT must exist before BEX_SESSION is created'
        );
    END IF;
END;
/

CREATE TABLE BEX_SESSION
(
    SESSION_ID           NUMBER
                         GENERATED ALWAYS AS IDENTITY
                         (
                             START WITH 1
                             INCREMENT BY 1
                             CACHE 20
                             NOCYCLE
                         ),
    SESSION_PUBLIC_ID    VARCHAR2(32 CHAR) NOT NULL,
    ACC_ID               NUMBER NOT NULL,
    SESSION_TOKEN_HASH   VARCHAR2(128 CHAR) NOT NULL,
    SESSION_STATUS       VARCHAR2(20 CHAR) DEFAULT 'ACTIVE' NOT NULL,
    SESSION_CREATED_AT   TIMESTAMP(6) NOT NULL,
    SESSION_EXPIRES_AT   TIMESTAMP(6) NOT NULL,
    SESSION_LAST_USED_AT TIMESTAMP(6),
    SESSION_REVOKED_AT   TIMESTAMP(6),
    SESSION_CREATED_BY   NUMBER,
    SESSION_UPDATED_BY   NUMBER,
    SESSION_IP           VARCHAR2(45 CHAR),
    SESSION_USER_AGENT   VARCHAR2(1000 CHAR),
    CONSTRAINT PK_SESSION
        PRIMARY KEY (SESSION_ID),
    CONSTRAINT UK_SESSION_PUBLIC_ID
        UNIQUE (SESSION_PUBLIC_ID),
    CONSTRAINT UK_SESSION_TOKEN_HASH
        UNIQUE (SESSION_TOKEN_HASH),
    CONSTRAINT FK_SESSION_ACCOUNT
        FOREIGN KEY (ACC_ID)
        REFERENCES BEX_ACCOUNT (ACC_ID),
    CONSTRAINT CK_SESSION_STATUS
        CHECK
        (
            SESSION_STATUS IN
            (
                'ACTIVE',
                'REVOKED',
                'EXPIRED'
            )
        )
);

COMMENT ON TABLE BEX_SESSION IS
    'Authenticated account sessions, including active and historical records';

COMMENT ON COLUMN BEX_SESSION.SESSION_ID IS
    'Internal technical identifier generated exclusively by Oracle';

COMMENT ON COLUMN BEX_SESSION.SESSION_PUBLIC_ID IS
    'Unique public identifier assigned by the application service';

COMMENT ON COLUMN BEX_SESSION.ACC_ID IS
    'Internal identifier of the account that owns the session';

COMMENT ON COLUMN BEX_SESSION.SESSION_TOKEN_HASH IS
    'Unique SHA-512 hexadecimal hash of the session token';

COMMENT ON COLUMN BEX_SESSION.SESSION_STATUS IS
    'Current lifecycle status of the session';

COMMENT ON COLUMN BEX_SESSION.SESSION_CREATED_AT IS
    'Timestamp when the session was created';

COMMENT ON COLUMN BEX_SESSION.SESSION_EXPIRES_AT IS
    'Timestamp after which the session is expired';

COMMENT ON COLUMN BEX_SESSION.SESSION_LAST_USED_AT IS
    'Timestamp when the session was last used';

COMMENT ON COLUMN BEX_SESSION.SESSION_REVOKED_AT IS
    'Timestamp when the session was revoked';

COMMENT ON COLUMN BEX_SESSION.SESSION_CREATED_BY IS
    'Optional technical identifier of the actor that created the session';

COMMENT ON COLUMN BEX_SESSION.SESSION_UPDATED_BY IS
    'Optional technical identifier of the actor that last changed the session';

COMMENT ON COLUMN BEX_SESSION.SESSION_IP IS
    'Optional client IP address associated with the session';

COMMENT ON COLUMN BEX_SESSION.SESSION_USER_AGENT IS
    'Optional client user-agent associated with the session';

CREATE INDEX IDX_SESSION_ACCOUNT
    ON BEX_SESSION (ACC_ID);

CREATE INDEX IDX_SESSION_STATUS
    ON BEX_SESSION (SESSION_STATUS);

CREATE INDEX IDX_SESSION_EXPIRES_AT
    ON BEX_SESSION (SESSION_EXPIRES_AT);

DECLARE
    l_table_count      PLS_INTEGER;
    l_column_count     PLS_INTEGER;
    l_constraint_count PLS_INTEGER;
    l_index_count      PLS_INTEGER;
BEGIN
    SELECT COUNT(*)
      INTO l_table_count
      FROM USER_TABLES
     WHERE TABLE_NAME = 'BEX_SESSION';

    SELECT COUNT(*)
      INTO l_column_count
      FROM USER_TAB_COLUMNS
     WHERE TABLE_NAME = 'BEX_SESSION';

    SELECT COUNT(*)
      INTO l_constraint_count
      FROM USER_CONSTRAINTS
     WHERE TABLE_NAME = 'BEX_SESSION'
       AND (
               (CONSTRAINT_NAME = 'PK_SESSION' AND CONSTRAINT_TYPE = 'P')
            OR (CONSTRAINT_NAME = 'UK_SESSION_PUBLIC_ID' AND CONSTRAINT_TYPE = 'U')
            OR (CONSTRAINT_NAME = 'UK_SESSION_TOKEN_HASH' AND CONSTRAINT_TYPE = 'U')
            OR (CONSTRAINT_NAME = 'FK_SESSION_ACCOUNT' AND CONSTRAINT_TYPE = 'R')
            OR (CONSTRAINT_NAME = 'CK_SESSION_STATUS' AND CONSTRAINT_TYPE = 'C')
       );

    SELECT COUNT(*)
      INTO l_index_count
      FROM USER_INDEXES
     WHERE TABLE_NAME = 'BEX_SESSION'
       AND INDEX_NAME IN
           (
               'IDX_SESSION_ACCOUNT',
               'IDX_SESSION_STATUS',
               'IDX_SESSION_EXPIRES_AT'
           );

    IF l_table_count <> 1 THEN
        RAISE_APPLICATION_ERROR(-20002, 'BEX_SESSION was not created');
    END IF;

    IF l_column_count <> 13 THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'BEX_SESSION does not contain the 13 approved columns'
        );
    END IF;

    IF l_constraint_count <> 5 THEN
        RAISE_APPLICATION_ERROR(
            -20004,
            'BEX_SESSION does not contain the approved constraints'
        );
    END IF;

    IF l_index_count <> 3 THEN
        RAISE_APPLICATION_ERROR(
            -20005,
            'BEX_SESSION does not contain the approved additional indexes'
        );
    END IF;
END;
/
