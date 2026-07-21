CREATE OR REPLACE PACKAGE acc_session_repository_pkg AS
  -- Camada de persistencia de sessoes autenticadas.
  -- Executa somente operacoes de dados sobre BEX_SESSION.

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
  );

  FUNCTION get_by_id(
    p_session_id IN BEX_SESSION.SESSION_ID%TYPE
  ) RETURN BEX_SESSION%ROWTYPE;

  FUNCTION get_by_public_id(
    p_session_public_id IN BEX_SESSION.SESSION_PUBLIC_ID%TYPE
  ) RETURN BEX_SESSION%ROWTYPE;

  FUNCTION get_by_token_hash(
    p_token_hash IN BEX_SESSION.SESSION_TOKEN_HASH%TYPE
  ) RETURN BEX_SESSION%ROWTYPE;

  FUNCTION session_exists(
    p_session_id IN BEX_SESSION.SESSION_ID%TYPE
  ) RETURN BOOLEAN;

  FUNCTION token_hash_exists(
    p_token_hash IN BEX_SESSION.SESSION_TOKEN_HASH%TYPE
  ) RETURN BOOLEAN;

  PROCEDURE update_last_used(
    p_session_id   IN BEX_SESSION.SESSION_ID%TYPE,
    p_last_used_at IN BEX_SESSION.SESSION_LAST_USED_AT%TYPE,
    p_updated_by   IN BEX_SESSION.SESSION_UPDATED_BY%TYPE
  );

  PROCEDURE update_status(
    p_session_id IN BEX_SESSION.SESSION_ID%TYPE,
    p_status     IN BEX_SESSION.SESSION_STATUS%TYPE,
    p_revoked_at IN BEX_SESSION.SESSION_REVOKED_AT%TYPE,
    p_updated_by IN BEX_SESSION.SESSION_UPDATED_BY%TYPE
  );

  PROCEDURE revoke_all_by_account(
    p_acc_id     IN BEX_SESSION.ACC_ID%TYPE,
    p_revoked_at IN BEX_SESSION.SESSION_REVOKED_AT%TYPE,
    p_updated_by IN BEX_SESSION.SESSION_UPDATED_BY%TYPE
  );

  PROCEDURE expire_sessions(
    p_reference_date IN BEX_SESSION.SESSION_EXPIRES_AT%TYPE,
    p_updated_by     IN BEX_SESSION.SESSION_UPDATED_BY%TYPE
  );
END acc_session_repository_pkg;
/
