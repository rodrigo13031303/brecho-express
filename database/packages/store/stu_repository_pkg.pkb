CREATE OR REPLACE PACKAGE BODY stu_repository_pkg AS
  PROCEDURE insert_store_user(
    p_public_id IN BEX_STORE_USER.STU_PUBLIC_ID%TYPE,
    p_store_id  IN BEX_STORE_USER.STR_ID%TYPE,
    p_account_id IN BEX_STORE_USER.ACC_ID%TYPE,
    p_role_code IN BEX_STORE_USER.STU_ROLE_CODE%TYPE,
    p_status    IN BEX_STORE_USER.STU_STATUS%TYPE,
    p_joined_at IN BEX_STORE_USER.STU_JOINED_AT%TYPE,
    p_created_by IN BEX_STORE_USER.STU_CREATED_BY%TYPE,
    o_store_user_id OUT BEX_STORE_USER.STU_ID%TYPE
  ) IS
  BEGIN
    INSERT INTO BEX_STORE_USER
    (
      STU_PUBLIC_ID,
      STR_ID,
      ACC_ID,
      STU_ROLE_CODE,
      STU_STATUS,
      STU_JOINED_AT,
      STU_CREATED_BY
    )
    VALUES
    (
      p_public_id,
      p_store_id,
      p_account_id,
      p_role_code,
      p_status,
      p_joined_at,
      p_created_by
    )
    RETURNING STU_ID INTO o_store_user_id;
  END insert_store_user;

  PROCEDURE update_role(
    p_store_user_id IN BEX_STORE_USER.STU_ID%TYPE,
    p_role_code     IN BEX_STORE_USER.STU_ROLE_CODE%TYPE,
    p_updated_at    IN BEX_STORE_USER.STU_UPDATED_AT%TYPE,
    p_updated_by    IN BEX_STORE_USER.STU_UPDATED_BY%TYPE,
    o_updated       OUT BOOLEAN
  ) IS
  BEGIN
    UPDATE BEX_STORE_USER
       SET STU_ROLE_CODE = p_role_code,
           STU_UPDATED_AT = p_updated_at,
           STU_UPDATED_BY = p_updated_by
     WHERE STU_ID = p_store_user_id;

    o_updated := SQL%ROWCOUNT = 1;
  END update_role;

  PROCEDURE update_status(
    p_store_user_id IN BEX_STORE_USER.STU_ID%TYPE,
    p_status        IN BEX_STORE_USER.STU_STATUS%TYPE,
    p_left_at       IN BEX_STORE_USER.STU_LEFT_AT%TYPE,
    p_updated_at    IN BEX_STORE_USER.STU_UPDATED_AT%TYPE,
    p_updated_by    IN BEX_STORE_USER.STU_UPDATED_BY%TYPE,
    o_updated       OUT BOOLEAN
  ) IS
  BEGIN
    UPDATE BEX_STORE_USER
       SET STU_STATUS = p_status,
           STU_LEFT_AT = p_left_at,
           STU_UPDATED_AT = p_updated_at,
           STU_UPDATED_BY = p_updated_by
     WHERE STU_ID = p_store_user_id;

    o_updated := SQL%ROWCOUNT = 1;
  END update_status;

  FUNCTION get_by_id(
    p_store_user_id IN BEX_STORE_USER.STU_ID%TYPE
  ) RETURN t_store_user_record IS
    l_store_user t_store_user_record;
  BEGIN
    SELECT su.STU_ID,
           su.STU_PUBLIC_ID,
           su.STR_ID,
           su.ACC_ID,
           su.STU_ROLE_CODE,
           su.STU_STATUS,
           su.STU_JOINED_AT,
           su.STU_LEFT_AT,
           su.STU_CREATED_AT,
           su.STU_CREATED_BY,
           su.STU_UPDATED_AT,
           su.STU_UPDATED_BY
      INTO l_store_user
      FROM BEX_STORE_USER su
     WHERE su.STU_ID = p_store_user_id;

    RETURN l_store_user;
  END get_by_id;

  FUNCTION get_by_public_id(
    p_public_id IN BEX_STORE_USER.STU_PUBLIC_ID%TYPE
  ) RETURN t_store_user_record IS
    l_store_user t_store_user_record;
  BEGIN
    SELECT su.STU_ID,
           su.STU_PUBLIC_ID,
           su.STR_ID,
           su.ACC_ID,
           su.STU_ROLE_CODE,
           su.STU_STATUS,
           su.STU_JOINED_AT,
           su.STU_LEFT_AT,
           su.STU_CREATED_AT,
           su.STU_CREATED_BY,
           su.STU_UPDATED_AT,
           su.STU_UPDATED_BY
      INTO l_store_user
      FROM BEX_STORE_USER su
     WHERE su.STU_PUBLIC_ID = p_public_id;

    RETURN l_store_user;
  END get_by_public_id;

  FUNCTION get_active_by_store_account(
    p_store_id   IN BEX_STORE_USER.STR_ID%TYPE,
    p_account_id IN BEX_STORE_USER.ACC_ID%TYPE
  ) RETURN t_store_user_record IS
    l_store_user t_store_user_record;
  BEGIN
    SELECT su.STU_ID,
           su.STU_PUBLIC_ID,
           su.STR_ID,
           su.ACC_ID,
           su.STU_ROLE_CODE,
           su.STU_STATUS,
           su.STU_JOINED_AT,
           su.STU_LEFT_AT,
           su.STU_CREATED_AT,
           su.STU_CREATED_BY,
           su.STU_UPDATED_AT,
           su.STU_UPDATED_BY
      INTO l_store_user
      FROM BEX_STORE_USER su
     WHERE su.STR_ID = p_store_id
       AND su.ACC_ID = p_account_id
       AND su.STU_STATUS = stu_rule_pkg.c_status_active;

    RETURN l_store_user;
  END get_active_by_store_account;

  FUNCTION public_id_exists(
    p_public_id IN BEX_STORE_USER.STU_PUBLIC_ID%TYPE
  ) RETURN BOOLEAN IS
    l_exists PLS_INTEGER;
  BEGIN
    SELECT 1
      INTO l_exists
      FROM BEX_STORE_USER su
     WHERE su.STU_PUBLIC_ID = p_public_id;

    RETURN TRUE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN FALSE;
  END public_id_exists;

  FUNCTION active_link_exists(
    p_store_id   IN BEX_STORE_USER.STR_ID%TYPE,
    p_account_id IN BEX_STORE_USER.ACC_ID%TYPE
  ) RETURN BOOLEAN IS
    l_exists PLS_INTEGER;
  BEGIN
    SELECT 1
      INTO l_exists
      FROM BEX_STORE_USER su
     WHERE su.STR_ID = p_store_id
       AND su.ACC_ID = p_account_id
       AND su.STU_STATUS = stu_rule_pkg.c_status_active;

    RETURN TRUE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN FALSE;
  END active_link_exists;

  FUNCTION active_admin_exists(
    p_store_id   IN BEX_STORE_USER.STR_ID%TYPE,
    p_account_id IN BEX_STORE_USER.ACC_ID%TYPE
  ) RETURN BOOLEAN IS
    l_exists PLS_INTEGER;
  BEGIN
    SELECT 1
      INTO l_exists
      FROM BEX_STORE_USER su
     WHERE su.STR_ID = p_store_id
       AND su.ACC_ID = p_account_id
       AND su.STU_STATUS = stu_rule_pkg.c_status_active
       AND su.STU_ROLE_CODE = stu_rule_pkg.c_role_admin;

    RETURN TRUE;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN FALSE;
  END active_admin_exists;

  FUNCTION count_active_admins(
    p_store_id IN BEX_STORE_USER.STR_ID%TYPE
  ) RETURN PLS_INTEGER IS
    l_count PLS_INTEGER;
  BEGIN
    SELECT COUNT(*)
      INTO l_count
      FROM BEX_STORE_USER su
     WHERE su.STR_ID = p_store_id
       AND su.STU_STATUS = stu_rule_pkg.c_status_active
       AND su.STU_ROLE_CODE = stu_rule_pkg.c_role_admin;

    RETURN l_count;
  END count_active_admins;

  FUNCTION list_by_store(
    p_store_id  IN BEX_STORE_USER.STR_ID%TYPE,
    p_status    IN BEX_STORE_USER.STU_STATUS%TYPE DEFAULT NULL,
    p_role_code IN BEX_STORE_USER.STU_ROLE_CODE%TYPE DEFAULT NULL
  ) RETURN t_store_user_table IS
    l_store_users t_store_user_table;
  BEGIN
    SELECT su.STU_ID,
           su.STU_PUBLIC_ID,
           su.STR_ID,
           su.ACC_ID,
           su.STU_ROLE_CODE,
           su.STU_STATUS,
           su.STU_JOINED_AT,
           su.STU_LEFT_AT,
           su.STU_CREATED_AT,
           su.STU_CREATED_BY,
           su.STU_UPDATED_AT,
           su.STU_UPDATED_BY
      BULK COLLECT INTO l_store_users
      FROM BEX_STORE_USER su
     WHERE su.STR_ID = p_store_id
       AND (p_status IS NULL OR su.STU_STATUS = p_status)
       AND (p_role_code IS NULL OR su.STU_ROLE_CODE = p_role_code)
     ORDER BY su.STU_JOINED_AT,
              su.STU_ID;

    RETURN l_store_users;
  END list_by_store;

  FUNCTION list_by_account(
    p_account_id IN BEX_STORE_USER.ACC_ID%TYPE,
    p_status     IN BEX_STORE_USER.STU_STATUS%TYPE DEFAULT NULL
  ) RETURN t_store_user_table IS
    l_store_users t_store_user_table;
  BEGIN
    SELECT su.STU_ID,
           su.STU_PUBLIC_ID,
           su.STR_ID,
           su.ACC_ID,
           su.STU_ROLE_CODE,
           su.STU_STATUS,
           su.STU_JOINED_AT,
           su.STU_LEFT_AT,
           su.STU_CREATED_AT,
           su.STU_CREATED_BY,
           su.STU_UPDATED_AT,
           su.STU_UPDATED_BY
      BULK COLLECT INTO l_store_users
      FROM BEX_STORE_USER su
     WHERE su.ACC_ID = p_account_id
       AND (p_status IS NULL OR su.STU_STATUS = p_status)
     ORDER BY su.STU_JOINED_AT,
              su.STU_ID;

    RETURN l_store_users;
  END list_by_account;
END stu_repository_pkg;
/
