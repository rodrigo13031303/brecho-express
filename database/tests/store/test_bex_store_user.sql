SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
    c_table CONSTANT VARCHAR2(30) := 'BEX_STORE_USER';
    l_count PLS_INTEGER;
    l_text VARCHAR2(4000);
    l_index_ddl CLOB;
    l_identity_type USER_TAB_IDENTITY_COLS.GENERATION_TYPE%TYPE;
    l_identity_sequence USER_TAB_IDENTITY_COLS.SEQUENCE_NAME%TYPE;
    l_account_1 BEX_ACCOUNT.ACC_ID%TYPE;
    l_account_2 BEX_ACCOUNT.ACC_ID%TYPE;
    l_account_3 BEX_ACCOUNT.ACC_ID%TYPE;
    l_store_1 BEX_STORE.STR_ID%TYPE;
    l_store_2 BEX_STORE.STR_ID%TYPE;
    l_store_user_id BEX_STORE_USER.STU_ID%TYPE;
    l_status BEX_STORE_USER.STU_STATUS%TYPE;
    l_created_at BEX_STORE_USER.STU_CREATED_AT%TYPE;
    l_updated_at BEX_STORE_USER.STU_UPDATED_AT%TYPE;

    PROCEDURE fail(p_name VARCHAR2, p_expected VARCHAR2, p_found VARCHAR2) IS
    BEGIN
        RAISE_APPLICATION_ERROR(-20900, p_name || ' | expected=' || p_expected ||
            ' | found=' || NVL(p_found, '<NULL>'));
    END;

    PROCEDURE assert_true(p_ok BOOLEAN, p_name VARCHAR2,
                          p_expected VARCHAR2, p_found VARCHAR2) IS
    BEGIN
        IF p_ok IS NULL OR NOT p_ok THEN
            fail(p_name, p_expected, p_found);
        END IF;
    END;

    PROCEDURE assert_column(p_name VARCHAR2, p_position PLS_INTEGER,
                            p_type VARCHAR2, p_length PLS_INTEGER,
                            p_scale PLS_INTEGER, p_char_used VARCHAR2,
                            p_nullable VARCHAR2) IS
        l_position PLS_INTEGER;
        l_type USER_TAB_COLUMNS.DATA_TYPE%TYPE;
        l_length USER_TAB_COLUMNS.CHAR_LENGTH%TYPE;
        l_scale USER_TAB_COLUMNS.DATA_SCALE%TYPE;
        l_char_used USER_TAB_COLUMNS.CHAR_USED%TYPE;
        l_nullable USER_TAB_COLUMNS.NULLABLE%TYPE;
    BEGIN
        SELECT COLUMN_ID, DATA_TYPE, CHAR_LENGTH, DATA_SCALE, CHAR_USED, NULLABLE
          INTO l_position, l_type, l_length, l_scale, l_char_used, l_nullable
          FROM USER_TAB_COLUMNS
         WHERE TABLE_NAME = c_table AND COLUMN_NAME = p_name;
        assert_true(l_position = p_position, p_name || ' order', TO_CHAR(p_position), TO_CHAR(l_position));
        assert_true(l_type = p_type, p_name || ' type', p_type, l_type);
        IF p_length IS NOT NULL THEN
            assert_true(l_length = p_length, p_name || ' length', TO_CHAR(p_length), TO_CHAR(l_length));
        END IF;
        IF p_scale IS NOT NULL THEN
            assert_true(l_scale = p_scale, p_name || ' scale', TO_CHAR(p_scale), TO_CHAR(l_scale));
        END IF;
        IF p_char_used IS NOT NULL THEN
            assert_true(l_char_used = p_char_used, p_name || ' semantics', p_char_used, l_char_used);
        END IF;
        assert_true(l_nullable = p_nullable, p_name || ' nullable', p_nullable, l_nullable);
    END;

    PROCEDURE assert_default(p_name VARCHAR2, p_expected VARCHAR2) IS
    BEGIN
        SELECT DATA_DEFAULT INTO l_text FROM USER_TAB_COLUMNS
         WHERE TABLE_NAME = c_table AND COLUMN_NAME = p_name;
        IF p_expected IS NULL THEN
            assert_true(
                UPPER(
                    REGEXP_REPLACE(
                        REPLACE(NVL(l_text, ''), '"', ''),
                        '[[:space:]]+',
                        ''
                    )
                ) IS NULL,
                p_name || ' default',
                '<NONE>',
                NVL(
                    UPPER(
                        REGEXP_REPLACE(
                            REPLACE(NVL(l_text, ''), '"', ''),
                            '[[:space:]]+',
                            ''
                        )
                    ),
                    '<NONE>'
                )
            );
        ELSE
            assert_true(
                UPPER(
                    REGEXP_REPLACE(
                        REPLACE(NVL(l_text, ''), '"', ''),
                        '[[:space:]]+',
                        ''
                    )
                ) =
                UPPER(
                    REGEXP_REPLACE(
                        REPLACE(NVL(p_expected, ''), '"', ''),
                        '[[:space:]]+',
                        ''
                    )
                ),
                p_name || ' default',
                UPPER(
                    REGEXP_REPLACE(
                        REPLACE(NVL(p_expected, ''), '"', ''),
                        '[[:space:]]+',
                        ''
                    )
                ),
                NVL(
                    UPPER(
                        REGEXP_REPLACE(
                            REPLACE(NVL(l_text, ''), '"', ''),
                            '[[:space:]]+',
                            ''
                        )
                    ),
                    '<NONE>'
                )
            );
        END IF;
    END;

    PROCEDURE assert_constraint(p_name VARCHAR2, p_type VARCHAR2,
                                p_column VARCHAR2, p_ref_table VARCHAR2 DEFAULT NULL,
                                p_ref_column VARCHAR2 DEFAULT NULL) IS
        l_type USER_CONSTRAINTS.CONSTRAINT_TYPE%TYPE;
        l_status USER_CONSTRAINTS.STATUS%TYPE;
        l_validated USER_CONSTRAINTS.VALIDATED%TYPE;
        l_column USER_CONS_COLUMNS.COLUMN_NAME%TYPE;
        l_ref_table USER_CONSTRAINTS.TABLE_NAME%TYPE;
        l_ref_column USER_CONS_COLUMNS.COLUMN_NAME%TYPE;
    BEGIN
        SELECT c.CONSTRAINT_TYPE, c.STATUS, c.VALIDATED, cc.COLUMN_NAME
          INTO l_type, l_status, l_validated, l_column
          FROM USER_CONSTRAINTS c JOIN USER_CONS_COLUMNS cc
            ON cc.OWNER = c.OWNER AND cc.CONSTRAINT_NAME = c.CONSTRAINT_NAME
         WHERE c.TABLE_NAME = c_table AND c.CONSTRAINT_NAME = p_name;
        assert_true(l_type = p_type, p_name || ' type', p_type, l_type);
        assert_true(l_status = 'ENABLED' AND l_validated = 'VALIDATED',
                    p_name || ' state', 'ENABLED/VALIDATED', l_status || '/' || l_validated);
        assert_true(l_column = p_column, p_name || ' column', p_column, l_column);
        IF p_ref_table IS NOT NULL THEN
            SELECT r.TABLE_NAME, rc.COLUMN_NAME
              INTO l_ref_table, l_ref_column
              FROM USER_CONSTRAINTS c JOIN USER_CONSTRAINTS r
                ON r.OWNER = c.R_OWNER AND r.CONSTRAINT_NAME = c.R_CONSTRAINT_NAME
              JOIN USER_CONS_COLUMNS rc
                ON rc.OWNER = r.OWNER AND rc.CONSTRAINT_NAME = r.CONSTRAINT_NAME
             WHERE c.TABLE_NAME = c_table AND c.CONSTRAINT_NAME = p_name;
            assert_true(l_ref_table = p_ref_table AND l_ref_column = p_ref_column,
                        p_name || ' reference', p_ref_table || '.' || p_ref_column,
                        l_ref_table || '.' || l_ref_column);
        END IF;
    END;

    PROCEDURE assert_index(p_name VARCHAR2, p_column VARCHAR2) IS
        l_column USER_IND_COLUMNS.COLUMN_NAME%TYPE;
        l_unique USER_INDEXES.UNIQUENESS%TYPE;
    BEGIN
        SELECT i.UNIQUENESS, ic.COLUMN_NAME INTO l_unique, l_column
          FROM USER_INDEXES i JOIN USER_IND_COLUMNS ic
            ON ic.INDEX_NAME = i.INDEX_NAME AND ic.TABLE_NAME = i.TABLE_NAME
         WHERE i.TABLE_NAME = c_table AND i.INDEX_NAME = p_name
           AND ic.COLUMN_POSITION = 1;
        assert_true(l_unique = 'NONUNIQUE', p_name || ' uniqueness', 'NONUNIQUE', l_unique);
        assert_true(l_column = p_column, p_name || ' column', p_column, l_column);
    END;

    PROCEDURE expect_error(p_sql VARCHAR2, p_code PLS_INTEGER, p_object VARCHAR2) IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
        fail(p_object || ' enforcement', TO_CHAR(p_code), 'statement succeeded');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE <> p_code OR INSTR(UPPER(SQLERRM), UPPER(p_object)) = 0 THEN
                fail(p_object || ' enforcement', TO_CHAR(p_code) || ' ' || p_object, SQLERRM);
            END IF;
    END;

    PROCEDURE add_link(p_public_id VARCHAR2, p_store NUMBER, p_account NUMBER,
                       p_role VARCHAR2, p_status VARCHAR2 DEFAULT NULL,
                       p_left_at TIMESTAMP DEFAULT NULL) IS
    BEGIN
        IF p_status IS NULL THEN
            INSERT INTO BEX_STORE_USER
                (STU_PUBLIC_ID, STR_ID, ACC_ID, STU_ROLE_CODE, STU_JOINED_AT, STU_LEFT_AT)
            VALUES (p_public_id, p_store, p_account, p_role, SYSTIMESTAMP, p_left_at);
        ELSE
            INSERT INTO BEX_STORE_USER
                (STU_PUBLIC_ID, STR_ID, ACC_ID, STU_ROLE_CODE, STU_STATUS,
                 STU_JOINED_AT, STU_LEFT_AT)
            VALUES (p_public_id, p_store, p_account, p_role, p_status,
                    SYSTIMESTAMP, p_left_at);
        END IF;
    END;
