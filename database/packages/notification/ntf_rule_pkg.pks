CREATE OR REPLACE PACKAGE ntf_rule_pkg AS
  e_invalid EXCEPTION;
  PROCEDURE validate_notification(p_type VARCHAR2,p_title VARCHAR2,p_body VARCHAR2);
  PROCEDURE validate_channel(p_channel VARCHAR2);
END ntf_rule_pkg;
/
