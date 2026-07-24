CREATE OR REPLACE PACKAGE stu_service_pkg AS
  -- Casos de uso internos da entidade STORE_USER.
  -- A STORE e o ator tecnico chegam resolvidos pela orquestracao de Store.
  -- Nao constitui fronteira externa e pode receber identificadores tecnicos.

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

  e_account_not_found  EXCEPTION;
  e_member_not_found   EXCEPTION;
  e_invalid_role       EXCEPTION;
  e_invalid_status     EXCEPTION;
  e_invalid_transition EXCEPTION;
  e_active_link_exists EXCEPTION;

  PRAGMA EXCEPTION_INIT(e_account_not_found, -20840);
  PRAGMA EXCEPTION_INIT(e_member_not_found, -20880);
  PRAGMA EXCEPTION_INIT(e_invalid_role, -20881);
  PRAGMA EXCEPTION_INIT(e_invalid_status, -20882);
  PRAGMA EXCEPTION_INIT(e_invalid_transition, -20883);
  PRAGMA EXCEPTION_INIT(e_active_link_exists, -20884);

  FUNCTION is_active_admin(
    p_store_id   IN BEX_STORE_USER.STR_ID%TYPE,
    p_account_id IN BEX_STORE_USER.ACC_ID%TYPE
  ) RETURN BOOLEAN;

  FUNCTION is_active_catalog_manager(
    p_store_id   IN BEX_STORE_USER.STR_ID%TYPE,
    p_account_id IN BEX_STORE_USER.ACC_ID%TYPE
  ) RETURN BOOLEAN;

  FUNCTION count_active_admins(
    p_store_id IN BEX_STORE_USER.STR_ID%TYPE
  ) RETURN PLS_INTEGER;

  FUNCTION is_admin_role(
    p_role_code IN BEX_STORE_USER.STU_ROLE_CODE%TYPE
  ) RETURN BOOLEAN;

  FUNCTION create_member(
    p_store_id         IN BEX_STORE_USER.STR_ID%TYPE,
    p_store_public_id  IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_account_public_id IN BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE,
    p_role_code        IN BEX_STORE_USER.STU_ROLE_CODE%TYPE,
    p_actor_id         IN BEX_ACCOUNT.ACC_ID%TYPE
  ) RETURN t_member_record;

  FUNCTION change_role(
    p_store_id             IN BEX_STORE_USER.STR_ID%TYPE,
    p_store_public_id      IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_store_user_public_id IN BEX_STORE_USER.STU_PUBLIC_ID%TYPE,
    p_role_code            IN BEX_STORE_USER.STU_ROLE_CODE%TYPE,
    p_actor_id             IN BEX_ACCOUNT.ACC_ID%TYPE
  ) RETURN t_member_record;

  FUNCTION activate_member(
    p_store_id             IN BEX_STORE_USER.STR_ID%TYPE,
    p_store_public_id      IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_store_user_public_id IN BEX_STORE_USER.STU_PUBLIC_ID%TYPE,
    p_actor_id             IN BEX_ACCOUNT.ACC_ID%TYPE
  ) RETURN t_member_record;

  FUNCTION deactivate_member(
    p_store_id             IN BEX_STORE_USER.STR_ID%TYPE,
    p_store_public_id      IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_store_user_public_id IN BEX_STORE_USER.STU_PUBLIC_ID%TYPE,
    p_actor_id             IN BEX_ACCOUNT.ACC_ID%TYPE
  ) RETURN t_member_record;

  FUNCTION get_member(
    p_store_id             IN BEX_STORE_USER.STR_ID%TYPE,
    p_store_public_id      IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_store_user_public_id IN BEX_STORE_USER.STU_PUBLIC_ID%TYPE
  ) RETURN t_member_record;

  FUNCTION list_members_by_store(
    p_store_id        IN BEX_STORE_USER.STR_ID%TYPE,
    p_store_public_id IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_status          IN BEX_STORE_USER.STU_STATUS%TYPE DEFAULT NULL,
    p_role_code       IN BEX_STORE_USER.STU_ROLE_CODE%TYPE DEFAULT NULL
  ) RETURN t_member_table;
END stu_service_pkg;
/