BEGIN
    SELECT COUNT(*) INTO l_count FROM USER_TABLES WHERE TABLE_NAME = c_table;
    assert_true(l_count = 1, 'table existence', '1', TO_CHAR(l_count));
    SELECT COUNT(*) INTO l_count FROM USER_TAB_COLUMNS WHERE TABLE_NAME = c_table;
    assert_true(l_count = 12, 'column count', '12', TO_CHAR(l_count));

    assert_column('STU_ID', 1, 'NUMBER', NULL, 0, NULL, 'N');
    assert_column('STU_PUBLIC_ID', 2, 'CHAR', 32, NULL, 'C', 'N');
    assert_column('STR_ID', 3, 'NUMBER', NULL, 0, NULL, 'N');
    assert_column('ACC_ID', 4, 'NUMBER', NULL, 0, NULL, 'N');
    assert_column('STU_ROLE_CODE', 5, 'VARCHAR2', 50, NULL, 'C', 'N');
    assert_column('STU_STATUS', 6, 'VARCHAR2', 20, NULL, 'C', 'N');
    assert_column('STU_JOINED_AT', 7, 'TIMESTAMP(6)', NULL, 6, NULL, 'N');
    assert_column('STU_LEFT_AT', 8, 'TIMESTAMP(6)', NULL, 6, NULL, 'Y');
    assert_column('STU_CREATED_AT', 9, 'TIMESTAMP(6)', NULL, 6, NULL, 'N');
    assert_column('STU_UPDATED_AT', 10, 'TIMESTAMP(6)', NULL, 6, NULL, 'N');
    assert_column('STU_CREATED_BY', 11, 'NUMBER', NULL, 0, NULL, 'Y');
    assert_column('STU_UPDATED_BY', 12, 'NUMBER', NULL, 0, NULL, 'Y');

    assert_default('STU_PUBLIC_ID', NULL);
    assert_default('STR_ID', NULL);
    assert_default('ACC_ID', NULL);
    assert_default('STU_ROLE_CODE', NULL);
    assert_default('STU_STATUS', '''ACTIVE''');
    assert_default('STU_JOINED_AT', NULL);
    assert_default('STU_LEFT_AT', NULL);
    assert_default('STU_CREATED_AT', 'SYSTIMESTAMP');
    assert_default('STU_UPDATED_AT', 'SYSTIMESTAMP');
    assert_default('STU_CREATED_BY', NULL);
    assert_default('STU_UPDATED_BY', NULL);

    SELECT GENERATION_TYPE, SEQUENCE_NAME
      INTO l_identity_type, l_identity_sequence
      FROM USER_TAB_IDENTITY_COLS
     WHERE TABLE_NAME = c_table AND COLUMN_NAME = 'STU_ID';
    assert_true(l_identity_type = 'BY DEFAULT', 'identity type', 'BY DEFAULT', l_identity_type);
    assert_true(l_identity_sequence IS NOT NULL, 'identity sequence metadata', 'Oracle-managed', l_identity_sequence);
    SELECT COUNT(*) INTO l_count FROM USER_SEQUENCES
     WHERE SEQUENCE_NAME <> l_identity_sequence
       AND (REGEXP_LIKE(SEQUENCE_NAME, '(^|_)STU($|_)') OR INSTR(SEQUENCE_NAME, c_table) > 0);
    assert_true(l_count = 0, 'manual sequence absence', '0', TO_CHAR(l_count));
    SELECT COUNT(*) INTO l_count FROM USER_TRIGGERS WHERE TABLE_NAME = c_table;
    assert_true(l_count = 0, 'trigger absence', '0', TO_CHAR(l_count));

    assert_constraint('PK_STORE_USER', 'P', 'STU_ID');
    assert_constraint('UK_STORE_USER_PUBLIC_ID', 'U', 'STU_PUBLIC_ID');
    assert_constraint('FK_STU_STORE', 'R', 'STR_ID', 'BEX_STORE', 'STR_ID');
    assert_constraint('FK_STU_ACCOUNT', 'R', 'ACC_ID', 'BEX_ACCOUNT', 'ACC_ID');
    assert_constraint('FK_STU_CREATED_BY_ACCOUNT', 'R', 'STU_CREATED_BY', 'BEX_ACCOUNT', 'ACC_ID');
    assert_constraint('FK_STU_UPDATED_BY_ACCOUNT', 'R', 'STU_UPDATED_BY', 'BEX_ACCOUNT', 'ACC_ID');
    assert_constraint('CK_STU_ROLE_CODE', 'C', 'STU_ROLE_CODE');
    assert_constraint('CK_STU_STATUS', 'C', 'STU_STATUS');

    SELECT COUNT(*) INTO l_count
      FROM USER_CONSTRAINTS c JOIN USER_CONSTRAINTS r
        ON r.OWNER = c.R_OWNER AND r.CONSTRAINT_NAME = c.R_CONSTRAINT_NAME
     WHERE c.TABLE_NAME = c_table AND c.CONSTRAINT_TYPE = 'R'
       AND r.TABLE_NAME NOT IN ('BEX_STORE', 'BEX_ACCOUNT');
    assert_true(l_count = 0, 'unapproved foreign-key dependencies', '0', TO_CHAR(l_count));

    SELECT SEARCH_CONDITION_VC INTO l_text FROM USER_CONSTRAINTS
     WHERE TABLE_NAME = c_table AND CONSTRAINT_NAME = 'CK_STU_ROLE_CODE';
    l_text := UPPER(
        REGEXP_REPLACE(
            REPLACE(NVL(l_text, ''), '"', ''),
            '[[:space:]]+',
            ''
        )
    );
    assert_true(REGEXP_COUNT(l_text, '''[^'']*''') = 4 AND
                INSTR(l_text, '''ADMIN''') > 0 AND INSTR(l_text, '''MANAGER''') > 0 AND
                INSTR(l_text, '''ATTENDANT''') > 0 AND INSTR(l_text, '''COLLABORATOR''') > 0,
                'role check domain', 'four approved values', l_text);
    SELECT SEARCH_CONDITION_VC INTO l_text FROM USER_CONSTRAINTS
     WHERE TABLE_NAME = c_table AND CONSTRAINT_NAME = 'CK_STU_STATUS';
    l_text := UPPER(
        REGEXP_REPLACE(
            REPLACE(NVL(l_text, ''), '"', ''),
            '[[:space:]]+',
            ''
        )
    );
    assert_true(REGEXP_COUNT(l_text, '''[^'']*''') = 2 AND
                INSTR(l_text, '''ACTIVE''') > 0 AND INSTR(l_text, '''INACTIVE''') > 0,
                'status check domain', 'ACTIVE/INACTIVE', l_text);

    SELECT COUNT(*) INTO l_count
      FROM (SELECT c.CONSTRAINT_NAME FROM USER_CONSTRAINTS c
             JOIN USER_CONS_COLUMNS cc ON cc.OWNER = c.OWNER
              AND cc.CONSTRAINT_NAME = c.CONSTRAINT_NAME
            WHERE c.TABLE_NAME = c_table AND c.CONSTRAINT_TYPE = 'U'
              AND cc.COLUMN_NAME IN ('STR_ID', 'ACC_ID')
            GROUP BY c.CONSTRAINT_NAME HAVING COUNT(*) = 2);
    assert_true(l_count = 0, 'conventional store/account unique absence', '0', TO_CHAR(l_count));

    SELECT COUNT(*) INTO l_count FROM USER_INDEXES
     WHERE TABLE_NAME = c_table AND INDEX_NAME = 'UK_STU_STORE_ACCOUNT_ACTIVE'
       AND UNIQUENESS = 'UNIQUE' AND INDEX_TYPE LIKE 'FUNCTION-BASED%';
    assert_true(l_count = 1, 'conditional unique index', 'unique function-based', TO_CHAR(l_count));

    l_index_ddl := DBMS_METADATA.GET_DDL(
        'INDEX',
        'UK_STU_STORE_ACCOUNT_ACTIVE',
        USER
    );
    l_text := UPPER(
        REGEXP_REPLACE(
            REPLACE(DBMS_LOB.SUBSTR(l_index_ddl, 4000, 1), '"', ''),
            '[[:space:]]+',
            ''
        )
    );
    assert_true(
        INSTR(l_text, 'CASEWHENSTU_STATUS=''ACTIVE''THENSTR_IDEND') > 0
        OR
        INSTR(l_text, 'CASESTU_STATUSWHEN''ACTIVE''THENSTR_IDEND') > 0,
        'conditional index STR_ID expression',
        'searched or simple CASE for ACTIVE returning STR_ID',
        l_text
    );
    assert_true(
        INSTR(l_text, 'CASEWHENSTU_STATUS=''ACTIVE''THENACC_IDEND') > 0
        OR
        INSTR(l_text, 'CASESTU_STATUSWHEN''ACTIVE''THENACC_IDEND') > 0,
        'conditional index ACC_ID expression',
        'searched or simple CASE for ACTIVE returning ACC_ID',
        l_text
    );
    assert_index('IDX_STORE_USER_STORE', 'STR_ID');
    assert_index('IDX_STORE_USER_ACCOUNT', 'ACC_ID');
    assert_index('IDX_STORE_USER_ROLE', 'STU_ROLE_CODE');
    assert_index('IDX_STORE_USER_STATUS', 'STU_STATUS');
    SELECT COUNT(*) INTO l_count FROM USER_INDEXES WHERE TABLE_NAME = c_table;
    assert_true(l_count = 7, 'exact index count', '7', TO_CHAR(l_count));

    SELECT COUNT(*) INTO l_count FROM USER_TAB_COMMENTS
     WHERE TABLE_NAME = c_table AND LENGTH(TRIM(COMMENTS)) > 0;
    assert_true(l_count = 1, 'table comment', '1 non-empty', TO_CHAR(l_count));
    SELECT COUNT(*) INTO l_count FROM USER_COL_COMMENTS
     WHERE TABLE_NAME = c_table AND LENGTH(TRIM(COMMENTS)) > 0;
    assert_true(l_count = 12, 'column comments', '12 non-empty', TO_CHAR(l_count));
    SELECT COUNT(*) INTO l_count
      FROM (SELECT COMMENTS FROM USER_TAB_COMMENTS WHERE TABLE_NAME = c_table
            UNION ALL
            SELECT COMMENTS FROM USER_COL_COMMENTS WHERE TABLE_NAME = c_table)
     WHERE INSTR(UPPER(COMMENTS), 'PRO' || 'FILE') > 0;
    assert_true(l_count = 0, 'forbidden identity term in comments', '0', TO_CHAR(l_count));

    INSERT INTO BEX_ACCOUNT (ACC_PUBLIC_ID, ACC_EMAIL, ACC_PASSWORD_HASH,
                             ACC_PASSWORD_CHANGED_AT, ACC_STATUS)
    VALUES (RAWTOHEX(SYS_GUID()), 'stu.1.' || LOWER(RAWTOHEX(SYS_GUID())) || '@example.invalid',
            'test-hash', SYSTIMESTAMP, 'ACTIVE') RETURNING ACC_ID INTO l_account_1;
    INSERT INTO BEX_ACCOUNT (ACC_PUBLIC_ID, ACC_EMAIL, ACC_PASSWORD_HASH,
                             ACC_PASSWORD_CHANGED_AT, ACC_STATUS)
    VALUES (RAWTOHEX(SYS_GUID()), 'stu.2.' || LOWER(RAWTOHEX(SYS_GUID())) || '@example.invalid',
            'test-hash', SYSTIMESTAMP, 'ACTIVE') RETURNING ACC_ID INTO l_account_2;
    INSERT INTO BEX_ACCOUNT (ACC_PUBLIC_ID, ACC_EMAIL, ACC_PASSWORD_HASH,
                             ACC_PASSWORD_CHANGED_AT, ACC_STATUS)
    VALUES (RAWTOHEX(SYS_GUID()), 'stu.3.' || LOWER(RAWTOHEX(SYS_GUID())) || '@example.invalid',
            'test-hash', SYSTIMESTAMP, 'ACTIVE') RETURNING ACC_ID INTO l_account_3;

    INSERT INTO BEX_STORE (STR_PUBLIC_ID, ACC_ID, STR_NAME, STR_SLUG)
    VALUES (RAWTOHEX(SYS_GUID()), l_account_1, 'STU Test Store 1',
            'stu-test-' || LOWER(SUBSTR(RAWTOHEX(SYS_GUID()), 1, 16))) RETURNING STR_ID INTO l_store_1;
    INSERT INTO BEX_STORE (STR_PUBLIC_ID, ACC_ID, STR_NAME, STR_SLUG)
    VALUES (RAWTOHEX(SYS_GUID()), l_account_1, 'STU Test Store 2',
            'stu-test-' || LOWER(SUBSTR(RAWTOHEX(SYS_GUID()), 1, 16))) RETURNING STR_ID INTO l_store_2;

    INSERT INTO BEX_STORE_USER
        (STU_PUBLIC_ID, STR_ID, ACC_ID, STU_ROLE_CODE, STU_JOINED_AT,
         STU_LEFT_AT, STU_CREATED_BY, STU_UPDATED_BY)
    VALUES (RAWTOHEX(SYS_GUID()), l_store_1, l_account_1, 'ADMIN', SYSTIMESTAMP,
            NULL, l_account_2, l_account_3)
    RETURNING STU_ID, STU_STATUS, STU_CREATED_AT, STU_UPDATED_AT
         INTO l_store_user_id, l_status, l_created_at, l_updated_at;
    assert_true(l_store_user_id IS NOT NULL, 'generated identity', 'non-null', NULL);
    assert_true(l_status = 'ACTIVE', 'ACTIVE default behavior', 'ACTIVE', l_status);
    assert_true(l_created_at IS NOT NULL AND l_updated_at IS NOT NULL,
                'timestamp defaults', 'non-null', NULL);
    SELECT COUNT(*) INTO l_count FROM BEX_STORE_USER
     WHERE STU_ID = l_store_user_id AND STU_LEFT_AT IS NULL;
    assert_true(l_count = 1, 'left timestamp accepts null', '1', TO_CHAR(l_count));

    add_link(RAWTOHEX(SYS_GUID()), l_store_1, l_account_2, 'MANAGER');
    add_link(RAWTOHEX(SYS_GUID()), l_store_2, l_account_1, 'ATTENDANT');
    assert_true(SQL%ROWCOUNT = 1, 'account/store cardinalities', 'accepted', TO_CHAR(SQL%ROWCOUNT));

    expect_error('INSERT INTO BEX_STORE_USER (STU_PUBLIC_ID,STR_ID,ACC_ID,STU_ROLE_CODE,STU_JOINED_AT) VALUES (RAWTOHEX(SYS_GUID()),' ||
                 l_store_1 || ',' || l_account_1 || ',''ADMIN'',SYSTIMESTAMP)', -1, 'UK_STU_STORE_ACCOUNT_ACTIVE');
    add_link(RAWTOHEX(SYS_GUID()), l_store_1, l_account_3, 'COLLABORATOR', 'INACTIVE');
    add_link(RAWTOHEX(SYS_GUID()), l_store_1, l_account_3, 'COLLABORATOR', 'INACTIVE', SYSTIMESTAMP);
    SELECT COUNT(*) INTO l_count FROM BEX_STORE_USER
     WHERE STR_ID = l_store_1 AND ACC_ID = l_account_3 AND STU_STATUS = 'INACTIVE';
    assert_true(l_count = 2, 'repeated inactive history', '2', TO_CHAR(l_count));
    add_link(RAWTOHEX(SYS_GUID()), l_store_1, l_account_3, 'ADMIN');
    assert_true(SQL%ROWCOUNT = 1, 'active after inactive history', 'accepted', TO_CHAR(SQL%ROWCOUNT));

    expect_error('INSERT INTO BEX_STORE_USER (STU_PUBLIC_ID,STR_ID,ACC_ID,STU_ROLE_CODE,STU_JOINED_AT) VALUES (RAWTOHEX(SYS_GUID()),-1,' || l_account_1 || ',''ADMIN'',SYSTIMESTAMP)', -2291, 'FK_STU_STORE');
    expect_error('INSERT INTO BEX_STORE_USER (STU_PUBLIC_ID,STR_ID,ACC_ID,STU_ROLE_CODE,STU_JOINED_AT) VALUES (RAWTOHEX(SYS_GUID()),' || l_store_2 || ',-1,''ADMIN'',SYSTIMESTAMP)', -2291, 'FK_STU_ACCOUNT');
    expect_error('INSERT INTO BEX_STORE_USER (STU_PUBLIC_ID,STR_ID,ACC_ID,STU_ROLE_CODE,STU_JOINED_AT,STU_CREATED_BY) VALUES (RAWTOHEX(SYS_GUID()),' || l_store_2 || ',' || l_account_2 || ',''ADMIN'',SYSTIMESTAMP,-1)', -2291, 'FK_STU_CREATED_BY_ACCOUNT');
    expect_error('INSERT INTO BEX_STORE_USER (STU_PUBLIC_ID,STR_ID,ACC_ID,STU_ROLE_CODE,STU_JOINED_AT,STU_UPDATED_BY) VALUES (RAWTOHEX(SYS_GUID()),' || l_store_2 || ',' || l_account_2 || ',''ADMIN'',SYSTIMESTAMP,-1)', -2291, 'FK_STU_UPDATED_BY_ACCOUNT');
    expect_error('INSERT INTO BEX_STORE_USER (STU_PUBLIC_ID,STR_ID,ACC_ID,STU_ROLE_CODE,STU_JOINED_AT) VALUES (RAWTOHEX(SYS_GUID()),' || l_store_2 || ',' || l_account_2 || ',''INVALID'',SYSTIMESTAMP)', -2290, 'CK_STU_ROLE_CODE');
    expect_error('INSERT INTO BEX_STORE_USER (STU_PUBLIC_ID,STR_ID,ACC_ID,STU_ROLE_CODE,STU_STATUS,STU_JOINED_AT) VALUES (RAWTOHEX(SYS_GUID()),' || l_store_2 || ',' || l_account_2 || ',''ADMIN'',''INVALID'',SYSTIMESTAMP)', -2290, 'CK_STU_STATUS');
    BEGIN
        EXECUTE IMMEDIATE
            'INSERT INTO BEX_STORE_USER (STU_PUBLIC_ID,STR_ID,ACC_ID,STU_JOINED_AT) ' ||
            'VALUES (RAWTOHEX(SYS_GUID()),:store_id,:account_id,SYSTIMESTAMP)'
            USING l_store_2, l_account_2;
        fail('role without default', 'ORA-01400', 'statement succeeded');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE <> -1400 THEN
                fail('role without default', 'ORA-01400', SQLERRM);
            END IF;
    END;

    FOR i IN 1 .. 4 LOOP
        add_link(RAWTOHEX(SYS_GUID()), l_store_2, l_account_2,
                 CASE i WHEN 1 THEN 'ADMIN' WHEN 2 THEN 'MANAGER'
                        WHEN 3 THEN 'ATTENDANT' ELSE 'COLLABORATOR' END,
                 'INACTIVE');
    END LOOP;
    SELECT COUNT(DISTINCT STU_ROLE_CODE) INTO l_count FROM BEX_STORE_USER
     WHERE STR_ID = l_store_2 AND ACC_ID = l_account_2 AND STU_STATUS = 'INACTIVE';
    assert_true(l_count = 4, 'all role values accepted', '4', TO_CHAR(l_count));
    SELECT COUNT(DISTINCT STU_STATUS) INTO l_count FROM BEX_STORE_USER
     WHERE STR_ID = l_store_1 AND ACC_ID = l_account_3;
    assert_true(l_count = 2, 'both status values accepted', '2', TO_CHAR(l_count));

    add_link('00000000000000000000000000000000', l_store_2, l_account_3, 'ADMIN', 'INACTIVE');
    expect_error('INSERT INTO BEX_STORE_USER (STU_PUBLIC_ID,STR_ID,ACC_ID,STU_ROLE_CODE,STU_STATUS,STU_JOINED_AT) VALUES (''00000000000000000000000000000000'',' || l_store_2 || ',' || l_account_3 || ',''ADMIN'',''INACTIVE'',SYSTIMESTAMP)', -1, 'UK_STORE_USER_PUBLIC_ID');

    SELECT COUNT(*) INTO l_count FROM BEX_STORE_USER
     WHERE STU_PUBLIC_ID LIKE '00000000000000000000000000000000%';
    assert_true(l_count = 1, 'public identifier integrity', '1', TO_CHAR(l_count));

    DBMS_OUTPUT.PUT_LINE('BEX_STORE_USER physical contract: PASSED');
    ROLLBACK;
    SELECT COUNT(*) INTO l_count FROM BEX_STORE_USER WHERE STU_ID = l_store_user_id;
    assert_true(l_count = 0, 'test data cleanup', '0', TO_CHAR(l_count));
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/
