CREATE OR REPLACE PACKAGE stu_repository_pkg AS
  -- Camada de persistencia da entidade STORE_USER.
  -- Recebe valores preparados e executa somente SQL sobre BEX_STORE_USER.

  TYPE t_store_user_record IS RECORD (
    stu_id         BEX_STORE_USER.STU_ID%TYPE,
    stu_public_id  BEX_STORE_USER.STU_PUBLIC_ID%TYPE,
    str_id         BEX_STORE_USER.STR_ID%TYPE,
    acc_id         BEX_STORE_USER.ACC_ID%TYPE,
    stu_role_code  BEX_STORE_USER.STU_ROLE_CODE%TYPE,
    stu_status     BEX_STORE_USER.STU_STATUS%TYPE,
    stu_joined_at  BEX_STORE_USER.STU_JOINED_AT%TYPE,
    stu_left_at    BEX_STORE_USER.STU_LEFT_AT%TYPE,
    stu_created_at BEX_STORE_USER.STU_CREATED_AT%TYPE,
    stu_created_by BEX_STORE_USER.STU_CREATED_BY%TYPE,
    stu_updated_at BEX_STORE_USER.STU_UPDATED_AT%TYPE,
    stu_updated_by BEX_STORE_USER.STU_UPDATED_BY%TYPE
  );

  TYPE t_store_user_table IS TABLE OF t_store_user_record
    INDEX BY PLS_INTEGER;

  PROCEDURE insert_store_user(
    p_public_id IN BEX_STORE_USER.STU_PUBLIC_ID%TYPE,
    p_store_id  IN BEX_STORE_USER.STR_ID%TYPE,
    p_account_id IN BEX_STORE_USER.ACC_ID%TYPE,
    p_role_code IN BEX_STORE_USER.STU_ROLE_CODE%TYPE,
    p_status    IN BEX_STORE_USER.STU_STATUS%TYPE,
    p_joined_at IN BEX_STORE_USER.STU_JOINED_AT%TYPE,
    p_created_by IN BEX_STORE_USER.STU_CREATED_BY%TYPE,
    o_store_user_id OUT BEX_STORE_USER.STU_ID%TYPE
  );

  PROCEDURE update_role(
    p_store_user_id IN BEX_STORE_USER.STU_ID%TYPE,
    p_role_code     IN BEX_STORE_USER.STU_ROLE_CODE%TYPE,
    p_updated_at    IN BEX_STORE_USER.STU_UPDATED_AT%TYPE,
    p_updated_by    IN BEX_STORE_USER.STU_UPDATED_BY%TYPE,
    o_updated       OUT BOOLEAN
  );

  PROCEDURE update_status(
    p_store_user_id IN BEX_STORE_USER.STU_ID%TYPE,
    p_status        IN BEX_STORE_USER.STU_STATUS%TYPE,
    p_left_at       IN BEX_STORE_USER.STU_LEFT_AT%TYPE,
    p_updated_at    IN BEX_STORE_USER.STU_UPDATED_AT%TYPE,
    p_updated_by    IN BEX_STORE_USER.STU_UPDATED_BY%TYPE,
    o_updated       OUT BOOLEAN
  );

  FUNCTION get_by_id(
    p_store_user_id IN BEX_STORE_USER.STU_ID%TYPE
  ) RETURN t_store_user_record;

  FUNCTION get_by_public_id(
    p_public_id IN BEX_STORE_USER.STU_PUBLIC_ID%TYPE
  ) RETURN t_store_user_record;

  FUNCTION get_active_by_store_account(
    p_store_id   IN BEX_STORE_USER.STR_ID%TYPE,
    p_account_id IN BEX_STORE_USER.ACC_ID%TYPE
  ) RETURN t_store_user_record;

  FUNCTION public_id_exists(
    p_public_id IN BEX_STORE_USER.STU_PUBLIC_ID%TYPE
  ) RETURN BOOLEAN;

  FUNCTION active_link_exists(
    p_store_id   IN BEX_STORE_USER.STR_ID%TYPE,
    p_account_id IN BEX_STORE_USER.ACC_ID%TYPE
  ) RETURN BOOLEAN;

  FUNCTION active_admin_exists(
    p_store_id   IN BEX_STORE_USER.STR_ID%TYPE,
    p_account_id IN BEX_STORE_USER.ACC_ID%TYPE
  ) RETURN BOOLEAN;

  FUNCTION count_active_admins(
    p_store_id IN BEX_STORE_USER.STR_ID%TYPE
  ) RETURN PLS_INTEGER;

  FUNCTION list_by_store(
    p_store_id  IN BEX_STORE_USER.STR_ID%TYPE,
    p_status    IN BEX_STORE_USER.STU_STATUS%TYPE DEFAULT NULL,
    p_role_code IN BEX_STORE_USER.STU_ROLE_CODE%TYPE DEFAULT NULL
  ) RETURN t_store_user_table;

  FUNCTION list_by_account(
    p_account_id IN BEX_STORE_USER.ACC_ID%TYPE,
    p_status     IN BEX_STORE_USER.STU_STATUS%TYPE DEFAULT NULL
  ) RETURN t_store_user_table;
END stu_repository_pkg;
/
