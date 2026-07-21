CREATE OR REPLACE PACKAGE BODY acc_session_pkg AS
  c_active_status  CONSTANT BEX_SESSION.SESSION_STATUS%TYPE := 'ACTIVE';
  c_revoked_status CONSTANT BEX_SESSION.SESSION_STATUS%TYPE := 'REVOKED';
  c_expired_status CONSTANT BEX_SESSION.SESSION_STATUS%TYPE := 'EXPIRED';
  c_token_bytes    CONSTANT PLS_INTEGER := 32;
  c_token_length   CONSTANT PLS_INTEGER := 64;

  ------------------------------------------------------------------------------
  -- Helpers privados
  ------------------------------------------------------------------------------

  FUNCTION generate_public_id
    RETURN BEX_SESSION.SESSION_PUBLIC_ID%TYPE IS
  BEGIN
    RETURN LOWER(RAWTOHEX(SYS_GUID()));
  END generate_public_id;

  FUNCTION generate_token
    RETURN VARCHAR2 IS
  BEGIN
    RETURN LOWER(RAWTOHEX(DBMS_CRYPTO.RANDOMBYTES(c_token_bytes)));
  END generate_token;

  FUNCTION hash_token(
    p_token IN VARCHAR2
  ) RETURN BEX_SESSION.SESSION_TOKEN_HASH%TYPE IS
  BEGIN
    RETURN LOWER(
      RAWTOHEX(
        DBMS_CRYPTO.HASH(
          src => UTL_I18N.STRING_TO_RAW(p_token, 'AL32UTF8'),
          typ => DBMS_CRYPTO.HASH_SH512
        )
      )
    );
  END hash_token;

  PROCEDURE assert_valid_token_format(
    p_token IN VARCHAR2
  ) IS
  BEGIN
    IF p_token IS NULL
       OR LENGTH(p_token) <> c_token_length
       OR NOT REGEXP_LIKE(p_token, '^[0-9a-fA-F]{64}$') THEN
      RAISE_APPLICATION_ERROR(c_err_invalid_token, 'Invalid session token');
    END IF;
  END assert_valid_token_format;

  FUNCTION account_exists(
    p_acc_id IN BEX_SESSION.ACC_ID%TYPE
  ) RETURN BOOLEAN IS
    l_account BEX_ACCOUNT%ROWTYPE;
  BEGIN
    l_account := acc_repository_pkg.get_by_id(p_acc_id);
    RETURN l_account.ACC_ID IS NOT NULL;
  END account_exists;

  ------------------------------------------------------------------------------
  -- Ciclo de vida da sessao
  ------------------------------------------------------------------------------

  PROCEDURE create_session(
    p_acc_id            IN BEX_SESSION.ACC_ID%TYPE,
    p_duration_minutes  IN PLS_INTEGER DEFAULT 1440,
    p_created_by        IN BEX_SESSION.SESSION_CREATED_BY%TYPE,
    p_ip                IN BEX_SESSION.SESSION_IP%TYPE,
    p_user_agent        IN BEX_SESSION.SESSION_USER_AGENT%TYPE,
    p_session_public_id OUT BEX_SESSION.SESSION_PUBLIC_ID%TYPE,
    p_session_token     OUT VARCHAR2,
    p_expires_at        OUT BEX_SESSION.SESSION_EXPIRES_AT%TYPE
  ) IS
    l_created_at TIMESTAMP(6);
    l_token_hash BEX_SESSION.SESSION_TOKEN_HASH%TYPE;
    l_session_id BEX_SESSION.SESSION_ID%TYPE;
  BEGIN
    IF p_duration_minutes IS NULL OR p_duration_minutes <= 0 THEN
      RAISE_APPLICATION_ERROR(
        c_err_invalid_duration,
        'Session duration must be greater than zero'
      );
    END IF;

    IF NOT account_exists(p_acc_id) THEN
      RAISE_APPLICATION_ERROR(c_err_account_not_found, 'Account not found');
    END IF;

    p_session_public_id := generate_public_id;
    p_session_token := generate_token;
    l_token_hash := hash_token(p_session_token);
    l_created_at := SYSTIMESTAMP;
    p_expires_at := l_created_at
      + NUMTODSINTERVAL(p_duration_minutes, 'MINUTE');

    acc_session_repository_pkg.insert_session(
      p_session_public_id => p_session_public_id,
      p_acc_id            => p_acc_id,
      p_token_hash        => l_token_hash,
      p_status            => c_active_status,
      p_created_at        => l_created_at,
      p_expires_at        => p_expires_at,
      p_created_by        => p_created_by,
      p_ip                => p_ip,
      p_user_agent        => p_user_agent,
      p_session_id        => l_session_id
    );
  END create_session;

  FUNCTION validate_session(
    p_session_token IN VARCHAR2,
    p_updated_by    IN BEX_SESSION.SESSION_UPDATED_BY%TYPE DEFAULT NULL
  ) RETURN BEX_SESSION%ROWTYPE IS
    l_session      BEX_SESSION%ROWTYPE;
    l_token_hash   BEX_SESSION.SESSION_TOKEN_HASH%TYPE;
    l_reference_at TIMESTAMP(6);
  BEGIN
    assert_valid_token_format(p_session_token);
    l_token_hash := hash_token(p_session_token);
    l_session := acc_session_repository_pkg.get_by_token_hash(l_token_hash);

    IF l_session.SESSION_ID IS NULL THEN
      RAISE_APPLICATION_ERROR(c_err_session_not_found, 'Session not found');
    END IF;

    IF l_session.SESSION_STATUS <> c_active_status THEN
      RAISE_APPLICATION_ERROR(c_err_session_inactive, 'Session is not active');
    END IF;

    l_reference_at := SYSTIMESTAMP;

    IF l_session.SESSION_EXPIRES_AT <= l_reference_at THEN
      acc_session_repository_pkg.update_status(
        p_session_id => l_session.SESSION_ID,
        p_status     => c_expired_status,
        p_revoked_at => NULL,
        p_updated_by => p_updated_by
      );
      RAISE_APPLICATION_ERROR(c_err_session_expired, 'Session has expired');
    END IF;

    acc_session_repository_pkg.update_last_used(
      p_session_id   => l_session.SESSION_ID,
      p_last_used_at => l_reference_at,
      p_updated_by   => p_updated_by
    );

    l_session.SESSION_LAST_USED_AT := l_reference_at;
    l_session.SESSION_UPDATED_BY := p_updated_by;

    RETURN l_session;
  END validate_session;

  FUNCTION get_session_by_public_id(
    p_session_public_id IN BEX_SESSION.SESSION_PUBLIC_ID%TYPE
  ) RETURN BEX_SESSION%ROWTYPE IS
    l_session BEX_SESSION%ROWTYPE;
  BEGIN
    l_session := acc_session_repository_pkg.get_by_public_id(
      p_session_public_id
    );

    IF l_session.SESSION_ID IS NULL THEN
      RAISE_APPLICATION_ERROR(c_err_session_not_found, 'Session not found');
    END IF;

    RETURN l_session;
  END get_session_by_public_id;

  PROCEDURE revoke_session(
    p_session_public_id IN BEX_SESSION.SESSION_PUBLIC_ID%TYPE,
    p_updated_by        IN BEX_SESSION.SESSION_UPDATED_BY%TYPE
  ) IS
    l_session    BEX_SESSION%ROWTYPE;
    l_revoked_at TIMESTAMP(6);
  BEGIN
    l_session := acc_session_repository_pkg.get_by_public_id(
      p_session_public_id
    );

    IF l_session.SESSION_ID IS NULL THEN
      RAISE_APPLICATION_ERROR(c_err_session_not_found, 'Session not found');
    END IF;

    IF l_session.SESSION_STATUS = c_active_status THEN
      l_revoked_at := SYSTIMESTAMP;
      acc_session_repository_pkg.update_status(
        p_session_id => l_session.SESSION_ID,
        p_status     => c_revoked_status,
        p_revoked_at => l_revoked_at,
        p_updated_by => p_updated_by
      );
    END IF;
  END revoke_session;

  PROCEDURE revoke_all_by_account(
    p_acc_id     IN BEX_SESSION.ACC_ID%TYPE,
    p_updated_by IN BEX_SESSION.SESSION_UPDATED_BY%TYPE
  ) IS
    l_revoked_at TIMESTAMP(6);
  BEGIN
    IF NOT account_exists(p_acc_id) THEN
      RAISE_APPLICATION_ERROR(c_err_account_not_found, 'Account not found');
    END IF;

    l_revoked_at := SYSTIMESTAMP;
    acc_session_repository_pkg.revoke_all_by_account(
      p_acc_id     => p_acc_id,
      p_revoked_at => l_revoked_at,
      p_updated_by => p_updated_by
    );
  END revoke_all_by_account;

  PROCEDURE expire_sessions(
    p_reference_date IN BEX_SESSION.SESSION_EXPIRES_AT%TYPE
                          DEFAULT SYSTIMESTAMP,
    p_updated_by     IN BEX_SESSION.SESSION_UPDATED_BY%TYPE DEFAULT NULL
  ) IS
  BEGIN
    acc_session_repository_pkg.expire_sessions(
      p_reference_date => p_reference_date,
      p_updated_by     => p_updated_by
    );
  END expire_sessions;
END acc_session_pkg;
/
