CREATE OR REPLACE PACKAGE stu_service_pkg AS
  -- Casos de uso da entidade STORE_USER.
  -- Coordena Rule, Repository e Services externos sem executar SQL, controlar
  -- transacoes ou conhecer JSON, HTTP, ORDS ou APEX.

  TYPE t_member_record IS RECORD (
    store_user_public_id BEX_STORE_USER.STU_PUBLIC_ID%TYPE,
    store_public_id      BEX_STORE.STR_PUBLIC_ID%TYPE,
    account_public_id    BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE,
    role_code            BEX_STORE_USER.STU_ROLE_CODE%TYPE,
    status               BEX_STORE_USER.STU_STATUS%TYPE,
    joined_at            BEX_STORE_USER.STU_JOINED_AT%TYPE,
    left_at              BEX_STORE_USER.STU_LEFT_AT%TYPE,
    created_at           BEX_STORE_USER.STU_CREATED_AT%TYPE,
    updated_at           BEX_STORE_USER.STU_UPDATED_AT%TYPE
  );

  TYPE t_member_table IS TABLE OF t_member_record INDEX BY PLS_INTEGER;

  e_store_not_found      EXCEPTION;
  e_account_not_found    EXCEPTION;
  e_member_not_found     EXCEPTION;
  e_invalid_role         EXCEPTION;
  e_invalid_status       EXCEPTION;
  e_invalid_transition   EXCEPTION;
  e_active_link_exists   EXCEPTION;
  e_actor_not_found      EXCEPTION;

  PRAGMA EXCEPTION_INIT(e_store_not_found, -20860);
  PRAGMA EXCEPTION_INIT(e_account_not_found, -20840);
  PRAGMA EXCEPTION_INIT(e_member_not_found, -20880);
  PRAGMA EXCEPTION_INIT(e_invalid_role, -20881);
  PRAGMA EXCEPTION_INIT(e_invalid_status, -20882);
  PRAGMA EXCEPTION_INIT(e_invalid_transition, -20883);
  PRAGMA EXCEPTION_INIT(e_active_link_exists, -20884);
  PRAGMA EXCEPTION_INIT(e_actor_not_found, -20885);

  FUNCTION create_member(
    p_store_public_id   IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_account_public_id IN BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE,
    p_role_code         IN BEX_STORE_USER.STU_ROLE_CODE%TYPE,
    p_actor_public_id   IN BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE
  ) RETURN t_member_record;

  FUNCTION change_role(
    p_store_user_public_id IN BEX_STORE_USER.STU_PUBLIC_ID%TYPE,
    p_role_code            IN BEX_STORE_USER.STU_ROLE_CODE%TYPE,
    p_actor_public_id      IN BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE
  ) RETURN t_member_record;

  FUNCTION activate_member(
    p_store_user_public_id IN BEX_STORE_USER.STU_PUBLIC_ID%TYPE,
    p_actor_public_id      IN BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE
  ) RETURN t_member_record;

  FUNCTION deactivate_member(
    p_store_user_public_id IN BEX_STORE_USER.STU_PUBLIC_ID%TYPE,
    p_actor_public_id      IN BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE
  ) RETURN t_member_record;

  FUNCTION get_member(
    p_store_user_public_id IN BEX_STORE_USER.STU_PUBLIC_ID%TYPE
  ) RETURN t_member_record;

  FUNCTION list_members_by_store(
    p_store_public_id IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_status          IN BEX_STORE_USER.STU_STATUS%TYPE DEFAULT NULL,
    p_role_code       IN BEX_STORE_USER.STU_ROLE_CODE%TYPE DEFAULT NULL
  ) RETURN t_member_table;

  FUNCTION list_stores_by_account(
    p_account_public_id IN BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE,
    p_status            IN BEX_STORE_USER.STU_STATUS%TYPE DEFAULT NULL
  ) RETURN t_member_table;
END stu_service_pkg;
/
