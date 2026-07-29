SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF
SET ECHO ON
SET FEEDBACK ON
WHENEVER OSERROR EXIT FAILURE ROLLBACK
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

SPOOL purchase_request_expiry_fix.log

PROMPT ============================================================
PROMPT BRECHO EXPRESS - PURCHASE EXPIRY AND ENCODING FIX
PROMPT ============================================================

@@packages/purchase/install_pur_service_pkg.sql
@@packages/purchase/install_pur_api_pkg.sql

UPDATE BEX_PURCHASE_REQUEST_ITEM item_data
   SET item_data.PRI_REJECT_REASON = UNISTR('Prazo de 5 minutos \00E3o atendido pelo brech\00F3'),
       item_data.PRI_UPDATED_AT = SYS_EXTRACT_UTC(SYSTIMESTAMP)
 WHERE item_data.PRI_STATUS = 'REJECTED'
   AND EXISTS(
     SELECT 1
       FROM BEX_PURCHASE_REQUEST request_data
      WHERE request_data.PUR_ID = item_data.PUR_ID
        AND request_data.PUR_STATUS = 'EXPIRED'
   );

COMMIT;

DECLARE
  l_invalid_count PLS_INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO l_invalid_count
    FROM USER_OBJECTS
   WHERE OBJECT_NAME IN ('PUR_SERVICE_PKG', 'PUR_API_PKG')
     AND STATUS <> 'VALID';

  IF l_invalid_count > 0 THEN
    RAISE_APPLICATION_ERROR(
      -20999,
      'Purchase packages are invalid after timezone fix.'
    );
  END IF;

  DBMS_OUTPUT.PUT_LINE(
    'SUCCESS - PURCHASE EXPIRY AND ENCODING FIX INSTALLED'
  );
END;
/

SPOOL OFF
EXIT SUCCESS COMMIT
