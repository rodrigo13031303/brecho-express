CREATE OR REPLACE PACKAGE pot_service_pkg AS
  TYPE t_record IS RECORD(payout_public_id CHAR(32),store_public_id CHAR(32),amount NUMBER,
    pix_key VARCHAR2(200),pix_key_type VARCHAR2(20),status VARCHAR2(20),requested_at TIMESTAMP,
    approved_at TIMESTAMP,paid_at TIMESTAMP,rejected_at TIMESTAMP,reject_reason VARCHAR2(1000));
  e_not_found EXCEPTION;e_forbidden EXCEPTION;e_invalid EXCEPTION;e_insufficient EXCEPTION;
  FUNCTION request_payout(p_store VARCHAR2,p_amount NUMBER,p_key VARCHAR2,p_type VARCHAR2,p_actor NUMBER) RETURN t_record;
  FUNCTION get_payout(p_public VARCHAR2,p_actor NUMBER) RETURN t_record;
  FUNCTION change_state_internal(p_public VARCHAR2,p_status VARCHAR2,p_reason VARCHAR2,p_actor NUMBER) RETURN t_record;
END pot_service_pkg;
/
