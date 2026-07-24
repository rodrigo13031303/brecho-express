CREATE OR REPLACE PACKAGE pqa_rule_pkg AS
  c_status_active CONSTANT VARCHAR2(20):='ACTIVE';
  c_status_hidden CONSTANT VARCHAR2(20):='HIDDEN';
  c_status_moderated CONSTANT VARCHAR2(20):='MODERATED';
  e_invalid_question EXCEPTION;e_invalid_answer EXCEPTION;e_invalid_status EXCEPTION;
  FUNCTION normalize_text(p VARCHAR2) RETURN VARCHAR2;
  FUNCTION normalize_status(p VARCHAR2) RETURN VARCHAR2;
  PROCEDURE validate_question(p VARCHAR2);
  PROCEDURE validate_answer(p VARCHAR2);
  PROCEDURE validate_status(p VARCHAR2);
END pqa_rule_pkg;
/
