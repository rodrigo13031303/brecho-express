SET DEFINE OFF
SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

PROMPT Corrigindo textos Unicode das notificacoes push...

UPDATE BEX_PUSH_OUTBOX
   SET PBO_TITLE = UNISTR('Nova solicita\00E7\00E3o!'),
       PBO_BODY = UNISTR('Voc\00EA tem 5 minutos para confirmar a disponibilidade.'),
       PBO_UPDATED_AT = SYS_EXTRACT_UTC(SYSTIMESTAMP)
 WHERE PBO_TYPE = 'SELLER_REQUEST'
   AND PBO_STATUS IN ('PENDING', 'FAILED');

UPDATE BEX_PUSH_OUTBOX
   SET PBO_TITLE = UNISTR('O brech\00F3 respondeu!'),
       PBO_BODY = CASE
         WHEN PBO_DATA LIKE '%"status":"REJECTED"%'
           THEN UNISTR('As pe\00E7as n\00E3o est\00E3o dispon\00EDveis desta vez.')
         ELSE UNISTR('As pe\00E7as foram confirmadas. Continue sua compra.')
       END,
       PBO_UPDATED_AT = SYS_EXTRACT_UTC(SYSTIMESTAMP)
 WHERE PBO_TYPE = 'BUYER_STOCK_RESPONSE'
   AND PBO_STATUS IN ('PENDING', 'FAILED');

COMMIT;

@@packages/purchase/pur_service_pkg.pkb

SHOW ERRORS PACKAGE BODY PUR_SERVICE_PKG

DECLARE
  l_errors NUMBER;
BEGIN
  SELECT COUNT(*)
    INTO l_errors
    FROM USER_ERRORS
   WHERE NAME = 'PUR_SERVICE_PKG'
     AND TYPE = 'PACKAGE BODY';

  IF l_errors > 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'PUR_SERVICE_PKG ficou invalido.');
  END IF;
  DBMS_OUTPUT.PUT_LINE('Textos Unicode e PUR_SERVICE_PKG atualizados com sucesso.');
END;
/

EXIT SUCCESS
