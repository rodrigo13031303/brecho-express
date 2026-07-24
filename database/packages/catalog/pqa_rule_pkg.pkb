CREATE OR REPLACE PACKAGE BODY pqa_rule_pkg AS
  FUNCTION normalize_text(p VARCHAR2) RETURN VARCHAR2 IS
  BEGIN RETURN REGEXP_REPLACE(TRIM(p),'[[:space:]]+',' ');END;
  FUNCTION normalize_status(p VARCHAR2) RETURN VARCHAR2 IS BEGIN RETURN UPPER(TRIM(p));END;
  PROCEDURE validate_question(p VARCHAR2) IS x VARCHAR2(32767):=normalize_text(p);
  BEGIN IF x IS NULL OR LENGTH(x)>4000 THEN RAISE e_invalid_question;END IF;END;
  PROCEDURE validate_answer(p VARCHAR2) IS x VARCHAR2(32767):=normalize_text(p);
  BEGIN IF x IS NULL OR LENGTH(x)>4000 THEN RAISE e_invalid_answer;END IF;END;
  PROCEDURE validate_status(p VARCHAR2) IS x VARCHAR2(30):=normalize_status(p);
  BEGIN IF x IS NULL OR x NOT IN(c_status_active,c_status_hidden,c_status_moderated)
    THEN RAISE e_invalid_status;END IF;END;
END pqa_rule_pkg;
/
