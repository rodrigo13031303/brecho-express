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
  BEGIN j:=core_json_pkg.parse_object(p_body);core_json_pkg.assert_allowed_attributes(j,'eventType,externalEventId,eventAt');r:=pev_service_pkg.process_event(p_payment_public,
    core_json_pkg.required_string(j,'eventType'),core_json_pkg.required_string(j,'externalEventId'),
    core_json_pkg.required_timestamp(j,'eventAt','YYYY-MM-DD"T"HH24:MI:SS.FF'),p_body,p_actor);
    o_body:=core_response_pkg.build_success(js(r));COMMIT;o_status:=200;
  EXCEPTION WHEN core_json_pkg.e_unknown_attribute THEN ROLLBACK;o_status:=400;o_body:=core_response_pkg.build_known_error('BEX-REQ-006',core_error_pkg.c_category_validation,'A requisicao contem campo desconhecido.');
    WHEN core_json_pkg.e_request_body_required OR core_json_pkg.e_invalid_json OR core_json_pkg.e_json_object_required OR core_json_pkg.e_required_attribute OR core_json_pkg.e_invalid_attribute_type OR core_json_pkg.e_invalid_temporal_value THEN ROLLBACK;o_status:=400;o_body:=core_response_pkg.build_known_error('BEX-REQ-002',core_error_pkg.c_category_validation,'O evento de pagamento e invalido.');
    WHEN pev_service_pkg.e_payment_not_found THEN ROLLBACK;o_status:=404;o_body:=core_response_pkg.build_known_error('BEX-PAY-001',core_error_pkg.c_category_not_found,'O pagamento informado nao foi encontrado.');
    WHEN pev_service_pkg.e_invalid THEN ROLLBACK;o_status:=422;o_body:=core_response_pkg.build_known_error('BEX-PEV-001',core_error_pkg.c_category_validation,'O evento de pagamento e invalido.');
    WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=core_response_pkg.build_technical_error;END;
END pev_api_pkg;
/
