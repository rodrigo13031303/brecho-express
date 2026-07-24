CREATE OR REPLACE PACKAGE BODY pev_api_pkg AS
  FUNCTION js(p pev_service_pkg.t_result) RETURN JSON_OBJECT_T IS j JSON_OBJECT_T:=JSON_OBJECT_T();
  BEGIN core_json_pkg.put_string(j,'eventPublicId',TRIM(p.event_public_id));
    core_json_pkg.put_string(j,'eventType',p.event_type);core_json_pkg.put_string(j,'externalEventId',p.external_event_id);
    core_json_pkg.put_string(j,'eventStatus',p.event_status);
    core_json_pkg.put_string(j,'paymentPublicId',TRIM(p.payment.payment_public_id));
    core_json_pkg.put_string(j,'paymentStatus',p.payment.status);
    IF p.payment.order_public_id IS NULL THEN core_json_pkg.put_null(j,'orderPublicId');
    ELSE core_json_pkg.put_string(j,'orderPublicId',TRIM(p.payment.order_public_id));END IF;RETURN j;END;
  PROCEDURE receive_event(p_payment_public VARCHAR2,p_body CLOB,p_actor NUMBER,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS j JSON_OBJECT_T;r pev_service_pkg.t_result;
  BEGIN j:=JSON_OBJECT_T.parse(p_body);r:=pev_service_pkg.process_event(p_payment_public,
    j.get_string('eventType'),j.get_string('externalEventId'),
    TO_TIMESTAMP(j.get_string('eventAt'),'YYYY-MM-DD"T"HH24:MI:SS.FF'),p_body,p_actor);
    COMMIT;o_body:=core_response_pkg.build_success(js(r));o_status:=200;
  EXCEPTION WHEN pev_service_pkg.e_payment_not_found THEN ROLLBACK;o_status:=404;o_body:=NULL;
    WHEN pev_service_pkg.e_invalid THEN ROLLBACK;o_status:=422;o_body:=NULL;
    WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=NULL;END;
END pev_api_pkg;
/
