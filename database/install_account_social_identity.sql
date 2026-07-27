SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF
SET ECHO ON
SET FEEDBACK ON
SET VERIFY OFF
SET LINESIZE 240
SET PAGESIZE 200
WHENEVER OSERROR EXIT FAILURE ROLLBACK
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

SPOOL account_social_identity_installation.log

PROMPT ============================================================
PROMPT BRECHO EXPRESS - INSTALL ACCOUNT SOCIAL IDENTITY
PROMPT ============================================================

@@tables/account/bex_account_identity.sql
@@tests/account/test_bex_account_identity.sql

DECLARE
  l_valid_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO l_valid_count
    FROM USER_OBJECTS
   WHERE OBJECT_NAME = 'BEX_ACCOUNT_IDENTITY'
     AND OBJECT_TYPE = 'TABLE'
     AND STATUS = 'VALID';

  IF l_valid_count <> 1 THEN
    RAISE_APPLICATION_ERROR(
      -20999,
      'BEX_ACCOUNT_IDENTITY was not installed correctly.'
    );
  END IF;

  DBMS_OUTPUT.PUT_LINE('SUCCESS - ACCOUNT SOCIAL IDENTITY INSTALLED');
  DBMS_OUTPUT.PUT_LINE('Providers: GOOGLE, APPLE, FACEBOOK');
END;
/

SPOOL OFF
EXIT SUCCESS COMMIT
