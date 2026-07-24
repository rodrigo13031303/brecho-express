CREATE OR REPLACE PACKAGE BODY bcf_rule_pkg AS
  PROCEDURE validate_value(p_text VARCHAR2,p_number NUMBER,p_boolean CHAR)IS
    n PLS_INTEGER:=0;
  BEGIN
    IF p_text IS NOT NULL THEN n:=n+1; END IF;
    IF p_number IS NOT NULL THEN n:=n+1; END IF;
    IF p_boolean IS NOT NULL THEN
      IF UPPER(p_boolean) NOT IN('Y','N') THEN RAISE e_invalid; END IF;
      n:=n+1;
    END IF;
    IF n<>1 THEN RAISE e_invalid; END IF;
  END;
END bcf_rule_pkg;
/
