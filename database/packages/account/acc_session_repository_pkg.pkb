CREATE OR REPLACE PACKAGE BODY acc_session_repository_pkg AS
  ------------------------------------------------------------------------------
  -- Insercao
  ------------------------------------------------------------------------------

  PROCEDURE insert_session(
    p_session_public_id IN BEX_SESSION.SESSION_PUBLIC_ID%TYPE,
    p_acc_id            IN BEX_SESSION.ACC_ID%TYPE,
    p_token_hash        IN BEX_SESSION.SESSION_TOKEN_HASH%TYPE,
    p_status            IN BEX_SESSION.SESSION_STATUS%TYPE,
    p_created_at        IN BEX_SESSION.SESSION_CREATED_AT%TYPE,
    p_expires_at        IN BEX_SESSION.SESSION_EXPIRES_AT%TYPE,
    p_created_by        IN BEX_SESSION.SESSION_CREATED_BY%TYPE,
    p_ip                IN BEX_SESSION.SESSION_IP%TYPE,
    p_user_agent        IN BEX_SESSION.SESSION_USER_AGENT%TYPE,
    p_session_id        OUT BEX_SESSION.SESSION_ID%TYPE
  ) IS
  BEGIN
    INSERT INTO BEX_SESSION
    (
      SESSION_PUBLIC_ID,
      ACC_ID,
      SESSION_TOKEN_HASH,
      SESSION_STATUS,
      SESSION_CREATED_AT,
      SESSION_EXPIRES_AT,
      SESSION_CREATED_BY,
      SESSION_IP,
      SESSION_USER_AGENT
    )
    VALUES
    (
      p_session_public_id,
      p_acc_id,
      p_token_hash,
      p_status,
      p_created_at,
      p_expires_at,
      p_created_by,
      p_ip,
      p_user_agent
    )
    RETURNING SESSION_ID INTO p_session_id;
  END insert_session;

  ------------------------------------------------------------------------------
  -- Consultas
  ------------------------------------------------------------------------------

  FUNCTION get_by_id(
    p_session_id IN BEX_SESSION.SESSION_ID%TYPE
  ) RETURN BEX_SESSION%ROWTYPE IS
    l_session BEX_SESSION%ROWTYPE;
  BEGIN
    SELECT *
      INTO l_session
      FROM BEX_SESSION
     WHERE SESSION_ID = p_session_id;

    RETURN l_session;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN l_session;
  END get_by_id;

  FUNCTION get_by_public_id(
    p_session_public_id IN BEX_SESSION.SESSION_PUBLIC_ID%TYPE
  ) RETURN BEX_SESSION%ROWTYPE IS
    l_session BEX_SESSION%ROWTYPE;
  BEGIN
    SELECT *
      INTO l_session
      FROM BEX_SESSION
     WHERE SESSION_PUBLIC_ID = p_session_public_id;

    RETURN l_session;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN l_session;
  END get_by_public_id;

  FUNCTION get_by_token_hash(
    p_token_hash IN BEX_SESSION.SESSION_TOKEN_HASH%TYPE
  ) RETURN BEX_SESSION%ROWTYPE IS
    l_session BEX_SESSION%ROWTYPE;
  BEGIN
    SELECT *
      INTO l_session
      FROM BEX_SESSION
     WHERE SESSION_TOKEN_HASH = p_token_hash;

    RETURN l_session;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN l_session;
  END get_by_token_hash;

  FUNCTION session_exists(
    p_session_id IN BEX_SESSION.SESSION_ID%TYPE
  ) RETURN BOOLEAN IS
    l_count PLS_INTEGER;
  BEGIN
    SELECT COUNT(*)
      INTO l_count
      FROM BEX_SESSION
     WHERE SESSION_ID = p_session_id;

    RETURN l_count > 0;
  END session_exists;

  FUNCTION token_hash_exists(
    p_token_hash IN BEX_SESSION.SESSION_TOKEN_HASH%TYPE
  ) RETURN BOOLEAN IS
    l_count PLS_INTEGER;
  BEGIN
    SELECT COUNT(*)
      INTO l_count
      FROM BEX_SESSION
     WHERE SESSION_TOKEN_HASH = p_token_hash;

    RETURN l_count > 0;
  END token_hash_exists;

  ------------------------------------------------------------------------------
  -- Atualizacoes
  ------------------------------------------------------------------------------

  PROCEDURE update_last_used(
    p_session_id   IN BEX_SESSION.SESSION_ID%TYPE,
    p_last_used_at IN BEX_SESSION.SESSION_LAST_USED_AT%TYPE,
    p_updated_by   IN BEX_SESSION.SESSION_UPDATED_BY%TYPE
  ) IS
  BEGIN
    UPDATE BEX_SESSION
       SET SESSION_LAST_USED_AT = p_last_used_at,
           SESSION_UPDATED_BY = p_updated_by
     WHERE SESSION_ID = p_session_id;
  END update_last_used;

  PROCEDURE update_status(
    p_session_id IN BEX_SESSION.SESSION_ID%TYPE,
    p_status     IN BEX_SESSION.SESSION_STATUS%TYPE,
    p_revoked_at IN BEX_SESSION.SESSION_REVOKED_AT%TYPE,
    p_updated_by IN BEX_SESSION.SESSION_UPDATED_BY%TYPE
  ) IS
  BEGIN
    UPDATE BEX_SESSION
       SET SESSION_STATUS = p_status,
           SESSION_REVOKED_AT = p_revoked_at,
           SESSION_UPDATED_BY = p_updated_by
     WHERE SESSION_ID = p_session_id;
  END update_status;

  PROCEDURE revoke_all_by_account(
    p_acc_id     IN BEX_SESSION.ACC_ID%TYPE,
    p_revoked_at IN BEX_SESSION.SESSION_REVOKED_AT%TYPE,
    p_updated_by IN BEX_SESSION.SESSION_UPDATED_BY%TYPE
  ) IS
  BEGIN
    UPDATE BEX_SESSION
       SET SESSION_STATUS = 'REVOKED',
           SESSION_REVOKED_AT = p_revoked_at,
           SESSION_UPDATED_BY = p_updated_by
     WHERE ACC_ID = p_acc_id
       AND SESSION_STATUS = 'ACTIVE';
  END revoke_all_by_account;

  PROCEDURE expire_sessions(
    p_reference_date IN BEX_SESSION.SESSION_EXPIRES_AT%TYPE,
    p_updated_by     IN BEX_SESSION.SESSION_UPDATED_BY%TYPE
  ) IS
  BEGIN
    UPDATE BEX_SESSION
       SET SESSION_STATUS = 'EXPIRED',
           SESSION_UPDATED_BY = p_updated_by
     WHERE SESSION_STATUS = 'ACTIVE'
       AND SESSION_EXPIRES_AT <= p_reference_date;
  END expire_sessions;
END acc_session_repository_pkg;
/
