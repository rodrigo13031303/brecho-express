SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF
SET ECHO ON
SET FEEDBACK ON
SET VERIFY OFF
SET LINESIZE 240
SET PAGESIZE 200
WHENEVER OSERROR EXIT FAILURE ROLLBACK
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

SPOOL google_social_auth_domain_installation.log

PROMPT ============================================================
PROMPT BRECHO EXPRESS - INSTALL GOOGLE SOCIAL AUTH DOMAIN
PROMPT Run from the database directory as BRECHOEXPRESS.
PROMPT ============================================================

PROMPT [1/8] Installing parameterized authentication configuration...
@@tables/configuration/google_oauth_configuration.sql

PROMPT [2/8] Reinstalling ACCOUNT repository...
@@packages/account/install_acc_repository_pkg.sql

PROMPT [3/8] Reinstalling ACCOUNT service...
@@packages/account/install_acc_service_pkg.sql

PROMPT [4/8] Installing identity repository...
@@packages/account/acc_identity_repository_pkg.pks
SHOW ERRORS PACKAGE ACC_IDENTITY_REPOSITORY_PKG
@@packages/account/acc_identity_repository_pkg.pkb
SHOW ERRORS PACKAGE BODY ACC_IDENTITY_REPOSITORY_PKG

PROMPT [5/8] Installing identity service...
@@packages/account/acc_identity_service_pkg.pks
SHOW ERRORS PACKAGE ACC_IDENTITY_SERVICE_PKG
@@packages/account/acc_identity_service_pkg.pkb
SHOW ERRORS PACKAGE BODY ACC_IDENTITY_SERVICE_PKG

PROMPT [6/8] Installing social authentication API...
@@packages/account/acc_social_auth_api_pkg.pks
SHOW ERRORS PACKAGE ACC_SOCIAL_AUTH_API_PKG
@@packages/account/acc_social_auth_api_pkg.pkb
SHOW ERRORS PACKAGE BODY ACC_SOCIAL_AUTH_API_PKG

DECLARE
  l_error_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO l_error_count
    FROM USER_ERRORS
   WHERE NAME IN (
     'ACC_REPOSITORY_PKG',
     'ACC_SERVICE_PKG',
     'ACC_IDENTITY_REPOSITORY_PKG',
     'ACC_IDENTITY_SERVICE_PKG',
     'ACC_SOCIAL_AUTH_API_PKG'
   );

  IF l_error_count > 0 THEN
    RAISE_APPLICATION_ERROR(
      -20999,
      'Google social authentication packages contain compilation errors.'
    );
  END IF;
END;
/

PROMPT [7/8] Recompiling consumers of the ACCOUNT service contract...
ALTER PACKAGE ACC_API_PKG COMPILE BODY;
ALTER PACKAGE ACC_AUTH_API_PKG COMPILE BODY;
ALTER PACKAGE PFL_SERVICE_PKG COMPILE BODY;
ALTER PACKAGE STR_SERVICE_PKG COMPILE BODY;
ALTER PACKAGE STU_SERVICE_PKG COMPILE BODY;

DECLARE
  l_invalid_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO l_invalid_count
    FROM USER_OBJECTS
   WHERE OBJECT_NAME IN (
     'ACC_API_PKG',
     'ACC_AUTH_API_PKG',
     'PFL_SERVICE_PKG',
     'STR_SERVICE_PKG',
     'STU_SERVICE_PKG'
   )
     AND OBJECT_TYPE = 'PACKAGE BODY'
     AND STATUS <> 'VALID';

  IF l_invalid_count > 0 THEN
    RAISE_APPLICATION_ERROR(
      -20997,
      'A consumer of ACC_SERVICE_PKG remains invalid.'
    );
  END IF;
END;
/

PROMPT [8/8] Running transactional domain tests...
@@tests/account/test_acc_identity_service_pkg.sql

DECLARE
  l_valid_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO l_valid_count
    FROM USER_OBJECTS
   WHERE OBJECT_NAME IN (
     'ACC_IDENTITY_REPOSITORY_PKG',
     'ACC_IDENTITY_SERVICE_PKG',
     'ACC_SOCIAL_AUTH_API_PKG'
   )
     AND OBJECT_TYPE IN ('PACKAGE', 'PACKAGE BODY')
     AND STATUS = 'VALID';

  IF l_valid_count <> 6 THEN
    RAISE_APPLICATION_ERROR(
      -20998,
      'Google social authentication domain is not fully valid.'
    );
  END IF;

  DBMS_OUTPUT.put_line('SUCCESS - GOOGLE SOCIAL AUTH DOMAIN INSTALLED');
  DBMS_OUTPUT.put_line('Session duration: AUTH_SESSION_DURATION_MINUTES');
  DBMS_OUTPUT.put_line('Audience: GOOGLE_OAUTH_ALLOWED_AUDIENCES');
END;
/

SPOOL OFF
EXIT SUCCESS COMMIT
