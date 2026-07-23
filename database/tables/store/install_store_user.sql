WHENEVER SQLERROR EXIT SQL.SQLCODE

SET DEFINE OFF

PROMPT ============================================================
PROMPT Installing STORE_USER structure...
PROMPT ============================================================

DECLARE
    l_account_count PLS_INTEGER;
    l_store_count   PLS_INTEGER;
BEGIN
    SELECT COUNT(*) INTO l_account_count
      FROM USER_TABLES WHERE TABLE_NAME = 'BEX_ACCOUNT';
    SELECT COUNT(*) INTO l_store_count
      FROM USER_TABLES WHERE TABLE_NAME = 'BEX_STORE';

    IF l_account_count <> 1 OR l_store_count <> 1 THEN
        RAISE_APPLICATION_ERROR(
            -20010,
            'BEX_ACCOUNT and BEX_STORE must exist before STORE_USER installation'
        );
    END IF;
END;
/

@@bex_store_user.sql

DECLARE
    l_error_count  PLS_INTEGER;
    l_table_count  PLS_INTEGER;
    l_invalid_count PLS_INTEGER;
BEGIN
    SELECT COUNT(*) INTO l_error_count
      FROM USER_ERRORS
     WHERE NAME = 'BEX_STORE_USER';

    SELECT COUNT(*) INTO l_table_count
      FROM USER_TABLES
     WHERE TABLE_NAME = 'BEX_STORE_USER';

    SELECT COUNT(*) INTO l_invalid_count
      FROM USER_OBJECTS
     WHERE OBJECT_NAME = 'BEX_STORE_USER'
       AND STATUS <> 'VALID';

    IF l_error_count <> 0 OR l_table_count <> 1 OR l_invalid_count <> 0 THEN
        RAISE_APPLICATION_ERROR(-20011, 'BEX_STORE_USER installation validation failed');
    END IF;
END;
/

PROMPT STORE_USER structure installed successfully.
