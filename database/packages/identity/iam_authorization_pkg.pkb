CREATE OR REPLACE PACKAGE BODY iam_authorization_pkg AS
  FUNCTION has_role(p_account_id NUMBER,p_role_code VARCHAR2)RETURN BOOLEAN IS n NUMBER;BEGIN
    SELECT COUNT(*)INTO n FROM BEX_PROFILE_ROLE pr JOIN BEX_PROFILE p ON p.PFL_ID=pr.PFL_ID JOIN BEX_ROLE r ON r.ROL_ID=pr.ROL_ID
    WHERE p.ACC_ID=p_account_id AND r.ROL_CODE=UPPER(TRIM(p_role_code))AND r.ROL_STATUS='ACTIVE'AND pr.PRL_STATUS='ACTIVE'
      AND(pr.PRL_EXPIRES_AT IS NULL OR pr.PRL_EXPIRES_AT>SYSTIMESTAMP);RETURN n>0;END;
  PROCEDURE require_role(p_account_id NUMBER,p_role_code VARCHAR2)IS BEGIN IF NOT has_role(p_account_id,p_role_code)THEN RAISE e_forbidden;END IF;END;
END iam_authorization_pkg;
/
