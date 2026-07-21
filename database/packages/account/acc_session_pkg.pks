CREATE OR REPLACE PACKAGE acc_session_pkg AS
  c_err_account_not_found CONSTANT PLS_INTEGER := -20840;
  c_err_invalid_token     CONSTANT PLS_INTEGER := -20841;
  c_err_session_not_found CONSTANT PLS_INTEGER := -20842;
  c_err_session_inactive  CONSTANT PLS_INTEGER := -20843;
  c_err_session_expired   CONSTANT PLS_INTEGER := -20844;
  c_err_invalid_duration  CONSTANT PLS_INTEGER := -20845;

  PROCEDURE create_session(
    p_acc_id            IN BEX_SESSION.ACC_ID%TYPE,
    p_duration_minutes  IN PLS_INTEGER DEFAULT 1440,
    p_created_by        IN BEX_SESSION.SESSION_CREATED_BY%TYPE,
    p_ip                IN BEX_SESSION.SESSION_IP%TYPE,
    p_user_agent        IN BEX_SESSION.SESSION_USER_AGENT%TYPE,
    p_session_public_id OUT BEX_SESSION.SESSION_PUBLIC_ID%TYPE,
    p_session_token     OUT VARCHAR2,
    p_expires_at        OUT BEX_SESSION.SESSION_EXPIRES_AT%TYPE
  );

  FUNCTION validate_session(
    p_session_token IN VARCHAR2,
    p_updated_by    IN BEX_SESSION.SESSION_UPDATED_BY%TYPE DEFAULT NULL
  ) RETURN BEX_SESSION%ROWTYPE;

  FUNCTION get_session_by_public_id(
    p_session_public_id IN BEX_SESSION.SESSION_PUBLIC_ID%TYPE
  ) RETURN BEX_SESSION%ROWTYPE;

  PROCEDURE revoke_session(
    p_session_public_id IN BEX_SESSION.SESSION_PUBLIC_ID%TYPE,
    p_updated_by        IN BEX_SESSION.SESSION_UPDATED_BY%TYPE
  );

  PROCEDURE revoke_all_by_account(
    p_acc_id     IN BEX_SESSION.ACC_ID%TYPE,
    p_updated_by IN BEX_SESSION.SESSION_UPDATED_BY%TYPE
  );

  PROCEDURE expire_sessions(
    p_reference_date IN BEX_SESSION.SESSION_EXPIRES_AT%TYPE
                          DEFAULT SYSTIMESTAMP,
    p_updated_by     IN BEX_SESSION.SESSION_UPDATED_BY%TYPE DEFAULT NULL
  );
END acc_session_pkg;
/
