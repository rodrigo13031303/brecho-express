CREATE OR REPLACE PACKAGE pur_rule_pkg AS
  e_invalid_response EXCEPTION;e_request_closed EXCEPTION;
  PROCEDURE validate_response(p_requested NUMBER,p_confirmed NUMBER,p_reason VARCHAR2,
    o_status OUT VARCHAR2,o_reason OUT VARCHAR2);
  PROCEDURE assert_pending(p_status VARCHAR2);
END pur_rule_pkg;
/
