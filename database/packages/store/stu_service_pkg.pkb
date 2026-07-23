CREATE OR REPLACE PACKAGE BODY stu_service_pkg AS
  c_public_id_attempts CONSTANT PLS_INTEGER := 3;

  FUNCTION generate_public_id
    RETURN BEX_STORE_USER.STU_PUBLIC_ID%TYPE IS
  BEGIN
    RETURN LOWER(RAWTOHEX(SYS_GUID()));
  END generate_public_id;

  FUNCTION to_public_record(
    p_member          IN stu_repository_pkg.t_store_user_record,
    p_store_public_id IN BEX_STORE.STR_PUBLIC_ID%TYPE
  ) RETURN t_member_record IS
    l_result  t_member_record;
    l_account BEX_ACCOUNT%ROWTYPE;
  BEGIN
    l_account := acc_service_pkg.get_account(p_member.acc_id);

    l_result.store_user_public_id := p_member.stu_public_id;
    l_result.store_public_id := p_store_public_id;
    l_result.account_public_id := l_account.ACC_PUBLIC_ID;
    l_result.role_code := p_member.stu_role_code;
    l_result.status := p_member.stu_status;
    l_result.joined_at := p_member.stu_joined_at;
    l_result.left_at := p_member.stu_left_at;
    l_result.created_at := p_member.stu_created_at;
    l_result.updated_at := p_member.stu_updated_at;
    RETURN l_result;
  END to_public_record;

  FUNCTION to_public_table(
    p_members         IN stu_repository_pkg.t_store_user_table,
    p_store_public_id IN BEX_STORE.STR_PUBLIC_ID%TYPE
  ) RETURN t_member_table IS
    l_result t_member_table;
    l_index  PLS_INTEGER;
  BEGIN
    l_index := p_members.FIRST;
    WHILE l_index IS NOT NULL LOOP
      l_result(l_index) := to_public_record(
        p_members(l_index),
        p_store_public_id
      );
      l_index := p_members.NEXT(l_index);
    END LOOP;
    RETURN l_result;
  END to_public_table;

  FUNCTION resolve_account(
    p_account_public_id IN BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE
  ) RETURN BEX_ACCOUNT%ROWTYPE IS
  BEGIN
    RETURN acc_service_pkg.require_by_public_id(p_account_public_id);
  EXCEPTION
    WHEN acc_service_pkg.e_account_not_found THEN
      RAISE e_account_not_found;
  END resolve_account;

  FUNCTION require_member(
    p_store_id             IN BEX_STORE_USER.STR_ID%TYPE,
    p_store_user_public_id IN BEX_STORE_USER.STU_PUBLIC_ID%TYPE
  ) RETURN stu_repository_pkg.t_store_user_record IS
    l_member stu_repository_pkg.t_store_user_record;
  BEGIN
    l_member := stu_repository_pkg.get_by_public_id(
      p_store_user_public_id
    );
    IF l_member.str_id <> p_store_id THEN
      RAISE e_member_not_found;
    END IF;
    RETURN l_member;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE e_member_not_found;
  END require_member;

  FUNCTION normalize_valid_role(
    p_role_code IN BEX_STORE_USER.STU_ROLE_CODE%TYPE
  ) RETURN BEX_STORE_USER.STU_ROLE_CODE%TYPE IS
    l_role BEX_STORE_USER.STU_ROLE_CODE%TYPE;
  BEGIN
    l_role := stu_rule_pkg.normalize_role(p_role_code);
    stu_rule_pkg.require_valid_role(l_role);
    RETURN l_role;
  EXCEPTION
    WHEN stu_rule_pkg.e_invalid_role THEN
      RAISE e_invalid_role;
  END normalize_valid_role;

  FUNCTION normalize_valid_status(
    p_status IN BEX_STORE_USER.STU_STATUS%TYPE
  ) RETURN BEX_STORE_USER.STU_STATUS%TYPE IS
    l_status BEX_STORE_USER.STU_STATUS%TYPE;
  BEGIN
    l_status := stu_rule_pkg.normalize_status(p_status);
    stu_rule_pkg.require_valid_status(l_status);
    RETURN l_status;
  EXCEPTION
    WHEN stu_rule_pkg.e_invalid_status THEN
      RAISE e_invalid_status;
  END normalize_valid_status;

  FUNCTION is_active_admin(
    p_store_id   IN BEX_STORE_USER.STR_ID%TYPE,
    p_account_id IN BEX_STORE_USER.ACC_ID%TYPE
  ) RETURN BOOLEAN IS
  BEGIN
    RETURN stu_repository_pkg.active_admin_exists(
      p_store_id,
      p_account_id
    );
  END is_active_admin;

  FUNCTION count_active_admins(
    p_store_id IN BEX_STORE_USER.STR_ID%TYPE
  ) RETURN PLS_INTEGER IS
  BEGIN
    RETURN stu_repository_pkg.count_active_admins(p_store_id);
  END count_active_admins;

  FUNCTION is_admin_role(
    p_role_code IN BEX_STORE_USER.STU_ROLE_CODE%TYPE
  ) RETURN BOOLEAN IS
  BEGIN
    RETURN normalize_valid_role(p_role_code) = stu_rule_pkg.c_role_admin;
  END is_admin_role;

  FUNCTION create_member(
    p_store_id          IN BEX_STORE_USER.STR_ID%TYPE,
    p_store_public_id   IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_account_public_id IN BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE,
    p_role_code         IN BEX_STORE_USER.STU_ROLE_CODE%TYPE,
    p_actor_id          IN BEX_ACCOUNT.ACC_ID%TYPE
  ) RETURN t_member_record IS
    l_account   BEX_ACCOUNT%ROWTYPE;
    l_role      BEX_STORE_USER.STU_ROLE_CODE%TYPE;
    l_public_id BEX_STORE_USER.STU_PUBLIC_ID%TYPE;
    l_member_id BEX_STORE_USER.STU_ID%TYPE;
    l_member    stu_repository_pkg.t_store_user_record;
    l_inserted  BOOLEAN := FALSE;
  BEGIN
    l_role := normalize_valid_role(p_role_code);
    l_account := resolve_account(p_account_public_id);

    IF stu_repository_pkg.active_link_exists(
         p_store_id,
         l_account.ACC_ID
       ) THEN
      RAISE e_active_link_exists;
    END IF;

    FOR i IN 1..c_public_id_attempts LOOP
      l_public_id := generate_public_id;
      IF stu_repository_pkg.public_id_exists(l_public_id) THEN
        CONTINUE;
      END IF;

      BEGIN
        stu_repository_pkg.insert_store_user(
          p_public_id     => l_public_id,
          p_store_id      => p_store_id,
          p_account_id    => l_account.ACC_ID,
          p_role_code     => l_role,
          p_status        => stu_rule_pkg.c_status_active,
          p_joined_at     => SYSTIMESTAMP,
          p_created_by    => p_actor_id,
          o_store_user_id => l_member_id
        );
        l_inserted := TRUE;
        EXIT;
      EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
          IF stu_repository_pkg.active_link_exists(
               p_store_id,
               l_account.ACC_ID
             ) THEN
            RAISE e_active_link_exists;
          ELSIF i = c_public_id_attempts THEN
            RAISE;
          END IF;
      END;
    END LOOP;

    IF NOT l_inserted THEN
      RAISE DUP_VAL_ON_INDEX;
    END IF;

    l_member := stu_repository_pkg.get_by_id(l_member_id);
    RETURN to_public_record(l_member, p_store_public_id);
  END create_member;

  FUNCTION change_role(
    p_store_id             IN BEX_STORE_USER.STR_ID%TYPE,
    p_store_public_id      IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_store_user_public_id IN BEX_STORE_USER.STU_PUBLIC_ID%TYPE,
    p_role_code            IN BEX_STORE_USER.STU_ROLE_CODE%TYPE,
    p_actor_id             IN BEX_ACCOUNT.ACC_ID%TYPE
  ) RETURN t_member_record IS
    l_member  stu_repository_pkg.t_store_user_record;
    l_role    BEX_STORE_USER.STU_ROLE_CODE%TYPE;
    l_updated BOOLEAN;
  BEGIN
    l_role := normalize_valid_role(p_role_code);
    l_member := require_member(p_store_id, p_store_user_public_id);

    stu_repository_pkg.update_role(
      p_store_user_id => l_member.stu_id,
      p_role_code     => l_role,
      p_updated_at    => SYSTIMESTAMP,
      p_updated_by    => p_actor_id,
      o_updated       => l_updated
    );

    IF l_updated IS NULL OR NOT l_updated THEN
      RAISE e_member_not_found;
    END IF;

    l_member := require_member(p_store_id, p_store_user_public_id);
    RETURN to_public_record(l_member, p_store_public_id);
  END change_role;

  FUNCTION change_status(
    p_store_id             IN BEX_STORE_USER.STR_ID%TYPE,
    p_store_public_id      IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_store_user_public_id IN BEX_STORE_USER.STU_PUBLIC_ID%TYPE,
    p_new_status           IN BEX_STORE_USER.STU_STATUS%TYPE,
    p_left_at              IN BEX_STORE_USER.STU_LEFT_AT%TYPE,
    p_actor_id             IN BEX_ACCOUNT.ACC_ID%TYPE
  ) RETURN t_member_record IS
    l_member  stu_repository_pkg.t_store_user_record;
    l_updated BOOLEAN;
  BEGIN
    l_member := require_member(p_store_id, p_store_user_public_id);

    BEGIN
      stu_rule_pkg.validate_transition(
        l_member.stu_status,
        p_new_status
      );
    EXCEPTION
      WHEN stu_rule_pkg.e_invalid_status THEN
        RAISE e_invalid_status;
      WHEN stu_rule_pkg.e_invalid_transition THEN
        RAISE e_invalid_transition;
    END;

    BEGIN
      stu_repository_pkg.update_status(
        p_store_user_id => l_member.stu_id,
        p_status        => p_new_status,
        p_left_at       => p_left_at,
        p_updated_at    => SYSTIMESTAMP,
        p_updated_by    => p_actor_id,
        o_updated       => l_updated
      );
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        RAISE e_active_link_exists;
    END;

    IF l_updated IS NULL OR NOT l_updated THEN
      RAISE e_member_not_found;
    END IF;

    l_member := require_member(p_store_id, p_store_user_public_id);
    RETURN to_public_record(l_member, p_store_public_id);
  END change_status;

  FUNCTION activate_member(
    p_store_id             IN BEX_STORE_USER.STR_ID%TYPE,
    p_store_public_id      IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_store_user_public_id IN BEX_STORE_USER.STU_PUBLIC_ID%TYPE,
    p_actor_id             IN BEX_ACCOUNT.ACC_ID%TYPE
  ) RETURN t_member_record IS
  BEGIN
    RETURN change_status(
      p_store_id,
      p_store_public_id,
      p_store_user_public_id,
      stu_rule_pkg.c_status_active,
      NULL,
      p_actor_id
    );
  END activate_member;

  FUNCTION deactivate_member(
    p_store_id             IN BEX_STORE_USER.STR_ID%TYPE,
    p_store_public_id      IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_store_user_public_id IN BEX_STORE_USER.STU_PUBLIC_ID%TYPE,
    p_actor_id             IN BEX_ACCOUNT.ACC_ID%TYPE
  ) RETURN t_member_record IS
  BEGIN
    RETURN change_status(
      p_store_id,
      p_store_public_id,
      p_store_user_public_id,
      stu_rule_pkg.c_status_inactive,
      SYSTIMESTAMP,
      p_actor_id
    );
  END deactivate_member;

  FUNCTION get_member(
    p_store_id             IN BEX_STORE_USER.STR_ID%TYPE,
    p_store_public_id      IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_store_user_public_id IN BEX_STORE_USER.STU_PUBLIC_ID%TYPE
  ) RETURN t_member_record IS
  BEGIN
    RETURN to_public_record(
      require_member(p_store_id, p_store_user_public_id),
      p_store_public_id
    );
  END get_member;

  FUNCTION list_members_by_store(
    p_store_id        IN BEX_STORE_USER.STR_ID%TYPE,
    p_store_public_id IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_status          IN BEX_STORE_USER.STU_STATUS%TYPE DEFAULT NULL,
    p_role_code       IN BEX_STORE_USER.STU_ROLE_CODE%TYPE DEFAULT NULL
  ) RETURN t_member_table IS
    l_status BEX_STORE_USER.STU_STATUS%TYPE;
    l_role   BEX_STORE_USER.STU_ROLE_CODE%TYPE;
  BEGIN
    IF p_status IS NOT NULL THEN
      l_status := normalize_valid_status(p_status);
    END IF;
    IF p_role_code IS NOT NULL THEN
      l_role := normalize_valid_role(p_role_code);
    END IF;

    RETURN to_public_table(
      stu_repository_pkg.list_by_store(
        p_store_id,
        l_status,
        l_role
      ),
      p_store_public_id
    );
  END list_members_by_store;
END stu_service_pkg;
/
