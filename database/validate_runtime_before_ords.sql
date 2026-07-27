SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF
SET ECHO ON
SET FEEDBACK ON
SET VERIFY OFF
SET LINESIZE 240
SET PAGESIZE 200
WHENEVER OSERROR EXIT FAILURE ROLLBACK
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

SPOOL runtime_before_ords_validation.log

PROMPT ============================================================
PROMPT BRECHO EXPRESS - RUNTIME VALIDATION BEFORE ORDS
PROMPT Run this script from the database directory.
PROMPT ============================================================

PROMPT [1/5] Installing updated Core packages...
@@packages/core/install_core_json_pkg.sql
@@packages/core/install_core_response_pkg.sql

PROMPT [2/5] Recompiling updated API package bodies...
@@packages/account/acc_session_api_pkg.pkb
@@packages/account/acc_api_pkg.pkb
@@packages/account/acc_auth_api_pkg.pks
@@packages/account/acc_auth_api_pkg.pkb

@@packages/catalog/brd_api_pkg.pkb
@@packages/catalog/cat_api_pkg.pkb
@@packages/catalog/pim_api_pkg.pkb
@@packages/catalog/pqa_api_pkg.pkb
@@packages/catalog/prd_api_pkg.pkb

@@packages/finance/pay_api_pkg.pkb
@@packages/finance/pev_api_pkg.pkb
@@packages/finance/pot_api_pkg.pkb
@@packages/finance/ppr_api_pkg.pkb
@@packages/finance/sbl_api_pkg.pkb

@@packages/identity/adr_api_pkg.pkb
@@packages/logistics/dlp_api_pkg.pkb
@@packages/logistics/shp_api_pkg.pkb

@@packages/post_sale/rat_api_pkg.pkb
@@packages/post_sale/rrq_api_pkg.pkb
@@packages/post_sale/srp_api_pkg.pkb
@@packages/post_sale/srv_api_pkg.pkb

@@packages/profile/pfl_api_pkg.pkb

@@packages/purchase/crt_api_pkg.pkb
@@packages/purchase/ord_api_pkg.pkb
@@packages/purchase/pur_api_pkg.pkb

@@packages/social/stf_api_pkg.pkb
@@packages/store/ste_api_pkg.pkb
@@packages/store/stp_api_pkg.pkb
@@packages/store/str_api_pkg.pkb

PROMPT [3/5] Reporting compilation errors...
COLUMN name FORMAT A32
COLUMN type FORMAT A20
COLUMN text FORMAT A140

SELECT name, type, line, position, text
  FROM user_errors
 WHERE name IN (
   'CORE_JSON_PKG',
   'CORE_RESPONSE_PKG',
   'ACC_SESSION_API_PKG',
   'ACC_API_PKG',
   'ACC_AUTH_API_PKG',
   'BRD_API_PKG',
   'CAT_API_PKG',
   'PIM_API_PKG',
   'PQA_API_PKG',
   'PRD_API_PKG',
   'PAY_API_PKG',
   'PEV_API_PKG',
   'POT_API_PKG',
   'PPR_API_PKG',
   'SBL_API_PKG',
   'ADR_API_PKG',
   'DLP_API_PKG',
   'SHP_API_PKG',
   'RAT_API_PKG',
   'RRQ_API_PKG',
   'SRP_API_PKG',
   'SRV_API_PKG',
   'PFL_API_PKG',
   'CRT_API_PKG',
   'ORD_API_PKG',
   'PUR_API_PKG',
   'STF_API_PKG',
   'STE_API_PKG',
   'STP_API_PKG',
   'STR_API_PKG'
 )
 ORDER BY name, type, sequence;

DECLARE
  l_invalid_count PLS_INTEGER;
  l_error_count   PLS_INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO l_invalid_count
    FROM user_objects
   WHERE object_name IN (
     'CORE_JSON_PKG',
     'CORE_RESPONSE_PKG',
     'ACC_SESSION_API_PKG',
     'ACC_API_PKG',
     'ACC_AUTH_API_PKG',
     'BRD_API_PKG',
     'CAT_API_PKG',
     'PIM_API_PKG',
     'PQA_API_PKG',
     'PRD_API_PKG',
     'PAY_API_PKG',
     'PEV_API_PKG',
     'POT_API_PKG',
     'PPR_API_PKG',
     'SBL_API_PKG',
     'ADR_API_PKG',
     'DLP_API_PKG',
     'SHP_API_PKG',
     'RAT_API_PKG',
     'RRQ_API_PKG',
     'SRP_API_PKG',
     'SRV_API_PKG',
     'PFL_API_PKG',
     'CRT_API_PKG',
     'ORD_API_PKG',
     'PUR_API_PKG',
     'STF_API_PKG',
     'STE_API_PKG',
     'STP_API_PKG',
     'STR_API_PKG'
   )
     AND object_type IN ('PACKAGE', 'PACKAGE BODY')
     AND status <> 'VALID';

  SELECT COUNT(*)
    INTO l_error_count
    FROM user_errors
   WHERE name IN (
     'CORE_JSON_PKG',
     'CORE_RESPONSE_PKG',
     'ACC_SESSION_API_PKG',
     'ACC_API_PKG',
     'ACC_AUTH_API_PKG',
     'BRD_API_PKG',
     'CAT_API_PKG',
     'PIM_API_PKG',
     'PQA_API_PKG',
     'PRD_API_PKG',
     'PAY_API_PKG',
     'PEV_API_PKG',
     'POT_API_PKG',
     'PPR_API_PKG',
     'SBL_API_PKG',
     'ADR_API_PKG',
     'DLP_API_PKG',
     'SHP_API_PKG',
     'RAT_API_PKG',
     'RRQ_API_PKG',
     'SRP_API_PKG',
     'SRV_API_PKG',
     'PFL_API_PKG',
     'CRT_API_PKG',
     'ORD_API_PKG',
     'PUR_API_PKG',
     'STF_API_PKG',
     'STE_API_PKG',
     'STP_API_PKG',
     'STR_API_PKG'
   );

  IF l_invalid_count > 0 OR l_error_count > 0 THEN
    RAISE_APPLICATION_ERROR(
      -20999,
      'Compilation failed. Invalid objects=' || l_invalid_count
      || ', errors=' || l_error_count
    );
  END IF;

  DBMS_OUTPUT.PUT_LINE('SUCCESS - ALL UPDATED OBJECTS ARE VALID');
END;
/

PROMPT [4/5] Running Core and Account regression tests...
@@tests/core/test_core_trace_pkg.sql
@@tests/core/test_core_error_pkg.sql
@@tests/core/test_core_context_pkg.sql
@@tests/core/test_core_security_context_pkg.sql
@@tests/core/test_core_json_pkg.sql
@@tests/core/test_core_response_pkg.sql
@@tests/account/test_acc_session_api_pkg.sql
@@tests/account/test_acc_api_pkg.sql
@@tests/account/test_acc_auth_module.sql

PROMPT [5/5] Final invalid-object audit...
SELECT object_name, object_type, status
  FROM user_objects
 WHERE status <> 'VALID'
 ORDER BY object_type, object_name;

DECLARE
  l_invalid_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO l_invalid_count
    FROM user_objects
   WHERE status <> 'VALID';

  IF l_invalid_count > 0 THEN
    RAISE_APPLICATION_ERROR(
      -20998,
      'Schema still contains invalid objects: ' || l_invalid_count
    );
  END IF;

  DBMS_OUTPUT.PUT_LINE('SUCCESS - RUNTIME READY FOR ORDS IMPLEMENTATION');
END;
/

SPOOL OFF
EXIT SUCCESS COMMIT
