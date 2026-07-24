CREATE OR REPLACE PACKAGE BODY pay_api_pkg AS
  FUNCTION js(p pay_service_pkg.t_record) RETURN JSON_OBJECT_T IS j JSON_OBJECT_T:=JSON_OBJECT_T();
  BEGIN core_json_pkg.put_string(j,'paymentPublicId',TRIM(p.payment_public_id));
    core_json_pkg.put_string(j,'requestPublicId',TRIM(p.request_public_id));
    IF p.order_public_id IS NULL THEN core_json_pkg.put_null(j,'orderPublicId');
    ELSE core_json_pkg.put_string(j,'orderPublicId',TRIM(p.order_public_id));END IF;
    core_json_pkg.put_string(j,'providerPublicId',TRIM(p.provider_public_id));
    IF p.external_id IS NULL THEN core_json_pkg.put_null(j,'externalId');ELSE core_json_pkg.put_string(j,'externalId',p.external_id);END IF;
    core_json_pkg.put_number(j,'amount',p.amount);core_json_pkg.put_string(j,'method',p.method);
    core_json_pkg.put_string(j,'status',p.status);RETURN j;END;
  PROCEDURE create_payment(p_body CLOB,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS
    j JSON_OBJECT_T;r pay_service_pkg.t_record;
  BEGIN j:=JSON_OBJECT_T.parse(p_body);r:=pay_service_pkg.create_payment(j.get_string('requestPublicId'),
    j.get_string('providerPublicId'),j.get_string('externalId'),j.get_string('method'),p_actor);
    COMMIT;o_body:=core_response_pkg.build_success(js(r));o_status:=201;
  EXCEPTION WHEN pay_service_pkg.e_conflict THEN ROLLBACK;o_status:=409;o_body:=NULL;
    WHEN pay_service_pkg.e_invalid THEN ROLLBACK;o_status:=422;o_body:=NULL;
    WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=NULL;END;
  PROCEDURE get_payment(p_public VARCHAR2,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS r pay_service_pkg.t_record;
  BEGIN r:=pay_service_pkg.get_payment(p_public,p_actor);o_body:=core_response_pkg.build_success(js(r));o_status:=200;
  EXCEPTION WHEN pay_service_pkg.e_not_found THEN o_status:=404;o_body:=NULL;
    WHEN pay_service_pkg.e_forbidden THEN o_status:=403;o_body:=NULL;WHEN OTHERS THEN o_status:=500;o_body:=NULL;END;
END pay_api_pkg;
/
