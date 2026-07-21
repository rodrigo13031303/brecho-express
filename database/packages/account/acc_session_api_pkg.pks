CREATE OR REPLACE PACKAGE acc_session_api_pkg AS
  PROCEDURE create_session(
    p_acc_id            IN NUMBER,
    p_duration_minutes  IN PLS_INTEGER DEFAULT 1440,
    p_created_by        IN NUMBER,
    p_ip                IN VARCHAR2,
    p_user_agent        IN VARCHAR2,
    p_session_public_id OUT VARCHAR2,
    p_session_token     OUT VARCHAR2,
    p_expires_at        OUT TIMESTAMP
  );

  FUNCTION validate_session(
    p_session_token IN VARCHAR2,
    p_updated_by    IN NUMBER DEFAULT NULL
  ) RETURN BEX_SESSION%ROWTYPE;

  FUNCTION get_session_by_public_id(
    p_session_public_id IN VARCHAR2
  ) RETURN BEX_SESSION%ROWTYPE;

  PROCEDURE revoke_session(
    p_session_public_id IN VARCHAR2,
    p_updated_by        IN NUMBER
  );

  PROCEDURE revoke_all_by_account(
    p_acc_id     IN NUMBER,
    p_updated_by IN NUMBER
  );

  PROCEDURE expire_sessions(
    p_reference_date IN TIMESTAMP DEFAULT SYSTIMESTAMP,
    p_updated_by     IN NUMBER DEFAULT NULL
  );
END acc_session_api_pkg;
/
