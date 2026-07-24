CREATE OR REPLACE PACKAGE iam_authorization_pkg AS
  FUNCTION has_role(p_account_id NUMBER,p_role_code VARCHAR2)RETURN BOOLEAN;
  PROCEDURE require_role(p_account_id NUMBER,p_role_code VARCHAR2);
  e_forbidden EXCEPTION;
END iam_authorization_pkg;
/
