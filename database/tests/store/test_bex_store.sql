SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
    c_table_name CONSTANT VARCHAR2(30) := 'BEX_STORE';

    l_count              PLS_INTEGER;
    l_found              VARCHAR2(4000);
    l_identity_type      USER_TAB_IDENTITY_COLS.GENERATION_TYPE%TYPE;
    l_identity_options   USER_TAB_IDENTITY_COLS.IDENTITY_OPTIONS%TYPE;
    l_identity_sequence  USER_TAB_IDENTITY_COLS.SEQUENCE_NAME%TYPE;
    l_check_condition    USER_CONSTRAINTS.SEARCH_CONDITION_VC%TYPE;
    l_referenced_table   USER_CONSTRAINTS.TABLE_NAME%TYPE;
    l_referenced_column  USER_CONS_COLUMNS.COLUMN_NAME%TYPE;
    l_account_id         BEX_ACCOUNT.ACC_ID%TYPE;
    l_account_public_id  BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE;
    l_account_email      BEX_ACCOUNT.ACC_EMAIL%TYPE;
    l_store_id           BEX_STORE.STR_ID%TYPE;
    l_store_public_id_1  BEX_STORE.STR_PUBLIC_ID%TYPE;
    l_store_public_id_2  BEX_STORE.STR_PUBLIC_ID%TYPE;
    l_store_slug_1       BEX_STORE.STR_SLUG%TYPE;
    l_store_slug_2       BEX_STORE.STR_SLUG%TYPE;
    l_run_token          VARCHAR2(16);
    l_status             BEX_STORE.STR_STATUS%TYPE;
    l_locale_code        BEX_STORE.STR_LOCALE_CODE%TYPE;
    l_timezone_name      BEX_STORE.STR_TIMEZONE_NAME%TYPE;
    l_created_at         BEX_STORE.STR_CREATED_AT%TYPE;
    l_updated_at         BEX_STORE.STR_UPDATED_AT%TYPE;

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
        l_column_id   USER_TAB_COLUMNS.COLUMN_ID%TYPE;
        l_data_type   USER_TAB_COLUMNS.DATA_TYPE%TYPE;
        l_char_length USER_TAB_COLUMNS.CHAR_LENGTH%TYPE;
        l_data_scale  USER_TAB_COLUMNS.DATA_SCALE%TYPE;
        l_char_used   USER_TAB_COLUMNS.CHAR_USED%TYPE;
        l_nullable    USER_TAB_COLUMNS.NULLABLE%TYPE;
    BEGIN
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

        assert_true(l_column_id = p_column_id, p_column_name || ' physical order', TO_CHAR(p_column_id), TO_CHAR(l_column_id));
        assert_true(l_data_type = p_data_type, p_column_name || ' data type', p_data_type, l_data_type);

        IF p_char_length IS NOT NULL THEN
            assert_true(l_char_length = p_char_length, p_column_name || ' character length', TO_CHAR(p_char_length), TO_CHAR(l_char_length));
        END IF;

        IF p_data_scale IS NOT NULL THEN
            assert_true(l_data_scale = p_data_scale, p_column_name || ' timestamp scale', TO_CHAR(p_data_scale), TO_CHAR(l_data_scale));
        END IF;

        IF p_char_used IS NOT NULL THEN
            assert_true(l_char_used = p_char_used, p_column_name || ' length semantics', p_char_used, l_char_used);
        END IF;

        assert_true(l_nullable = p_nullable, p_column_name || ' nullability', p_nullable, l_nullable);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            fail(p_column_name || ' existence', 'exactly 1', '0');
    END assert_column;

    PROCEDURE assert_default(
        p_column_name    IN VARCHAR2,
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
            assert_true(l_normalized IS NULL, p_column_name || ' default', '<NONE>', l_normalized);
        ELSE
            assert_true(l_normalized = normalize_catalog_text(p_expected_value), p_column_name || ' default', normalize_catalog_text(p_expected_value), l_normalized);
        END IF;
    END assert_default;

    PROCEDURE assert_constraint(
        p_constraint_name IN VARCHAR2,
        p_constraint_type IN VARCHAR2,
        p_column_name     IN VARCHAR2
    ) IS
        l_type         USER_CONSTRAINTS.CONSTRAINT_TYPE%TYPE;
        l_status       USER_CONSTRAINTS.STATUS%TYPE;
        l_validated    USER_CONSTRAINTS.VALIDATED%TYPE;
        l_column_count PLS_INTEGER;
        l_column_name  USER_CONS_COLUMNS.COLUMN_NAME%TYPE;
    BEGIN
        SELECT CONSTRAINT_TYPE, STATUS, VALIDATED
          INTO l_type, l_status, l_validated
          FROM USER_CONSTRAINTS
         WHERE TABLE_NAME = c_table_name
           AND CONSTRAINT_NAME = p_constraint_name;

        assert_true(l_type = p_constraint_type, p_constraint_name || ' type', p_constraint_type, l_type);
        assert_true(l_status = 'ENABLED' AND l_validated = 'VALIDATED', p_constraint_name || ' state', 'ENABLED/VALIDATED', l_status || '/' || l_validated);

        SELECT COUNT(*), MIN(COLUMN_NAME)
          INTO l_column_count, l_column_name
          FROM USER_CONS_COLUMNS
         WHERE TABLE_NAME = c_table_name
           AND CONSTRAINT_NAME = p_constraint_name;

        assert_true(l_column_count = 1 AND l_column_name = p_column_name, p_constraint_name || ' column', p_column_name, l_column_name);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            fail(p_constraint_name || ' existence', 'exactly 1', '0');
    END assert_constraint;

    PROCEDURE assert_index(
        p_index_name  IN VARCHAR2,
        p_column_name IN VARCHAR2,
        p_uniqueness  IN VARCHAR2
    ) IS
        l_uniqueness USER_INDEXES.UNIQUENESS%TYPE;
        l_column     USER_IND_COLUMNS.COLUMN_NAME%TYPE;
        l_position   USER_IND_COLUMNS.COLUMN_POSITION%TYPE;
    BEGIN
        SELECT i.UNIQUENESS, c.COLUMN_NAME, c.COLUMN_POSITION
          INTO l_uniqueness, l_column, l_position
          FROM USER_INDEXES i
          JOIN USER_IND_COLUMNS c
            ON c.INDEX_NAME = i.INDEX_NAME
           AND c.TABLE_NAME = i.TABLE_NAME
         WHERE i.TABLE_NAME = c_table_name
           AND i.INDEX_NAME = p_index_name;

        assert_true(l_uniqueness = p_uniqueness, p_index_name || ' uniqueness', p_uniqueness, l_uniqueness);
        assert_true(l_column = p_column_name AND l_position = 1, p_index_name || ' column', p_column_name || '@1', l_column || '@' || TO_CHAR(l_position));
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            fail(p_index_name || ' existence', 'exactly 1', '0');
    END assert_index;

BEGIN
    SELECT COUNT(*)
      INTO l_count
      FROM USER_TABLES
     WHERE TABLE_NAME = c_table_name;

    assert_true(l_count = 1, 'BEX_STORE table existence', 'exactly 1', TO_CHAR(l_count));

    SELECT COUNT(*)
      INTO l_count
      FROM USER_TAB_COLUMNS
     WHERE TABLE_NAME = c_table_name;

    assert_true(l_count = 15, 'BEX_STORE column count', '15', TO_CHAR(l_count));

    assert_column('STR_ID', 1, 'NUMBER', NULL, NULL, NULL, 'N');
    assert_column('STR_PUBLIC_ID', 2, 'CHAR', 32, NULL, 'C', 'N');
    assert_column('ACC_ID', 3, 'NUMBER', NULL, NULL, NULL, 'N');
    assert_column('STR_NAME', 4, 'VARCHAR2', 200, NULL, 'C', 'N');
    assert_column('STR_SLUG', 5, 'VARCHAR2', 100, NULL, 'C', 'N');
    assert_column('STR_DESCRIPTION', 6, 'VARCHAR2', 1000, NULL, 'C', 'Y');
    assert_column('STR_STATUS', 7, 'VARCHAR2', 20, NULL, 'C', 'N');
    assert_column('STR_LOGO_URL', 8, 'VARCHAR2', 1000, NULL, 'C', 'Y');
    assert_column('STR_COVER_URL', 9, 'VARCHAR2', 1000, NULL, 'C', 'Y');
    assert_column('STR_LOCALE_CODE', 10, 'VARCHAR2', 10, NULL, 'C', 'N');
    assert_column('STR_TIMEZONE_NAME', 11, 'VARCHAR2', 64, NULL, 'C', 'N');
    assert_column('STR_CREATED_AT', 12, 'TIMESTAMP(6)', NULL, 6, NULL, 'N');
    assert_column('STR_CREATED_BY', 13, 'NUMBER', NULL, NULL, NULL, 'Y');
    assert_column('STR_UPDATED_AT', 14, 'TIMESTAMP(6)', NULL, 6, NULL, 'N');
    assert_column('STR_UPDATED_BY', 15, 'NUMBER', NULL, NULL, NULL, 'Y');

    SELECT COUNT(*)
      INTO l_count
      FROM USER_TAB_COLUMNS
     WHERE TABLE_NAME = c_table_name
       AND COLUMN_NAME = 'PFL_ID';

    assert_true(l_count = 0, 'BEX_STORE PFL_ID absence', '0', TO_CHAR(l_count));

    assert_default('STR_PUBLIC_ID', NULL);
    assert_default('ACC_ID', NULL);
    assert_default('STR_NAME', NULL);
    assert_default('STR_SLUG', NULL);
    assert_default('STR_DESCRIPTION', NULL);
    assert_default('STR_STATUS', '''DRAFT''');
    assert_default('STR_LOGO_URL', NULL);
    assert_default('STR_COVER_URL', NULL);
    assert_default('STR_LOCALE_CODE', '''pt-BR''');
    assert_default('STR_TIMEZONE_NAME', '''America/Sao_Paulo''');
    assert_default('STR_CREATED_AT', 'SYSTIMESTAMP');
    assert_default('STR_CREATED_BY', NULL);
    assert_default('STR_UPDATED_AT', 'SYSTIMESTAMP');
    assert_default('STR_UPDATED_BY', NULL);

    SELECT GENERATION_TYPE, IDENTITY_OPTIONS, SEQUENCE_NAME
      INTO l_identity_type, l_identity_options, l_identity_sequence
      FROM USER_TAB_IDENTITY_COLS
     WHERE TABLE_NAME = c_table_name
       AND COLUMN_NAME = 'STR_ID';

    assert_true(l_identity_type = 'ALWAYS', 'STR_ID identity type', 'ALWAYS', l_identity_type);
    l_found := normalize_catalog_text(l_identity_options);
    assert_true(INSTR(l_found, 'STARTWITH:1') > 0, 'STR_ID identity start', '1', l_found);
    assert_true(INSTR(l_found, 'INCREMENTBY:1') > 0, 'STR_ID identity increment', '1', l_found);
    assert_true(INSTR(l_found, 'CACHE_SIZE:20') > 0, 'STR_ID identity cache', '20', l_found);
    assert_true(INSTR(l_found, 'CYCLE_FLAG:N') > 0, 'STR_ID identity cycle', 'N', l_found);
    assert_true(l_identity_sequence IS NOT NULL, 'STR_ID identity sequence', 'non-null Oracle-managed name', l_identity_sequence);

    assert_constraint('PK_STORE', 'P', 'STR_ID');
    assert_constraint('UK_STORE_PUBLIC_ID', 'U', 'STR_PUBLIC_ID');
    assert_constraint('UK_STORE_SLUG', 'U', 'STR_SLUG');
    assert_constraint('FK_STR_ACC', 'R', 'ACC_ID');
    assert_constraint('CK_STR_STATUS', 'C', 'STR_STATUS');

    SELECT r.TABLE_NAME, rc.COLUMN_NAME
      INTO l_referenced_table, l_referenced_column
      FROM USER_CONSTRAINTS c
      JOIN USER_CONSTRAINTS r
        ON r.CONSTRAINT_NAME = c.R_CONSTRAINT_NAME
       AND r.OWNER = c.R_OWNER
      JOIN USER_CONS_COLUMNS rc
        ON rc.CONSTRAINT_NAME = r.CONSTRAINT_NAME
       AND rc.OWNER = r.OWNER
     WHERE c.TABLE_NAME = c_table_name
       AND c.CONSTRAINT_NAME = 'FK_STR_ACC';

    assert_true(l_referenced_table = 'BEX_ACCOUNT', 'FK_STR_ACC table', 'BEX_ACCOUNT', l_referenced_table);
    assert_true(l_referenced_column = 'ACC_ID', 'FK_STR_ACC column', 'ACC_ID', l_referenced_column);

    SELECT COUNT(*)
      INTO l_count
      FROM USER_CONSTRAINTS
     WHERE TABLE_NAME = c_table_name
       AND CONSTRAINT_NAME = 'FK_STR_ACC'
       AND DELETE_RULE = 'NO ACTION';

    assert_true(l_count = 1, 'FK_STR_ACC delete rule', 'NO ACTION', TO_CHAR(l_count));

    SELECT SEARCH_CONDITION_VC
      INTO l_check_condition
      FROM USER_CONSTRAINTS
     WHERE TABLE_NAME = c_table_name
       AND CONSTRAINT_NAME = 'CK_STR_STATUS';

    l_found := normalize_catalog_text(l_check_condition);
    assert_true(REGEXP_COUNT(l_found, '''[^'']*''') = 4, 'CK_STR_STATUS value count', '4', TO_CHAR(REGEXP_COUNT(l_found, '''[^'']*''')));
    assert_true(REGEXP_COUNT(l_found, '''DRAFT''') = 1, 'CK_STR_STATUS DRAFT', 'exactly 1', l_found);
    assert_true(REGEXP_COUNT(l_found, '''ACTIVE''') = 1, 'CK_STR_STATUS ACTIVE', 'exactly 1', l_found);
    assert_true(REGEXP_COUNT(l_found, '''SUSPENDED''') = 1, 'CK_STR_STATUS SUSPENDED', 'exactly 1', l_found);
    assert_true(REGEXP_COUNT(l_found, '''CLOSED''') = 1, 'CK_STR_STATUS CLOSED', 'exactly 1', l_found);

    SELECT COUNT(*)
      INTO l_count
      FROM USER_CONSTRAINTS c
      JOIN USER_CONS_COLUMNS cc
        ON cc.CONSTRAINT_NAME = c.CONSTRAINT_NAME
       AND cc.OWNER = c.OWNER
     WHERE c.TABLE_NAME = c_table_name
       AND c.CONSTRAINT_TYPE = 'U'
       AND cc.COLUMN_NAME = 'ACC_ID';

    assert_true(l_count = 0, 'ACC_ID unique constraint absence', '0', TO_CHAR(l_count));

    SELECT COUNT(*)
      INTO l_count
      FROM USER_CONSTRAINTS c
      JOIN USER_CONSTRAINTS r
        ON r.CONSTRAINT_NAME = c.R_CONSTRAINT_NAME
       AND r.OWNER = c.R_OWNER
     WHERE c.TABLE_NAME = c_table_name
       AND c.CONSTRAINT_TYPE = 'R'
       AND r.TABLE_NAME = 'BEX_PROFILE';

    assert_true(l_count = 0, 'BEX_STORE PROFILE foreign keys', '0', TO_CHAR(l_count));

    assert_index('PK_STORE', 'STR_ID', 'UNIQUE');
    assert_index('UK_STORE_PUBLIC_ID', 'STR_PUBLIC_ID', 'UNIQUE');
    assert_index('UK_STORE_SLUG', 'STR_SLUG', 'UNIQUE');
    assert_index('IDX_STORE_ACCOUNT', 'ACC_ID', 'NONUNIQUE');
    assert_index('IDX_STORE_STATUS', 'STR_STATUS', 'NONUNIQUE');

    SELECT COUNT(*)
      INTO l_count
      FROM (
               SELECT i.INDEX_NAME
                 FROM USER_INDEXES i
                 JOIN USER_IND_COLUMNS ic
                   ON ic.INDEX_NAME = i.INDEX_NAME
                  AND ic.TABLE_NAME = i.TABLE_NAME
                WHERE i.TABLE_NAME = c_table_name
                  AND i.UNIQUENESS = 'UNIQUE'
                GROUP BY i.INDEX_NAME
               HAVING COUNT(*) = 1
                  AND MIN(ic.COLUMN_NAME) = 'ACC_ID'
           );

    assert_true(l_count = 0, 'ACC_ID exclusive unique index absence', '0', TO_CHAR(l_count));

    SELECT COUNT(*)
      INTO l_count
      FROM USER_TRIGGERS
     WHERE TABLE_NAME = c_table_name;

    assert_true(l_count = 0, 'BEX_STORE triggers', '0', TO_CHAR(l_count));

    SELECT COUNT(*)
      INTO l_count
      FROM USER_TAB_COMMENTS
     WHERE TABLE_NAME = c_table_name
       AND COMMENTS IS NOT NULL
       AND LENGTH(TRIM(COMMENTS)) > 0;

    assert_true(l_count = 1, 'BEX_STORE table comment', '1', TO_CHAR(l_count));

    SELECT COUNT(*)
      INTO l_count
      FROM USER_COL_COMMENTS
     WHERE TABLE_NAME = c_table_name
       AND COMMENTS IS NOT NULL
       AND LENGTH(TRIM(COMMENTS)) > 0;

    assert_true(l_count = 15, 'BEX_STORE column comments', '15', TO_CHAR(l_count));

    l_run_token := LOWER(SUBSTR(RAWTOHEX(SYS_GUID()), 1, 16));
    l_account_public_id := RAWTOHEX(SYS_GUID());
    l_account_email :=
        'store.physical.' ||
        LOWER(RAWTOHEX(SYS_GUID())) ||
        '@example.invalid';
    l_store_public_id_1 := RAWTOHEX(SYS_GUID());
    l_store_public_id_2 := RAWTOHEX(SYS_GUID());
    l_store_slug_1 := 'physical-store-one-' || l_run_token;
    l_store_slug_2 := 'physical-store-two-' || l_run_token;

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
        l_account_public_id,
        l_account_email,
        'test-hash-store-owner',
        SYSTIMESTAMP,
        'ACTIVE'
    )
    RETURNING ACC_ID INTO l_account_id;

    SELECT COUNT(*)
      INTO l_count
      FROM USER_TABLES
     WHERE TABLE_NAME = 'BEX_PROFILE';

    IF l_count = 1 THEN
        EXECUTE IMMEDIATE
            'SELECT COUNT(*) FROM BEX_PROFILE WHERE ACC_ID = :account_id'
            INTO l_count
            USING l_account_id;
    ELSE
        l_count := 0;
    END IF;

    assert_true(l_count = 0, 'Test ACCOUNT has no PROFILE', '0', TO_CHAR(l_count));

    INSERT INTO BEX_STORE
    (
        STR_PUBLIC_ID,
        ACC_ID,
        STR_NAME,
        STR_SLUG,
        STR_DESCRIPTION,
        STR_LOGO_URL,
        STR_COVER_URL,
        STR_CREATED_BY,
        STR_UPDATED_BY
    )
    VALUES
    (
        l_store_public_id_1,
        l_account_id,
        'Physical Store One',
        l_store_slug_1,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL
    )
    RETURNING STR_ID,
              STR_STATUS,
              STR_LOCALE_CODE,
              STR_TIMEZONE_NAME,
              STR_CREATED_AT,
              STR_UPDATED_AT
         INTO l_store_id,
              l_status,
              l_locale_code,
              l_timezone_name,
              l_created_at,
              l_updated_at;

    assert_true(l_store_id IS NOT NULL, 'Valid STORE identity', 'generated STR_ID', NULL);
    assert_true(l_status = 'DRAFT', 'STR_STATUS default behavior', 'DRAFT', l_status);
    assert_true(l_locale_code = 'pt-BR', 'STR_LOCALE_CODE default behavior', 'pt-BR', l_locale_code);
    assert_true(l_timezone_name = 'America/Sao_Paulo', 'STR_TIMEZONE_NAME default behavior', 'America/Sao_Paulo', l_timezone_name);
    assert_true(l_created_at IS NOT NULL, 'STR_CREATED_AT default behavior', 'non-null', NULL);
    assert_true(l_updated_at IS NOT NULL, 'STR_UPDATED_AT default behavior', 'non-null', NULL);

    INSERT INTO BEX_STORE
    (
        STR_PUBLIC_ID,
        ACC_ID,
        STR_NAME,
        STR_SLUG
    )
    VALUES
    (
        l_store_public_id_2,
        l_account_id,
        'Physical Store Two',
        l_store_slug_2
    );

    SELECT COUNT(*)
      INTO l_count
      FROM BEX_STORE
     WHERE ACC_ID = l_account_id;

    assert_true(l_count = 2, 'Multiple STORE per ACCOUNT', '2', TO_CHAR(l_count));

    BEGIN
        INSERT INTO BEX_STORE (STR_PUBLIC_ID, ACC_ID, STR_NAME, STR_SLUG)
        VALUES (l_store_public_id_1, l_account_id, 'Duplicate Public ID', 'duplicate-public-' || l_run_token);
        fail('UK_STORE_PUBLIC_ID enforcement', 'ORA-00001 UK_STORE_PUBLIC_ID', 'insert succeeded');
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            IF INSTR(UPPER(SQLERRM), 'UK_STORE_PUBLIC_ID') = 0 THEN
                fail('UK_STORE_PUBLIC_ID enforcement', 'UK_STORE_PUBLIC_ID', SQLERRM);
            END IF;
        WHEN OTHERS THEN
            fail('UK_STORE_PUBLIC_ID enforcement', 'ORA-00001 UK_STORE_PUBLIC_ID', SQLERRM);
    END;

    BEGIN
        INSERT INTO BEX_STORE (STR_PUBLIC_ID, ACC_ID, STR_NAME, STR_SLUG)
        VALUES (RAWTOHEX(SYS_GUID()), l_account_id, 'Duplicate Slug', l_store_slug_1);
        fail('UK_STORE_SLUG enforcement', 'ORA-00001 UK_STORE_SLUG', 'insert succeeded');
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            IF INSTR(UPPER(SQLERRM), 'UK_STORE_SLUG') = 0 THEN
                fail('UK_STORE_SLUG enforcement', 'UK_STORE_SLUG', SQLERRM);
            END IF;
        WHEN OTHERS THEN
            fail('UK_STORE_SLUG enforcement', 'ORA-00001 UK_STORE_SLUG', SQLERRM);
    END;

    BEGIN
        INSERT INTO BEX_STORE (STR_PUBLIC_ID, ACC_ID, STR_NAME, STR_SLUG, STR_STATUS)
        VALUES (RAWTOHEX(SYS_GUID()), l_account_id, 'Invalid Status', 'invalid-status-' || l_run_token, 'INVALID');
        fail('CK_STR_STATUS enforcement', 'ORA-02290 CK_STR_STATUS', 'insert succeeded');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE <> -2290 OR INSTR(UPPER(SQLERRM), 'CK_STR_STATUS') = 0 THEN
                fail('CK_STR_STATUS enforcement', 'ORA-02290 CK_STR_STATUS', SQLERRM);
            END IF;
    END;

    BEGIN
        INSERT INTO BEX_STORE (STR_PUBLIC_ID, ACC_ID, STR_NAME, STR_SLUG)
        VALUES (RAWTOHEX(SYS_GUID()), -1, 'Missing Account', 'missing-account-' || l_run_token);
        fail('FK_STR_ACC enforcement', 'ORA-02291 FK_STR_ACC', 'insert succeeded');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE <> -2291 OR INSTR(UPPER(SQLERRM), 'FK_STR_ACC') = 0 THEN
                fail('FK_STR_ACC enforcement', 'ORA-02291 FK_STR_ACC', SQLERRM);
            END IF;
    END;

    BEGIN
        INSERT INTO BEX_STORE (STR_PUBLIC_ID, ACC_ID, STR_NAME, STR_SLUG)
        VALUES (RAWTOHEX(SYS_GUID()), NULL, 'Null Account', 'null-account-' || l_run_token);
        fail('ACC_ID required', 'ORA-01400', 'insert succeeded');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE <> -1400 THEN
                fail('ACC_ID required', 'ORA-01400', SQLERRM);
            END IF;
    END;

    BEGIN
        DELETE FROM BEX_ACCOUNT
         WHERE ACC_ID = l_account_id;
        fail('Referenced ACCOUNT deletion', 'ORA-02292 FK_STR_ACC', 'delete succeeded');
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE <> -2292 OR INSTR(UPPER(SQLERRM), 'FK_STR_ACC') = 0 THEN
                fail('Referenced ACCOUNT deletion', 'ORA-02292 FK_STR_ACC', SQLERRM);
            END IF;
    END;

    DBMS_OUTPUT.PUT_LINE('BEX_STORE physical contract: PASSED');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/

ROLLBACK;
