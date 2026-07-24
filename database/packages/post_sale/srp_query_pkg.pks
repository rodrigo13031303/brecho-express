CREATE OR REPLACE PACKAGE srp_query_pkg AS
  TYPE t_record IS RECORD(store_public_id CHAR(32),overall_rate NUMBER,review_count NUMBER,order_count NUMBER,
    return_request_count NUMBER,return_rate NUMBER,would_buy_again_rate NUMBER,last_review_at TIMESTAMP);
  e_not_found EXCEPTION;FUNCTION get_store(p_store VARCHAR2)RETURN t_record;
END srp_query_pkg;
/
