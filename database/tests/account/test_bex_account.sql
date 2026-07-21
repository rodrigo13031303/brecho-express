SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
    c_table_name CONSTANT VARCHAR2(30) := 'BEX_ACCOUNT';

    l_count              PLS_INTEGER;
    l_found              VARCHAR2(4000);
    l_identity_type      USER_TAB_IDENTITY_COLS.GENERATION_TYPE%TYPE;
    l_identity_options   USER_TAB_IDENTITY_COLS.IDENTITY_OPTIONS%TYPE;
    l_identity_sequence  USER_TAB_IDENTITY_COLS.SEQUENCE_NAME%TYPE;
    l_check_condition    USER_CONSTRAINTS.SEARCH_CONDITION_VC%TYPE;
    l_account_id         BEX_ACCOUNT.ACC_ID%TYPE;
    l_created_at         BEX_ACCOUNT.ACC_CREATED_AT%TYPE;
    l_updated_at         BEX_ACCOUNT.ACC_UPDATED_AT%TYPE;
    l_public_id          BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE;
    l_email              BEX_ACCOUNT.ACC_EMAIL%TYPE;
    l_password_hash      BEX_ACCOUNT.ACC_PASSWORD_HASH%TYPE;
    l_status             BEX_ACCOUNT.ACC_STATUS%TYPE;

    PROCEDURE fail(
        p_contract IN VARCHAR2,
        p_expected IN VARCHAR2,
        p_found    IN VARCHAR2
    ) IS
    BEGIN
        RAISE_APPLICATION_ERROR(
            -20900,
            p_contract || ' | expected=' || p_expected ||
            ' | found=' || NVL(p_found, '<NULL>')
        );
    END fail;

    PROCEDURE assert_true(
        p_condition IN BOOLEAN,
        p_contract  IN VARCHAR2,
        p_expected  IN VARCHAR2,
        p_found     IN VARCHAR2
    ) IS
    BEGIN
        IF p_condition IS NULL OR NOT p_condition THEN
            fail(p_contract, p_expected, p_found);
        END IF;
    END assert_true;

    FUNCTION normalize_catalog_text(
        p_value IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN UPPER(
            REGEXP_REPLACE(
                REPLACE(NVL(p_value, ''), '"', ''),
                '[[:space:]]+',
                ''
            )
        );
    END normalize_catalog_text;

    PROCEDURE assert_column(
        p_column_name IN VARCHAR2,
        p_column_id   IN PLS_INTEGER,
        p_data_type   IN VARCHAR2,
        p_char_length IN PLS_INTEGER,
        p_data_scale  IN PLS_INTEGER,
        p_char_used   IN VARCHAR2,
        p_nullable    IN VARCHAR2
    ) IS
        l_count       PLS_INTEGER;
        l_column_id   USER_TAB_COLUMNS.COLUMN_ID%TYPE;
        l_data_type   USER_TAB_COLUMNS.DATA_TYPE%TYPE;
        l_char_length USER_TAB_COLUMNS.CHAR_LENGTH%TYPE;
        l_data_scale  USER_TAB_COLUMNS.DATA_SCALE%TYPE;
        l_char_used   USER_TAB_COLUMNS.CHAR_USED%TYPE;
        l_nullable    USER_TAB_COLUMNS.NULLABLE%TYPE;
    BEGIN
        SELECT COUNT(*)
          INTO l_count
          FROM USER_TAB_COLUMNS
         WHERE TABLE_NAME = c_table_name
           AND COLUMN_NAME = p_column_name;

        assert_true(
            l_count = 1,
            'Column ' || p_column_name || ' existence',
            'exactly 1',
            TO_CHAR(l_count)
        );

        SELECT COLUMN_ID,
               DATA_TYPE,
               CHAR_LENGTH,
               DATA_SCALE,
               CHAR_USED,
               NULLABLE
          INTO l_column_id,
               l_data_type,
               l_char_length,
               l_data_scale,
               l_char_used,
               l_nullable
          FROM USER_TAB_COLUMNS
         WHERE TABLE_NAME = c_table_name
           AND COLUMN_NAME = p_column_name;

        assert_true(
            l_column_id = p_column_id,
            'Column ' || p_column_name || ' physical order',
            TO_CHAR(p_column_id),
            TO_CHAR(l_column_id)
        );

        assert_true(
            l_data_type = p_data_type,
            'Column ' || p_column_name || ' data type',
            p_data_type,
            l_data_type
        );

        IF p_char_length IS NOT NULL THEN
            assert_true(
                l_char_length = p_char_length,
                'Column ' || p_column_name || ' character length',
                TO_CHAR(p_char_length),
                TO_CHAR(l_char_length)
            );
        END IF;

        IF p_data_scale IS NOT NULL THEN
            assert_true(
                l_data_scale = p_data_scale,
                'Column ' || p_column_name || ' timestamp scale',
                TO_CHAR(p_data_scale),
                TO_CHAR(l_data_scale)
            );
        END IF;

        IF p_char_used IS NOT NULL THEN
            assert_true(
                l_char_used = p_char_used,
                'Column ' || p_column_name || ' length semantics',
                p_char_used,
                l_char_used
            );
        END IF;

        assert_true(
            l_nullable = p_nullable,
            'Column ' || p_column_name || ' nullability',
            p_nullable,
            l_nullable
        );
    END assert_column;

    PROCEDURE assert_default(
        p_column_name     IN VARCHAR2,
        p_expected_value IN VARCHAR2
    ) IS
        l_data_default VARCHAR2(4000);
        l_normalized   VARCHAR2(4000);
    BEGIN
        SELECT DATA_DEFAULT
          INTO l_data_default
          FROM USER_TAB_COLUMNS
         WHERE TABLE_NAME = c_table_name
           AND COLUMN_NAME = p_column_name;

        l_normalized := normalize_catalog_text(l_data_default);

        IF p_expected_value IS NULL THEN
            assert_true(
                l_normalized IS NULL,
                'Column ' || p_column_name || ' default',
                '<NONE>',
                l_normalized
            );
        ELSE
            assert_true(
                l_normalized = normalize_catalog_text(p_expected_value),
                'Column ' || p_column_name || ' default',
                normalize_catalog_text(p_expected_value),
                l_normalized
            );
        END IF;
    END assert_default;

    PROCEDURE assert_constraint(
        p_constraint_name IN VARCHAR2,
        p_constraint_type IN VARCHAR2,
        p_column_name     IN VARCHAR2
    ) IS
        l_count           PLS_INTEGER;
        l_type            USER_CONSTRAINTS.CONSTRAINT_TYPE%TYPE;
        l_status          USER_CONSTRAINTS.STATUS%TYPE;
        l_validated       USER_CONSTRAINTS.VALIDATED%TYPE;
        l_column_count    PLS_INTEGER;
        l_column_name     USER_CONS_COLUMNS.COLUMN_NAME%TYPE;
        l_column_position USER_CONS_COLUMNS.POSITION%TYPE;
    BEGIN
        SELECT COUNT(*)
          INTO l_count
          FROM USER_CONSTRAINTS
         WHERE TABLE_NAME = c_table_name
           AND CONSTRAINT_NAME = p_constraint_name;

        assert_true(
            l_count = 1,
            'Constraint ' || p_constraint_name || ' existence',
            'exactly 1',
            TO_CHAR(l_count)
        );

        SELECT CONSTRAINT_TYPE, STATUS, VALIDATED
          INTO l_type, l_status, l_validated
          FROM USER_CONSTRAINTS
         WHERE TABLE_NAME = c_table_name
           AND CONSTRAINT_NAME = p_constraint_name;

        assert_true(
            l_type = p_constraint_type,
            'Constraint ' || p_constraint_name || ' type',
            p_constraint_type,
            l_type
        );

        assert_true(
            l_status = 'ENABLED',
            'Constraint ' || p_constraint_name || ' status',
            'ENABLED',
            l_status
        );

        assert_true(
            l_validated = 'VALIDATED',
            'Constraint ' || p_constraint_name || ' validation',
            'VALIDATED',
            l_validated
        );

        SELECT COUNT(*), MIN(COLUMN_NAME), MIN(POSITION)
          INTO l_column_count, l_column_name, l_column_position
          FROM USER_CONS_COLUMNS
         WHERE TABLE_NAME = c_table_name
           AND CONSTRAINT_NAME = p_constraint_name;

        assert_true(
            l_column_count = 1,
            'Constraint ' || p_constraint_name || ' column count',
            '1',
            TO_CHAR(l_column_count)
        );

        IF p_constraint_type IN ('P', 'U', 'R') THEN
            assert_true(
                l_column_name = p_column_name AND l_column_position = 1,
                'Constraint ' || p_constraint_name || ' ordered columns',
                p_column_name || '@1',
                l_column_name || '@' || TO_CHAR(l_column_position)
            );
        ELSE
            assert_true(
                l_column_name = p_column_name,
                'Constraint ' || p_constraint_name || ' column',
                p_column_name,
                l_column_name
            );
        END IF;
    END assert_constraint;

    PROCEDURE expect_required_failure(
        p_case IN PLS_INTEGER
    ) IS
        l_contract VARCHAR2(100);
    BEGIN
        CASE p_case
            WHEN 1 THEN
                l_contract := 'ACC_PUBLIC_ID required';
                INSERT INTO BEX_ACCOUNT
                (
                    ACC_PUBLIC_ID,
                    ACC_EMAIL,
                    ACC_PASSWORD_HASH,
                    ACC_PASSWORD_CHANGED_AT,
                    ACC_STATUS
                )
                VALUES
                (
                    NULL,
                    'physical.null.public@example.invalid',
                    'test-hash-null-public',
                    SYSTIMESTAMP,
                    'ACTIVE'
                );
            WHEN 2 THEN
                l_contract := 'ACC_EMAIL required';
                INSERT INTO BEX_ACCOUNT
                (
                    ACC_PUBLIC_ID,
                    ACC_EMAIL,
                    ACC_PASSWORD_HASH,
                    ACC_PASSWORD_CHANGED_AT,
                    ACC_STATUS
                )
                VALUES
                (
                    'F0000000000000000000000000000010',
                    NULL,
                    'test-hash-null-email',
                    SYSTIMESTAMP,
                    'ACTIVE'
                );
            WHEN 3 THEN
                l_contract := 'ACC_PASSWORD_HASH required';
                INSERT INTO BEX_ACCOUNT
                (
                    ACC_PUBLIC_ID,
                    ACC_EMAIL,
                    ACC_PASSWORD_HASH,
                    ACC_PASSWORD_CHANGED_AT,
                    ACC_STATUS
                )
                VALUES
                (
                    'F0000000000000000000000000000011',
                    'physical.null.hash@example.invalid',
                    NULL,
                    SYSTIMESTAMP,
                    'ACTIVE'
                );
            WHEN 4 THEN
                l_contract := 'ACC_STATUS required';
                INSERT INTO BEX_ACCOUNT
                (
                    ACC_PUBLIC_ID,
                    ACC_EMAIL,
                    ACC_PASSWORD_HASH,
                    ACC_PASSWORD_CHANGED_AT,
                    ACC_STATUS
                )
                VALUES
                (
                    'F0000000000000000000000000000012',
                    'physical.null.status@example.invalid',
                    'test-hash-null-status',
                    SYSTIMESTAMP,
                    NULL
                );
            ELSE
                fail('Required-column test case', '1..4', TO_CHAR(p_case));
        END CASE;

        fail(l_contract, 'ORA-01400', 'insert succeeded');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE <> -1400 THEN
                fail(l_contract, 'ORA-01400', SQLERRM);
            END IF;
    END expect_required_failure;

BEGIN
    --------------------------------------------------------------------------
    -- Table and columns
    --------------------------------------------------------------------------
    SELECT COUNT(*)
      INTO l_count
      FROM USER_TABLES
     WHERE TABLE_NAME = c_table_name;

    assert_true(l_count = 1, 'BEX_ACCOUNT table existence', 'exactly 1', TO_CHAR(l_count));

    SELECT COUNT(*)
      INTO l_count
      FROM USER_TAB_COLUMNS
     WHERE TABLE_NAME = c_table_name;

    assert_true(l_count = 12, 'BEX_ACCOUNT column count', '12', TO_CHAR(l_count));

    assert_column('ACC_ID', 1, 'NUMBER', NULL, NULL, NULL, 'N');
    assert_column('ACC_PUBLIC_ID', 2, 'CHAR', 32, NULL, 'C', 'N');
    assert_column('ACC_EMAIL', 3, 'VARCHAR2', 255, NULL, 'C', 'N');
    assert_column('ACC_EMAIL_VERIFIED_AT', 4, 'TIMESTAMP(6)', NULL, 6, NULL, 'Y');
    assert_column('ACC_PASSWORD_HASH', 5, 'VARCHAR2', 255, NULL, 'C', 'N');
    assert_column('ACC_PASSWORD_CHANGED_AT', 6, 'TIMESTAMP(6)', NULL, 6, NULL, 'Y');
    assert_column('ACC_STATUS', 7, 'VARCHAR2', 30, NULL, 'C', 'N');
    assert_column('ACC_LAST_LOGIN_AT', 8, 'TIMESTAMP(6)', NULL, 6, NULL, 'Y');
    assert_column('ACC_CREATED_AT', 9, 'TIMESTAMP(6)', NULL, 6, NULL, 'N');
    assert_column('ACC_UPDATED_AT', 10, 'TIMESTAMP(6)', NULL, 6, NULL, 'N');
    assert_column('ACC_CREATED_BY', 11, 'NUMBER', NULL, NULL, NULL, 'Y');
    assert_column('ACC_UPDATED_BY', 12, 'NUMBER', NULL, NULL, NULL, 'Y');

    assert_default('ACC_PUBLIC_ID', NULL);
    assert_default('ACC_EMAIL', NULL);
    assert_default('ACC_EMAIL_VERIFIED_AT', NULL);
    assert_default('ACC_PASSWORD_HASH', NULL);
    assert_default('ACC_PASSWORD_CHANGED_AT', NULL);
    assert_default('ACC_STATUS', NULL);
    assert_default('ACC_LAST_LOGIN_AT', NULL);
    assert_default('ACC_CREATED_AT', 'SYSTIMESTAMP');
    assert_default('ACC_UPDATED_AT', 'SYSTIMESTAMP');
    assert_default('ACC_CREATED_BY', NULL);
    assert_default('ACC_UPDATED_BY', NULL);

    --------------------------------------------------------------------------
    -- Identity
    --------------------------------------------------------------------------
    SELECT COUNT(*)
      INTO l_count
      FROM USER_TAB_IDENTITY_COLS
     WHERE TABLE_NAME = c_table_name
       AND COLUMN_NAME = 'ACC_ID';

    assert_true(l_count = 1, 'ACC_ID identity metadata', 'exactly 1', TO_CHAR(l_count));

    SELECT GENERATION_TYPE, IDENTITY_OPTIONS, SEQUENCE_NAME
      INTO l_identity_type, l_identity_options, l_identity_sequence
      FROM USER_TAB_IDENTITY_COLS
     WHERE TABLE_NAME = c_table_name
       AND COLUMN_NAME = 'ACC_ID';

    assert_true(
        l_identity_type = 'ALWAYS',
        'ACC_ID identity generation type',
        'ALWAYS',
        l_identity_type
    );

    l_found := normalize_catalog_text(l_identity_options);

    assert_true(INSTR(l_found, 'STARTWITH:1') > 0, 'ACC_ID identity start', '1', l_found);
    assert_true(INSTR(l_found, 'INCREMENTBY:1') > 0, 'ACC_ID identity increment', '1', l_found);
    assert_true(INSTR(l_found, 'CACHE_SIZE:20') > 0, 'ACC_ID identity cache', '20', l_found);
    assert_true(INSTR(l_found, 'CYCLE_FLAG:N') > 0, 'ACC_ID identity cycle', 'N', l_found);

    --------------------------------------------------------------------------
    -- Constraints and status check
    --------------------------------------------------------------------------
    assert_constraint('PK_ACC', 'P', 'ACC_ID');
    assert_constraint('UK_ACC_PUBLIC_ID', 'U', 'ACC_PUBLIC_ID');
    assert_constraint('UK_ACC_EMAIL', 'U', 'ACC_EMAIL');
    assert_constraint('CK_ACC_STATUS', 'C', 'ACC_STATUS');

    SELECT SEARCH_CONDITION_VC
      INTO l_check_condition
      FROM USER_CONSTRAINTS
     WHERE TABLE_NAME = c_table_name
       AND CONSTRAINT_NAME = 'CK_ACC_STATUS';

    l_found := normalize_catalog_text(l_check_condition);

    assert_true(
        INSTR(l_found, 'ACC_STATUSIN(') > 0,
        'CK_ACC_STATUS expression target',
        'ACC_STATUS IN (...)',
        l_found
    );

    assert_true(
        REGEXP_COUNT(l_found, '''[^'']*''') = 4,
        'CK_ACC_STATUS value count',
        '4',
        TO_CHAR(REGEXP_COUNT(l_found, '''[^'']*'''))
    );

    assert_true(
        REGEXP_COUNT(l_found, '''PENDING_EMAIL_VERIFICATION''') = 1,
        'CK_ACC_STATUS PENDING_EMAIL_VERIFICATION',
        'exactly 1',
        l_found
    );
    assert_true(REGEXP_COUNT(l_found, '''ACTIVE''') = 1, 'CK_ACC_STATUS ACTIVE', 'exactly 1', l_found);
    assert_true(REGEXP_COUNT(l_found, '''BLOCKED''') = 1, 'CK_ACC_STATUS BLOCKED', 'exactly 1', l_found);
    assert_true(REGEXP_COUNT(l_found, '''DISABLED''') = 1, 'CK_ACC_STATUS DISABLED', 'exactly 1', l_found);

    --------------------------------------------------------------------------
    -- Indexes and auxiliary objects
    --------------------------------------------------------------------------
    SELECT COUNT(*), MIN(i.INDEX_NAME)
      INTO l_count, l_found
      FROM USER_INDEXES i
     WHERE i.TABLE_NAME = c_table_name
       AND NOT EXISTS
           (
               SELECT 1
                 FROM USER_CONSTRAINTS c
                WHERE c.TABLE_NAME = c_table_name
                  AND c.CONSTRAINT_NAME IN
                      ('PK_ACC', 'UK_ACC_PUBLIC_ID', 'UK_ACC_EMAIL')
                  AND c.INDEX_NAME = i.INDEX_NAME
           );

    assert_true(
        l_count = 0,
        'BEX_ACCOUNT additional indexes',
        '0',
        TO_CHAR(l_count) || CASE WHEN l_found IS NOT NULL THEN ':' || l_found END
    );

    SELECT COUNT(*)
      INTO l_count
      FROM USER_IND_COLUMNS ic
     WHERE ic.TABLE_NAME = c_table_name
       AND ic.COLUMN_NAME IN ('ACC_ID', 'ACC_PUBLIC_ID', 'ACC_EMAIL', 'ACC_STATUS')
       AND NOT EXISTS
           (
               SELECT 1
                 FROM USER_CONSTRAINTS c
                WHERE c.TABLE_NAME = c_table_name
                  AND c.CONSTRAINT_NAME IN
                      ('PK_ACC', 'UK_ACC_PUBLIC_ID', 'UK_ACC_EMAIL')
                  AND c.INDEX_NAME = ic.INDEX_NAME
           );

    assert_true(l_count = 0, 'BEX_ACCOUNT redundant indexed columns', '0', TO_CHAR(l_count));

    SELECT COUNT(*)
      INTO l_count
      FROM USER_TRIGGERS
     WHERE TABLE_NAME = c_table_name;

    assert_true(l_count = 0, 'BEX_ACCOUNT triggers', '0', TO_CHAR(l_count));

    SELECT COUNT(*), MIN(SEQUENCE_NAME)
      INTO l_count, l_found
      FROM USER_SEQUENCES
     WHERE SEQUENCE_NAME <> l_identity_sequence
       AND (
               REGEXP_LIKE(SEQUENCE_NAME, '(^|_)(ACC|ACCOUNT)($|_)')
            OR INSTR(SEQUENCE_NAME, 'BEX_ACCOUNT') > 0
       );

    assert_true(
        l_count = 0,
        'BEX_ACCOUNT dedicated manual sequences',
        '0',
        TO_CHAR(l_count) || CASE WHEN l_found IS NOT NULL THEN ':' || l_found END
    );

    --------------------------------------------------------------------------
    -- Comments
    --------------------------------------------------------------------------
    SELECT COUNT(*)
      INTO l_count
      FROM USER_TAB_COMMENTS
     WHERE TABLE_NAME = c_table_name
       AND COMMENTS IS NOT NULL
       AND LENGTH(TRIM(COMMENTS)) > 0;

    assert_true(l_count = 1, 'BEX_ACCOUNT table comment', 'non-empty', TO_CHAR(l_count));

    SELECT COUNT(*)
      INTO l_count
      FROM USER_COL_COMMENTS
     WHERE TABLE_NAME = c_table_name
       AND COMMENTS IS NOT NULL
       AND LENGTH(TRIM(COMMENTS)) > 0;

    assert_true(l_count = 12, 'BEX_ACCOUNT column comments', '12 non-empty', TO_CHAR(l_count));

    --------------------------------------------------------------------------
    -- Functional integrity
    --------------------------------------------------------------------------
    INSERT INTO BEX_ACCOUNT
    (
        ACC_PUBLIC_ID,
        ACC_EMAIL,
        ACC_PASSWORD_HASH,
        ACC_PASSWORD_CHANGED_AT,
        ACC_STATUS
    )
    VALUES
    (
        'F0000000000000000000000000000001',
        'physical.valid@example.invalid',
        'test-hash-valid',
        SYSTIMESTAMP,
        'PENDING_EMAIL_VERIFICATION'
    )
    RETURNING ACC_ID, ACC_CREATED_AT, ACC_UPDATED_AT
         INTO l_account_id, l_created_at, l_updated_at;

    assert_true(l_account_id IS NOT NULL, 'Valid insert identity', 'generated ACC_ID', NULL);
    assert_true(l_created_at IS NOT NULL, 'Valid insert ACC_CREATED_AT', 'non-null default', NULL);
    assert_true(l_updated_at IS NOT NULL, 'Valid insert ACC_UPDATED_AT', 'non-null default', NULL);

    SELECT ACC_PUBLIC_ID, ACC_EMAIL, ACC_PASSWORD_HASH, ACC_STATUS
      INTO l_public_id, l_email, l_password_hash, l_status
      FROM BEX_ACCOUNT
     WHERE ACC_ID = l_account_id;

    assert_true(TRIM(l_public_id) = 'F0000000000000000000000000000001', 'Valid insert public ID', 'preserved', TRIM(l_public_id));
    assert_true(l_email = 'physical.valid@example.invalid', 'Valid insert email', 'preserved', l_email);
    assert_true(l_password_hash = 'test-hash-valid', 'Valid insert password hash', 'preserved', l_password_hash);
    assert_true(l_status = 'PENDING_EMAIL_VERIFICATION', 'Valid insert status', 'preserved', l_status);

    BEGIN
        INSERT INTO BEX_ACCOUNT
        (
            ACC_ID,
            ACC_PUBLIC_ID,
            ACC_EMAIL,
            ACC_PASSWORD_HASH,
            ACC_PASSWORD_CHANGED_AT,
            ACC_STATUS
        )
        VALUES
        (
            999999,
            'F0000000000000000000000000000002',
            'physical.manual.id@example.invalid',
            'test-hash-manual-id',
            SYSTIMESTAMP,
            'ACTIVE'
        );

        fail('ACC_ID manual insertion', 'ORA-32795', 'insert succeeded');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE <> -32795 THEN
                fail('ACC_ID manual insertion', 'ORA-32795', SQLERRM);
            END IF;
    END;

    BEGIN
        INSERT INTO BEX_ACCOUNT
        (
            ACC_PUBLIC_ID,
            ACC_EMAIL,
            ACC_PASSWORD_HASH,
            ACC_PASSWORD_CHANGED_AT,
            ACC_STATUS
        )
        VALUES
        (
            'F0000000000000000000000000000001',
            'physical.duplicate.public@example.invalid',
            'test-hash-duplicate-public',
            SYSTIMESTAMP,
            'ACTIVE'
        );

        fail('UK_ACC_PUBLIC_ID enforcement', 'ORA-00001 UK_ACC_PUBLIC_ID', 'insert succeeded');
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            IF INSTR(UPPER(SQLERRM), 'UK_ACC_PUBLIC_ID') = 0 THEN
                fail('UK_ACC_PUBLIC_ID enforcement', 'UK_ACC_PUBLIC_ID', SQLERRM);
            END IF;
        WHEN OTHERS THEN
            fail('UK_ACC_PUBLIC_ID enforcement', 'ORA-00001 UK_ACC_PUBLIC_ID', SQLERRM);
    END;

    BEGIN
        INSERT INTO BEX_ACCOUNT
        (
            ACC_PUBLIC_ID,
            ACC_EMAIL,
            ACC_PASSWORD_HASH,
            ACC_PASSWORD_CHANGED_AT,
            ACC_STATUS
        )
        VALUES
        (
            'F0000000000000000000000000000003',
            'physical.valid@example.invalid',
            'test-hash-duplicate-email',
            SYSTIMESTAMP,
            'ACTIVE'
        );

        fail('UK_ACC_EMAIL enforcement', 'ORA-00001 UK_ACC_EMAIL', 'insert succeeded');
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            IF INSTR(UPPER(SQLERRM), 'UK_ACC_EMAIL') = 0 THEN
                fail('UK_ACC_EMAIL enforcement', 'UK_ACC_EMAIL', SQLERRM);
            END IF;
        WHEN OTHERS THEN
            fail('UK_ACC_EMAIL enforcement', 'ORA-00001 UK_ACC_EMAIL', SQLERRM);
    END;

    BEGIN
        INSERT INTO BEX_ACCOUNT
        (
            ACC_PUBLIC_ID,
            ACC_EMAIL,
            ACC_PASSWORD_HASH,
            ACC_PASSWORD_CHANGED_AT,
            ACC_STATUS
        )
        VALUES
        (
            'F0000000000000000000000000000004',
            'physical.invalid.status@example.invalid',
            'test-hash-invalid-status',
            SYSTIMESTAMP,
            'INVALID'
        );

        fail('CK_ACC_STATUS enforcement', 'ORA-02290 CK_ACC_STATUS', 'insert succeeded');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE <> -2290 OR INSTR(UPPER(SQLERRM), 'CK_ACC_STATUS') = 0 THEN
                fail('CK_ACC_STATUS enforcement', 'ORA-02290 CK_ACC_STATUS', SQLERRM);
            END IF;
    END;

    FOR l_case IN 1 .. 4 LOOP
        expect_required_failure(l_case);
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('BEX_ACCOUNT physical contract: PASSED');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

ROLLBACK;