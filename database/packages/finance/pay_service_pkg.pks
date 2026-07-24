CREATE OR REPLACE PACKAGE pay_service_pkg AS
  TYPE t_record IS RECORD(payment_public_id CHAR(32),request_public_id CHAR(32),
    order_public_id CHAR(32),provider_public_id CHAR(32),external_id VARCHAR2(100),
    amount NUMBER,method VARCHAR2(20),status VARCHAR2(20),approved_at TIMESTAMP,created_at TIMESTAMP);
  e_not_found EXCEPTION;e_invalid EXCEPTION;e_conflict EXCEPTION;e_forbidden EXCEPTION;
  FUNCTION create_payment(p_request_public VARCHAR2,p_provider_public VARCHAR2,
    p_external VARCHAR2,p_method VARCHAR2,p_actor NUMBER) RETURN t_record;
  FUNCTION get_payment(p_public VARCHAR2,p_actor NUMBER) RETURN t_record;
  FUNCTION get_internal(p_public VARCHAR2) RETURN pay_repository_pkg.t_row;
  FUNCTION get_by_id_internal(p_id NUMBER) RETURN t_record;
  FUNCTION apply_event(p_id NUMBER,p_event_type VARCHAR2,p_actor NUMBER) RETURN t_record;
END pay_service_pkg;
/
