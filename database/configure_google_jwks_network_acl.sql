SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK ON
SET VERIFY OFF
SET LINESIZE 240
SET PAGESIZE 200
WHENEVER OSERROR EXIT FAILURE ROLLBACK
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

SPOOL google_jwks_network_acl_configuration.log

PROMPT ============================================================
PROMPT BRECHO EXPRESS - CONFIGURE GOOGLE JWKS NETWORK ACL
PROMPT Administrative script: run as SYS or another DBA account.
PROMPT Target schema: BRECHOEXPRESS
PROMPT Target host  : www.googleapis.com:443
PROMPT ============================================================

DECLARE
    c_principal CONSTANT VARCHAR2(128) := 'BRECHOEXPRESS';
    c_host      CONSTANT VARCHAR2(255) := 'www.googleapis.com';
    l_count     PLS_INTEGER;
BEGIN
    SELECT COUNT(*)
      INTO l_count
      FROM DBA_USERS
     WHERE USERNAME = c_principal;

    IF l_count = 0 THEN
        RAISE_APPLICATION_ERROR(
            -20001,
            'Database user ' || c_principal || ' does not exist.'
        );
    END IF;

    DBMS_NETWORK_ACL_ADMIN.append_host_ace(
        host       => c_host,
        lower_port => 443,
        upper_port => 443,
        ace        => XS$ACE_TYPE(
            privilege_list => XS$NAME_LIST('http'),
            principal_name => c_principal,
            principal_type => XS_ACL.PTYPE_DB
        )
    );

    DBMS_NETWORK_ACL_ADMIN.append_host_ace(
        host => c_host,
        ace  => XS$ACE_TYPE(
            privilege_list => XS$NAME_LIST('resolve'),
            principal_name => c_principal,
            principal_type => XS_ACL.PTYPE_DB
        )
    );

    COMMIT;

    DBMS_OUTPUT.put_line('[PASS] HTTPS access granted to ' || c_principal);
    DBMS_OUTPUT.put_line('       Host : ' || c_host);
    DBMS_OUTPUT.put_line('       Port : 443');
    DBMS_OUTPUT.put_line('       Rights: http, resolve');
END;
/

PROMPT
PROMPT Effective ACL entries:

COLUMN HOST FORMAT A35
COLUMN LOWER_PORT FORMAT 99999
COLUMN UPPER_PORT FORMAT 99999
COLUMN PRINCIPAL FORMAT A25
COLUMN PRIVILEGE FORMAT A12
COLUMN GRANT_TYPE FORMAT A10

SELECT HOST,
       LOWER_PORT,
       UPPER_PORT,
       PRINCIPAL,
       PRIVILEGE,
       GRANT_TYPE
  FROM DBA_HOST_ACES
 WHERE HOST = 'www.googleapis.com'
   AND PRINCIPAL = 'BRECHOEXPRESS'
 ORDER BY PRIVILEGE, LOWER_PORT NULLS FIRST;

SPOOL OFF

PROMPT Configuration completed.
PROMPT Log: google_jwks_network_acl_configuration.log
