CREATE OR REPLACE PACKAGE BODY pur_rule_pkg AS
  PROCEDURE validate_response(p_requested NUMBER,p_confirmed NUMBER,p_reason VARCHAR2,
    o_status OUT VARCHAR2,o_reason OUT VARCHAR2) IS r VARCHAR2(500):=TRIM(p_reason);
  BEGIN
    IF p_requested IS NULL OR p_requested<=0 OR p_confirmed IS NULL
       OR p_confirmed<0 OR p_confirmed>p_requested OR p_confirmed<>TRUNC(p_confirmed)
    THEN RAISE e_invalid_response;END IF;
    IF p_confirmed=0 THEN IF r IS NULL THEN RAISE e_invalid_response;END IF;
      o_status:='REJECTED';o_reason:=r;
    ELSIF p_confirmed=p_requested THEN IF r IS NOT NULL THEN RAISE e_invalid_response;END IF;
      o_status:='APPROVED';o_reason:=NULL;
    ELSE IF r IS NOT NULL THEN RAISE e_invalid_response;END IF;
      o_status:='PARTIALLY_APPROVED';o_reason:=NULL;END IF;
  END;
  PROCEDURE assert_pending(p_status VARCHAR2) IS BEGIN
    IF p_status<>'PENDING' THEN RAISE e_request_closed;END IF;END;
END pur_rule_pkg;
/
