SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
    c_table_name CONSTANT VARCHAR2(30) := 'BEX_SESSION';

    l_count             PLS_INTEGER;
    l_found             VARCHAR2(4000);
    l_identity_type     USER_TAB_IDENTITY_COLS.GENERATION_TYPE%TYPE;
    l_identity_options  USER_TAB_IDENTITY_COLS.IDENTITY_OPTIONS%TYPE;
    l_check_condition   USER_CONSTRAINTS.SEARCH_CONDITION_VC%TYPE;
    l_referenced_table  USER_CONSTRAINTS.TABLE_NAME%TYPE;
    l_referenced_column USER_CONS_COLUMNS.COLUMN_NAME%TYPE;

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

        assert_true(
            l_column_id = p_column_id,
            p_column_name || ' physical order',
            TO_CHAR(p_column_id),
            TO_CHAR(l_column_id)
        );
        assert_true(
            l_data_type = p_data_type,
            p_column_name || ' data type',
            p_data_type,
            l_data_type
        );

        IF p_char_length IS NOT NULL THEN
            assert_true(
                l_char_length = p_char_length,
                p_column_name || ' character length',
                TO_CHAR(p_char_length),
                TO_CHAR(l_char_length)
            );
        END IF;

        IF p_data_scale IS NOT NULL THEN
            assert_true(
                l_data_scale = p_data_scale,
                p_column_name || ' timestamp scale',
                TO_CHAR(p_data_scale),
                TO_CHAR(l_data_scale)
            );
        END IF;

        IF p_char_used IS NOT NULL THEN
            assert_true(
                l_char_used = p_char_used,
                p_column_name || ' length semantics',
                p_char_used,
                l_char_used
            );
        END IF;

        assert_true(
            l_nullable = p_nullable,
            p_column_name || ' nullability',
            p_nullable,
            l_nullable
        );
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
            assert_true(
                l_normalized IS NULL,
                p_column_name || ' default',
                '<NONE>',
                l_normalized
            );
        ELSE
            assert_true(
                l_normalized = normalize_catalog_text(p_expected_value),
                p_column_name || ' default',
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
        assert_true(l_status = 'ENABLED', p_constraint_name || ' status', 'ENABLED', l_status);
        assert_true(l_validated = 'VALIDATED', p_constraint_name || ' validation', 'VALIDATED', l_validated);

        SELECT COUNT(*), MIN(COLUMN_NAME)
          INTO l_column_count, l_column_name
          FROM USER_CONS_COLUMNS
         WHERE TABLE_NAME = c_table_name
           AND CONSTRAINT_NAME = p_constraint_name;

        assert_true(l_column_count = 1, p_constraint_name || ' column count', '1', TO_CHAR(l_column_count));
        assert_true(l_column_name = p_column_name, p_constraint_name || ' column', p_column_name, l_column_name);
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

    assert_true(l_count = 1, 'BEX_SESSION table existence', 'exactly 1', TO_CHAR(l_count));

    SELECT COUNT(*)
      INTO l_count
      FROM USER_TAB_COLUMNS
     WHERE TABLE_NAME = c_table_name;

    assert_true(l_count = 13, 'BEX_SESSION column count', '13', TO_CHAR(l_count));

    assert_column('SESSION_ID', 1, 'NUMBER', NULL, NULL, NULL, 'N');
    assert_column('SESSION_PUBLIC_ID', 2, 'VARCHAR2', 32, NULL, 'C', 'N');
    assert_column('ACC_ID', 3, 'NUMBER', NULL, NULL, NULL, 'N');
    assert_column('SESSION_TOKEN_HASH', 4, 'VARCHAR2', 128, NULL, 'C', 'N');
    assert_column('SESSION_STATUS', 5, 'VARCHAR2', 20, NULL, 'C', 'N');
    assert_column('SESSION_CREATED_AT', 6, 'TIMESTAMP(6)', NULL, 6, NULL, 'N');
    assert_column('SESSION_EXPIRES_AT', 7, 'TIMESTAMP(6)', NULL, 6, NULL, 'N');
    assert_column('SESSION_LAST_USED_AT', 8, 'TIMESTAMP(6)', NULL, 6, NULL, 'Y');
    assert_column('SESSION_REVOKED_AT', 9, 'TIMESTAMP(6)', NULL, 6, NULL, 'Y');
    assert_column('SESSION_CREATED_BY', 10, 'NUMBER', NULL, NULL, NULL, 'Y');
    assert_column('SESSION_UPDATED_BY', 11, 'NUMBER', NULL, NULL, NULL, 'Y');
    assert_column('SESSION_IP', 12, 'VARCHAR2', 45, NULL, 'C', 'Y');
    assert_column('SESSION_USER_AGENT', 13, 'VARCHAR2', 1000, NULL, 'C', 'Y');

    assert_default('SESSION_PUBLIC_ID', NULL);
    assert_default('ACC_ID', NULL);
    assert_default('SESSION_TOKEN_HASH', NULL);
    assert_default('SESSION_STATUS', '''ACTIVE''');
    assert_default('SESSION_CREATED_AT', NULL);
    assert_default('SESSION_EXPIRES_AT', NULL);
    assert_default('SESSION_LAST_USED_AT', NULL);
    assert_default('SESSION_REVOKED_AT', NULL);
    assert_default('SESSION_CREATED_BY', NULL);
    assert_default('SESSION_UPDATED_BY', NULL);
    assert_default('SESSION_IP', NULL);
    assert_default('SESSION_USER_AGENT', NULL);

    SELECT GENERATION_TYPE, IDENTITY_OPTIONS
      INTO l_identity_type, l_identity_options
      FROM USER_TAB_IDENTITY_COLS
     WHERE TABLE_NAME = c_table_name
       AND COLUMN_NAME = 'SESSION_ID';

    assert_true(l_identity_type = 'ALWAYS', 'SESSION_ID identity type', 'ALWAYS', l_identity_type);
    l_found := normalize_catalog_text(l_identity_options);
    assert_true(INSTR(l_found, 'STARTWITH:1') > 0, 'SESSION_ID identity start', '1', l_found);
    assert_true(INSTR(l_found, 'INCREMENTBY:1') > 0, 'SESSION_ID identity increment', '1', l_found);
    assert_true(INSTR(l_found, 'CACHE_SIZE:20') > 0, 'SESSION_ID identity cache', '20', l_found);
    assert_true(INSTR(l_found, 'CYCLE_FLAG:N') > 0, 'SESSION_ID identity cycle', 'N', l_found);

    assert_constraint('PK_SESSION', 'P', 'SESSION_ID');
    assert_constraint('UK_SESSION_PUBLIC_ID', 'U', 'SESSION_PUBLIC_ID');
    assert_constraint('UK_SESSION_TOKEN_HASH', 'U', 'SESSION_TOKEN_HASH');
    assert_constraint('FK_SESSION_ACCOUNT', 'R', 'ACC_ID');
    assert_constraint('CK_SESSION_STATUS', 'C', 'SESSION_STATUS');

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
       AND c.CONSTRAINT_NAME = 'FK_SESSION_ACCOUNT';

    assert_true(l_referenced_table = 'BEX_ACCOUNT', 'FK_SESSION_ACCOUNT table', 'BEX_ACCOUNT', l_referenced_table);
    assert_true(l_referenced_column = 'ACC_ID', 'FK_SESSION_ACCOUNT referenced column', 'ACC_ID', l_referenced_column);

    SELECT SEARCH_CONDITION_VC
      INTO l_check_condition
      FROM USER_CONSTRAINTS
     WHERE TABLE_NAME = c_table_name
       AND CONSTRAINT_NAME = 'CK_SESSION_STATUS';

    l_found := normalize_catalog_text(l_check_condition);
    assert_true(REGEXP_COUNT(l_found, '''[^'']*''') = 3, 'CK_SESSION_STATUS value count', '3', TO_CHAR(REGEXP_COUNT(l_found, '''[^'']*''')));
    assert_true(REGEXP_COUNT(l_found, '''ACTIVE''') = 1, 'CK_SESSION_STATUS ACTIVE', 'exactly 1', l_found);
    assert_true(REGEXP_COUNT(l_found, '''REVOKED''') = 1, 'CK_SESSION_STATUS REVOKED', 'exactly 1', l_found);
    assert_true(REGEXP_COUNT(l_found, '''EXPIRED''') = 1, 'CK_SESSION_STATUS EXPIRED', 'exactly 1', l_found);

    SELECT COUNT(*)
      INTO l_count
      FROM USER_CONSTRAINTS
     WHERE TABLE_NAME = c_table_name
       AND CONSTRAINT_NAME = 'FK_SESSION_ACCOUNT'
       AND DELETE_RULE = 'NO ACTION';

    assert_true(l_count = 1, 'FK_SESSION_ACCOUNT delete rule', 'NO ACTION', TO_CHAR(l_count));

    assert_index('UK_SESSION_PUBLIC_ID', 'SESSION_PUBLIC_ID', 'UNIQUE');
    assert_index('UK_SESSION_TOKEN_HASH', 'SESSION_TOKEN_HASH', 'UNIQUE');
    assert_index('IDX_SESSION_ACCOUNT', 'ACC_ID', 'NONUNIQUE');
    assert_index('IDX_SESSION_STATUS', 'SESSION_STATUS', 'NONUNIQUE');
    assert_index('IDX_SESSION_EXPIRES_AT', 'SESSION_EXPIRES_AT', 'NONUNIQUE');

    SELECT COUNT(*)
      INTO l_count
      FROM USER_INDEXES
     WHERE TABLE_NAME = c_table_name;

    assert_true(l_count = 6, 'BEX_SESSION index count', '6', TO_CHAR(l_count));

    SELECT COUNT(*)
      INTO l_count
      FROM USER_TAB_COMMENTS
     WHERE TABLE_NAME = c_table_name
       AND COMMENTS IS NOT NULL
       AND LENGTH(TRIM(COMMENTS)) > 0;

    assert_true(l_count = 1, 'BEX_SESSION table comment', 'non-empty', TO_CHAR(l_count));

    SELECT COUNT(*)
      INTO l_count
      FROM USER_COL_COMMENTS
     WHERE TABLE_NAME = c_table_name
       AND COMMENTS IS NOT NULL
       AND LENGTH(TRIM(COMMENTS)) > 0;

    assert_true(l_count = 13, 'BEX_SESSION column comments', '13 non-empty', TO_CHAR(l_count));

    DBMS_OUTPUT.PUT_LINE('BEX_SESSION: PASSED');
END;
/
