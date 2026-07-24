CREATE OR REPLACE PACKAGE pev_service_pkg AS
  TYPE t_result IS RECORD(event_public_id CHAR(32),event_type VARCHAR2(50),
    external_event_id VARCHAR2(100),event_status VARCHAR2(20),payment pay_service_pkg.t_record);
  e_invalid EXCEPTION;e_payment_not_found EXCEPTION;
  FUNCTION process_event(p_payment_public VARCHAR2,p_type VARCHAR2,p_external VARCHAR2,
    p_at TIMESTAMP,p_payload CLOB,p_actor NUMBER) RETURN t_result;
END pev_service_pkg;
/
