CREATE OR REPLACE PACKAGE BODY acc_session_api_pkg AS
  e_account_not_found EXCEPTION;
  e_invalid_token     EXCEPTION;
  e_session_not_found EXCEPTION;
  e_session_inactive  EXCEPTION;
  e_session_expired   EXCEPTION;
  e_invalid_duration  EXCEPTION;

  PRAGMA EXCEPTION_INIT(
    e_account_not_found,
    -20840
  );
  PRAGMA EXCEPTION_INIT(
    e_invalid_token,
    -20841
  );
  PRAGMA EXCEPTION_INIT(
    e_session_not_found,
    -20842
  );
  PRAGMA EXCEPTION_INIT(
    e_session_inactive,
    -20843
  );
  PRAGMA EXCEPTION_INIT(
    e_session_expired,
    -20844
  );
  PRAGMA EXCEPTION_INIT(
    e_invalid_duration,
    -20845
  );

  PROCEDURE create_session(
    p_acc_id            IN NUMBER,
    p_duration_minutes  IN PLS_INTEGER DEFAULT 1440,
    p_created_by        IN NUMBER,
    p_ip                IN VARCHAR2,
    p_user_agent        IN VARCHAR2,
    p_session_public_id OUT VARCHAR2,
    p_session_token     OUT VARCHAR2,
    p_expires_at        OUT TIMESTAMP
  ) IS
  BEGIN
    acc_session_pkg.create_session(
      p_acc_id            => p_acc_id,
      p_duration_minutes  => p_duration_minutes,
      p_created_by        => p_created_by,
      p_ip                => p_ip,
      p_user_agent        => p_user_agent,
      p_session_public_id => p_session_public_id,
      p_session_token     => p_session_token,
      p_expires_at        => p_expires_at
    );
    COMMIT;
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX
      OR e_account_not_found
      OR e_invalid_duration THEN
      ROLLBACK;
      RAISE;
  END create_session;

  FUNCTION validate_session(
    p_session_token IN VARCHAR2,
    p_updated_by    IN NUMBER DEFAULT NULL
  ) RETURN BEX_SESSION%ROWTYPE IS
    l_session BEX_SESSION%ROWTYPE;
  BEGIN
    l_session := acc_session_pkg.validate_session(
      p_session_token => p_session_token,
      p_updated_by    => p_updated_by
    );
    COMMIT;
    RETURN l_session;
  EXCEPTION
    WHEN e_invalid_token
      OR e_session_not_found
      OR e_session_inactive
      OR e_session_expired THEN
      ROLLBACK;
      RAISE;
  END validate_session;

  FUNCTION get_session_by_public_id(
    p_session_public_id IN VARCHAR2
  ) RETURN BEX_SESSION%ROWTYPE IS
  BEGIN
    RETURN acc_session_pkg.get_session_by_public_id(p_session_public_id);
  END get_session_by_public_id;

  PROCEDURE revoke_session(
    p_session_public_id IN VARCHAR2,
    p_updated_by        IN NUMBER
  ) IS
  BEGIN
    acc_session_pkg.revoke_session(
      p_session_public_id => p_session_public_id,
      p_updated_by        => p_updated_by
    );
    COMMIT;
  EXCEPTION
    WHEN e_session_not_found THEN
      ROLLBACK;
      RAISE;
  END revoke_session;

  PROCEDURE revoke_all_by_account(
    p_acc_id     IN NUMBER,
    p_updated_by IN NUMBER
  ) IS
  BEGIN
    acc_session_pkg.revoke_all_by_account(
      p_acc_id     => p_acc_id,
      p_updated_by => p_updated_by
    );
    COMMIT;
  EXCEPTION
    WHEN e_account_not_found THEN
      ROLLBACK;
      RAISE;
  END revoke_all_by_account;

  PROCEDURE expire_sessions(
    p_reference_date IN TIMESTAMP DEFAULT SYSTIMESTAMP,
    p_updated_by     IN NUMBER DEFAULT NULL
  ) IS
  BEGIN
    acc_session_pkg.expire_sessions(
      p_reference_date => p_reference_date,
      p_updated_by     => p_updated_by
    );
    COMMIT;
  END expire_sessions;
END acc_session_api_pkg;
/
