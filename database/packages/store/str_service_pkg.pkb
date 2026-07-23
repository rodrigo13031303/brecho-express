CREATE OR REPLACE PACKAGE BODY str_service_pkg AS
  c_public_id_attempts CONSTANT PLS_INTEGER := 3;

  FUNCTION generate_public_id RETURN BEX_STORE.STR_PUBLIC_ID%TYPE IS
  BEGIN
    RETURN LOWER(RAWTOHEX(SYS_GUID()));
  END generate_public_id;

  FUNCTION to_public_record(
    p_store IN str_repository_pkg.t_store_record
  ) RETURN t_store_record IS
    l_result t_store_record;
  BEGIN
    l_result.store_public_id := p_store.str_public_id;
    l_result.store_name := p_store.str_name;
    l_result.store_slug := p_store.str_slug;
    l_result.description := p_store.str_description;
    l_result.status := p_store.str_status;
    l_result.logo_url := p_store.str_logo_url;
    l_result.cover_url := p_store.str_cover_url;
    l_result.locale_code := p_store.str_locale_code;
    l_result.timezone_name := p_store.str_timezone_name;
    l_result.created_at := p_store.str_created_at;
    l_result.updated_at := p_store.str_updated_at;
    RETURN l_result;
  END to_public_record;

  FUNCTION to_public_table(
    p_stores IN str_repository_pkg.t_store_table
  ) RETURN t_store_table IS
    l_result t_store_table;
    l_index  PLS_INTEGER;
  BEGIN
    l_index := p_stores.FIRST;
    WHILE l_index IS NOT NULL LOOP
      l_result(l_index) := to_public_record(p_stores(l_index));
      l_index := p_stores.NEXT(l_index);
    END LOOP;
    RETURN l_result;
  END to_public_table;

  FUNCTION to_member_record(
    p_member IN stu_service_pkg.t_member_record
  ) RETURN t_member_record IS
    l_result t_member_record;
  BEGIN
    l_result.store_user_public_id := p_member.store_user_public_id;
    l_result.store_public_id := p_member.store_public_id;
    l_result.account_public_id := p_member.account_public_id;
    l_result.role_code := p_member.role_code;
    l_result.status := p_member.status;
    l_result.joined_at := p_member.joined_at;
    l_result.left_at := p_member.left_at;
    l_result.created_at := p_member.created_at;
    l_result.updated_at := p_member.updated_at;
    RETURN l_result;
  END to_member_record;

  FUNCTION to_member_table(
    p_members IN stu_service_pkg.t_member_table
  ) RETURN t_member_table IS
    l_result t_member_table;
    l_index  PLS_INTEGER;
  BEGIN
    l_index := p_members.FIRST;
    WHILE l_index IS NOT NULL LOOP
      l_result(l_index) := to_member_record(p_members(l_index));
      l_index := p_members.NEXT(l_index);
    END LOOP;
    RETURN l_result;
  END to_member_table;

  FUNCTION to_rule_patch(
    p_patch IN t_store_patch
  ) RETURN str_rule_pkg.t_store_patch IS
    l_result str_rule_pkg.t_store_patch;
  BEGIN
    l_result.set_name := p_patch.set_name;
    l_result.name_value := p_patch.name_value;
    l_result.set_slug := p_patch.set_slug;
    l_result.slug_value := p_patch.slug_value;
    l_result.set_description := p_patch.set_description;
    l_result.description_value := p_patch.description_value;
    l_result.set_logo_url := p_patch.set_logo_url;
    l_result.logo_url_value := p_patch.logo_url_value;
    l_result.set_cover_url := p_patch.set_cover_url;
    l_result.cover_url_value := p_patch.cover_url_value;
    l_result.set_locale_code := p_patch.set_locale_code;
    l_result.locale_code_value := p_patch.locale_code_value;
    l_result.set_timezone_name := p_patch.set_timezone_name;
    l_result.timezone_value := p_patch.timezone_value;
    RETURN l_result;
  END to_rule_patch;

  PROCEDURE assert_found(
    p_store IN str_repository_pkg.t_store_record
  ) IS
  BEGIN
    IF p_store.str_id IS NULL THEN
      RAISE e_store_not_found;
    END IF;
  END assert_found;

  FUNCTION require_internal_store(
    p_store_public_id IN BEX_STORE.STR_PUBLIC_ID%TYPE
  ) RETURN str_repository_pkg.t_store_record IS
    l_store str_repository_pkg.t_store_record;
  BEGIN
    l_store := str_repository_pkg.get_by_public_id(p_store_public_id);
    assert_found(l_store);
    RETURN l_store;
  END require_internal_store;

  PROCEDURE assert_member_manager(
    p_store    IN str_repository_pkg.t_store_record,
    p_actor_id IN BEX_ACCOUNT.ACC_ID%TYPE
  ) IS
  BEGIN
    IF p_actor_id IS NULL OR p_actor_id <= 0 THEN
      RAISE e_member_forbidden;
    END IF;

    IF p_store.acc_id = p_actor_id THEN
      RETURN;
    END IF;

    IF stu_service_pkg.is_active_admin(p_store.str_id, p_actor_id) THEN
      RETURN;
    END IF;

    RAISE e_member_forbidden;
  END assert_member_manager;

  FUNCTION require_authorized_store(
    p_store_public_id IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_actor_id        IN BEX_ACCOUNT.ACC_ID%TYPE,
    p_lock            IN BOOLEAN
  ) RETURN str_repository_pkg.t_store_record IS
    l_store str_repository_pkg.t_store_record;
  BEGIN
    l_store := require_internal_store(p_store_public_id);
    IF p_lock THEN
      str_repository_pkg.lock_by_id(l_store.str_id);
      l_store := str_repository_pkg.get_by_id(l_store.str_id);
    END IF;
    assert_member_manager(l_store, p_actor_id);
    RETURN l_store;
  END require_authorized_store;

  FUNCTION resolve_account(
    p_account_public_id IN BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE
  ) RETURN BEX_ACCOUNT%ROWTYPE IS
  BEGIN
    RETURN acc_service_pkg.require_by_public_id(
      p_public_id => p_account_public_id
    );
  EXCEPTION
    WHEN acc_service_pkg.e_account_not_found THEN
      RAISE e_account_not_found;
  END resolve_account;

  FUNCTION create_by_account_public_id(
    p_account_public_id IN BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE,
    p_name              IN BEX_STORE.STR_NAME%TYPE,
    p_slug              IN BEX_STORE.STR_SLUG%TYPE,
    p_description       IN BEX_STORE.STR_DESCRIPTION%TYPE DEFAULT NULL,
    p_logo_url          IN BEX_STORE.STR_LOGO_URL%TYPE DEFAULT NULL,
    p_cover_url         IN BEX_STORE.STR_COVER_URL%TYPE DEFAULT NULL,
    p_locale_code       IN BEX_STORE.STR_LOCALE_CODE%TYPE DEFAULT NULL,
    p_timezone_name     IN BEX_STORE.STR_TIMEZONE_NAME%TYPE DEFAULT NULL,
    p_audit_actor_id    IN BEX_STORE.STR_CREATED_BY%TYPE DEFAULT NULL
  ) RETURN t_store_record IS
    l_account   BEX_ACCOUNT%ROWTYPE;
    l_creation  str_rule_pkg.t_store_creation;
    l_public_id BEX_STORE.STR_PUBLIC_ID%TYPE;
    l_store_id  BEX_STORE.STR_ID%TYPE;
    l_store     str_repository_pkg.t_store_record;
    l_inserted  BOOLEAN := FALSE;
  BEGIN
    l_account := resolve_account(p_account_public_id);
    str_rule_pkg.assert_account_eligible(
      p_account_exists => l_account.ACC_ID IS NOT NULL,
      p_account_status => l_account.ACC_STATUS
    );

    l_creation.name_value := p_name;
    l_creation.slug_value := p_slug;
    l_creation.description_value := p_description;
    l_creation.logo_url_value := p_logo_url;
    l_creation.cover_url_value := p_cover_url;
    l_creation.locale_code_value := p_locale_code;
    l_creation.timezone_value := p_timezone_name;
    l_creation.status_value := NULL;
    str_rule_pkg.normalize_and_validate_creation(l_creation);

    IF str_repository_pkg.slug_exists(l_creation.slug_value) THEN
      RAISE str_rule_pkg.e_slug_already_used;
    END IF;

    FOR i IN 1..c_public_id_attempts LOOP
      l_public_id := generate_public_id;
      IF str_repository_pkg.public_id_exists(l_public_id) THEN
        CONTINUE;
      END IF;

      BEGIN
        str_repository_pkg.insert_store(
          p_public_id     => l_public_id,
          p_account_id    => l_account.ACC_ID,
          p_name          => l_creation.name_value,
          p_slug          => l_creation.slug_value,
          p_description   => l_creation.description_value,
          p_status        => l_creation.status_value,
          p_logo_url      => l_creation.logo_url_value,
          p_cover_url     => l_creation.cover_url_value,
          p_locale_code   => l_creation.locale_code_value,
          p_timezone_name => l_creation.timezone_value,
          p_created_by    => p_audit_actor_id,
          p_updated_by    => p_audit_actor_id,
          o_store_id      => l_store_id
        );
        l_inserted := TRUE;
        EXIT;
      EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
          IF str_repository_pkg.slug_exists(l_creation.slug_value) THEN
            RAISE str_rule_pkg.e_slug_already_used;
          ELSIF i = c_public_id_attempts THEN
            RAISE;
          END IF;
      END;
    END LOOP;

    IF NOT l_inserted THEN
      RAISE DUP_VAL_ON_INDEX;
    END IF;

    l_store := str_repository_pkg.get_by_public_id(l_public_id);
    assert_found(l_store);
    RETURN to_public_record(l_store);
  EXCEPTION
    WHEN str_rule_pkg.e_name_required THEN
      RAISE e_name_required;
    WHEN str_rule_pkg.e_invalid_name THEN
      RAISE e_invalid_name;
    WHEN str_rule_pkg.e_slug_required THEN
      RAISE e_slug_required;
    WHEN str_rule_pkg.e_invalid_slug THEN
      RAISE e_invalid_slug;
    WHEN str_rule_pkg.e_invalid_description THEN
      RAISE e_invalid_description;
    WHEN str_rule_pkg.e_invalid_logo_url THEN
      RAISE e_invalid_logo_url;
    WHEN str_rule_pkg.e_invalid_cover_url THEN
      RAISE e_invalid_cover_url;
    WHEN str_rule_pkg.e_invalid_locale THEN
      RAISE e_invalid_locale;
    WHEN str_rule_pkg.e_invalid_timezone THEN
      RAISE e_invalid_timezone;
    WHEN str_rule_pkg.e_invalid_status THEN
      RAISE e_invalid_status;
    WHEN str_rule_pkg.e_account_ineligible THEN
      RAISE e_account_ineligible;
    WHEN str_rule_pkg.e_slug_already_used THEN
      RAISE e_slug_already_used;
  END create_by_account_public_id;

  FUNCTION get_by_public_id(
    p_store_public_id IN BEX_STORE.STR_PUBLIC_ID%TYPE
  ) RETURN t_store_record IS
  BEGIN
    RETURN to_public_record(
      str_repository_pkg.get_by_public_id(p_store_public_id)
    );
  END get_by_public_id;

  FUNCTION require_by_public_id(
    p_store_public_id IN BEX_STORE.STR_PUBLIC_ID%TYPE
  ) RETURN t_store_record IS
    l_store str_repository_pkg.t_store_record;
  BEGIN
    l_store := str_repository_pkg.get_by_public_id(p_store_public_id);
    assert_found(l_store);
    RETURN to_public_record(l_store);
  END require_by_public_id;

  FUNCTION get_store_by_id(
    p_store_id IN BEX_STORE.STR_ID%TYPE
  ) RETURN t_store_record IS
    l_store str_repository_pkg.t_store_record;
  BEGIN
    l_store := str_repository_pkg.get_by_id(p_store_id);
    RETURN to_public_record(l_store);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE e_store_not_found;
  END get_store_by_id;

  FUNCTION resolve_store_id(
    p_store_public_id IN BEX_STORE.STR_PUBLIC_ID%TYPE
  ) RETURN BEX_STORE.STR_ID%TYPE IS
    l_store str_repository_pkg.t_store_record;
  BEGIN
    l_store := str_repository_pkg.get_by_public_id(p_store_public_id);
    assert_found(l_store);
    RETURN l_store.str_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE e_store_not_found;
  END resolve_store_id;

  FUNCTION get_by_slug(
    p_slug IN BEX_STORE.STR_SLUG%TYPE
  ) RETURN t_store_record IS
    l_slug BEX_STORE.STR_SLUG%TYPE;
  BEGIN
    l_slug := str_rule_pkg.normalize_slug(p_slug);
    str_rule_pkg.validate_slug(l_slug);
    RETURN to_public_record(str_repository_pkg.get_by_slug(l_slug));
  EXCEPTION
    WHEN str_rule_pkg.e_slug_required THEN
      RAISE e_slug_required;
    WHEN str_rule_pkg.e_invalid_slug THEN
      RAISE e_invalid_slug;
  END get_by_slug;

  FUNCTION require_by_slug(
    p_slug IN BEX_STORE.STR_SLUG%TYPE
  ) RETURN t_store_record IS
    l_slug  BEX_STORE.STR_SLUG%TYPE;
    l_store str_repository_pkg.t_store_record;
  BEGIN
    l_slug := str_rule_pkg.normalize_slug(p_slug);
    str_rule_pkg.validate_slug(l_slug);
    l_store := str_repository_pkg.get_by_slug(l_slug);
    assert_found(l_store);
    RETURN to_public_record(l_store);
  EXCEPTION
    WHEN str_rule_pkg.e_slug_required THEN
      RAISE e_slug_required;
    WHEN str_rule_pkg.e_invalid_slug THEN
      RAISE e_invalid_slug;
  END require_by_slug;

  FUNCTION list_by_account_public_id(
    p_account_public_id IN BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE
  ) RETURN t_store_table IS
    l_account BEX_ACCOUNT%ROWTYPE;
  BEGIN
    l_account := resolve_account(p_account_public_id);
    RETURN to_public_table(
      str_repository_pkg.list_by_account(l_account.ACC_ID)
    );
  END list_by_account_public_id;

  FUNCTION update_by_public_id(
    p_store_public_id IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_patch           IN t_store_patch,
    p_audit_actor_id  IN BEX_STORE.STR_UPDATED_BY%TYPE DEFAULT NULL
  ) RETURN t_store_record IS
    l_store   str_repository_pkg.t_store_record;
    l_patch   str_rule_pkg.t_store_patch;
    l_updated BOOLEAN;
  BEGIN
    l_store := str_repository_pkg.get_by_public_id(p_store_public_id);
    assert_found(l_store);
    l_patch := to_rule_patch(p_patch);
    str_rule_pkg.normalize_and_validate_patch(
      p_current_status => l_store.str_status,
      p_current_slug   => l_store.str_slug,
      io_patch         => l_patch
    );

    IF l_patch.set_slug
       AND l_patch.slug_value <> l_store.str_slug
       AND str_repository_pkg.slug_exists(l_patch.slug_value) THEN
      RAISE str_rule_pkg.e_slug_already_used;
    END IF;

    BEGIN
      str_repository_pkg.update_store(
        p_store_id          => l_store.str_id,
        p_set_name          => l_patch.set_name,
        p_name              => l_patch.name_value,
        p_set_slug          => l_patch.set_slug,
        p_slug              => l_patch.slug_value,
        p_set_description   => l_patch.set_description,
        p_description       => l_patch.description_value,
        p_set_logo_url      => l_patch.set_logo_url,
        p_logo_url          => l_patch.logo_url_value,
        p_set_cover_url     => l_patch.set_cover_url,
        p_cover_url         => l_patch.cover_url_value,
        p_set_locale_code   => l_patch.set_locale_code,
        p_locale_code       => l_patch.locale_code_value,
        p_set_timezone_name => l_patch.set_timezone_name,
        p_timezone_name     => l_patch.timezone_value,
        p_updated_at        => SYSTIMESTAMP,
        p_updated_by        => p_audit_actor_id,
        o_updated           => l_updated
      );
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        RAISE str_rule_pkg.e_slug_already_used;
    END;

    IF l_updated IS NULL OR NOT l_updated THEN
      RAISE e_store_not_found;
    END IF;
    l_store := str_repository_pkg.get_by_public_id(p_store_public_id);
    assert_found(l_store);
    RETURN to_public_record(l_store);
  EXCEPTION
    WHEN str_rule_pkg.e_name_required THEN
      RAISE e_name_required;
    WHEN str_rule_pkg.e_invalid_name THEN
      RAISE e_invalid_name;
    WHEN str_rule_pkg.e_slug_required THEN
      RAISE e_slug_required;
    WHEN str_rule_pkg.e_invalid_slug THEN
      RAISE e_invalid_slug;
    WHEN str_rule_pkg.e_invalid_description THEN
      RAISE e_invalid_description;
    WHEN str_rule_pkg.e_invalid_logo_url THEN
      RAISE e_invalid_logo_url;
    WHEN str_rule_pkg.e_invalid_cover_url THEN
      RAISE e_invalid_cover_url;
    WHEN str_rule_pkg.e_invalid_locale THEN
      RAISE e_invalid_locale;
    WHEN str_rule_pkg.e_invalid_timezone THEN
      RAISE e_invalid_timezone;
    WHEN str_rule_pkg.e_invalid_status THEN
      RAISE e_invalid_status;
    WHEN str_rule_pkg.e_empty_patch THEN
      RAISE e_empty_patch;
    WHEN str_rule_pkg.e_slug_not_editable THEN
      RAISE e_slug_not_editable;
    WHEN str_rule_pkg.e_store_closed THEN
      RAISE e_store_closed;
    WHEN str_rule_pkg.e_slug_already_used THEN
      RAISE e_slug_already_used;
  END update_by_public_id;

  FUNCTION change_status(
    p_store_public_id IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_new_status      IN BEX_STORE.STR_STATUS%TYPE,
    p_audit_actor_id  IN BEX_STORE.STR_UPDATED_BY%TYPE
  ) RETURN t_store_record IS
    l_store   str_repository_pkg.t_store_record;
    l_updated BOOLEAN;
  BEGIN
    l_store := str_repository_pkg.get_by_public_id(p_store_public_id);
    assert_found(l_store);
    str_rule_pkg.validate_status_transition(l_store.str_status, p_new_status);
    str_repository_pkg.update_status(
      p_store_id   => l_store.str_id,
      p_status     => p_new_status,
      p_updated_at => SYSTIMESTAMP,
      p_updated_by => p_audit_actor_id,
      o_updated    => l_updated
    );
    IF l_updated IS NULL OR NOT l_updated THEN
      RAISE e_store_not_found;
    END IF;
    l_store := str_repository_pkg.get_by_public_id(p_store_public_id);
    assert_found(l_store);
    RETURN to_public_record(l_store);
  END change_status;

  FUNCTION activate_by_public_id(
    p_store_public_id IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_audit_actor_id  IN BEX_STORE.STR_UPDATED_BY%TYPE DEFAULT NULL
  ) RETURN t_store_record IS
  BEGIN
    RETURN change_status(
      p_store_public_id,
      str_rule_pkg.c_status_active,
      p_audit_actor_id
    );
  EXCEPTION
    WHEN str_rule_pkg.e_invalid_status THEN
      RAISE e_invalid_status;
    WHEN str_rule_pkg.e_invalid_transition THEN
      RAISE e_invalid_transition;
  END activate_by_public_id;

  FUNCTION close_by_public_id(
    p_store_public_id IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_audit_actor_id  IN BEX_STORE.STR_UPDATED_BY%TYPE DEFAULT NULL
  ) RETURN t_store_record IS
  BEGIN
    RETURN change_status(
      p_store_public_id,
      str_rule_pkg.c_status_closed,
      p_audit_actor_id
    );
  EXCEPTION
    WHEN str_rule_pkg.e_invalid_status THEN
      RAISE e_invalid_status;
    WHEN str_rule_pkg.e_invalid_transition THEN
      RAISE e_invalid_transition;
  END close_by_public_id;

  FUNCTION slug_available(
    p_slug IN BEX_STORE.STR_SLUG%TYPE
  ) RETURN BOOLEAN IS
    l_slug BEX_STORE.STR_SLUG%TYPE;
  BEGIN
    l_slug := str_rule_pkg.normalize_slug(p_slug);
    str_rule_pkg.validate_slug(l_slug);
    RETURN NOT str_repository_pkg.slug_exists(l_slug);
  EXCEPTION
    WHEN str_rule_pkg.e_slug_required THEN
      RAISE e_slug_required;
    WHEN str_rule_pkg.e_invalid_slug THEN
      RAISE e_invalid_slug;
  END slug_available;

  FUNCTION add_member(
    p_store_public_id   IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_account_public_id IN BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE,
    p_role_code         IN BEX_STORE_USER.STU_ROLE_CODE%TYPE,
    p_actor_id          IN BEX_ACCOUNT.ACC_ID%TYPE
  ) RETURN t_member_record IS
    l_store  str_repository_pkg.t_store_record;
    l_member stu_service_pkg.t_member_record;
  BEGIN
    l_store := require_authorized_store(
      p_store_public_id,
      p_actor_id,
      TRUE
    );
    l_member := stu_service_pkg.create_member(
      l_store.str_id,
      l_store.str_public_id,
      p_account_public_id,
      p_role_code,
      p_actor_id
    );
    RETURN to_member_record(l_member);
  EXCEPTION
    WHEN stu_service_pkg.e_account_not_found THEN
      RAISE e_account_not_found;
    WHEN stu_service_pkg.e_invalid_role THEN
      RAISE e_member_invalid_role;
    WHEN stu_service_pkg.e_active_link_exists THEN
      RAISE e_active_member_link_exists;
  END add_member;

  FUNCTION get_member(
    p_store_public_id      IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_store_user_public_id IN BEX_STORE_USER.STU_PUBLIC_ID%TYPE,
    p_actor_id             IN BEX_ACCOUNT.ACC_ID%TYPE
  ) RETURN t_member_record IS
    l_store  str_repository_pkg.t_store_record;
    l_member stu_service_pkg.t_member_record;
  BEGIN
    l_store := require_authorized_store(
      p_store_public_id,
      p_actor_id,
      FALSE
    );
    l_member := stu_service_pkg.get_member(
      l_store.str_id,
      l_store.str_public_id,
      p_store_user_public_id
    );
    RETURN to_member_record(l_member);
  EXCEPTION
    WHEN stu_service_pkg.e_member_not_found THEN
      RAISE e_member_not_found;
  END get_member;

  FUNCTION list_members(
    p_store_public_id IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_actor_id        IN BEX_ACCOUNT.ACC_ID%TYPE,
    p_status          IN BEX_STORE_USER.STU_STATUS%TYPE DEFAULT NULL,
    p_role_code       IN BEX_STORE_USER.STU_ROLE_CODE%TYPE DEFAULT NULL
  ) RETURN t_member_table IS
    l_store   str_repository_pkg.t_store_record;
    l_members stu_service_pkg.t_member_table;
  BEGIN
    l_store := require_authorized_store(
      p_store_public_id,
      p_actor_id,
      FALSE
    );
    l_members := stu_service_pkg.list_members_by_store(
      l_store.str_id,
      l_store.str_public_id,
      p_status,
      p_role_code
    );
    RETURN to_member_table(l_members);
  EXCEPTION
    WHEN stu_service_pkg.e_invalid_status THEN
      RAISE e_member_invalid_status;
    WHEN stu_service_pkg.e_invalid_role THEN
      RAISE e_member_invalid_role;
  END list_members;

  FUNCTION change_member_role(
    p_store_public_id      IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_store_user_public_id IN BEX_STORE_USER.STU_PUBLIC_ID%TYPE,
    p_role_code            IN BEX_STORE_USER.STU_ROLE_CODE%TYPE,
    p_actor_id             IN BEX_ACCOUNT.ACC_ID%TYPE
  ) RETURN t_member_record IS
    l_store        str_repository_pkg.t_store_record;
    l_current      stu_service_pkg.t_member_record;
    l_member       stu_service_pkg.t_member_record;
    l_is_admin     BOOLEAN;
  BEGIN
    l_store := require_authorized_store(
      p_store_public_id,
      p_actor_id,
      TRUE
    );

    BEGIN
      l_is_admin := stu_service_pkg.is_admin_role(p_role_code);
      l_current := stu_service_pkg.get_member(
        l_store.str_id,
        l_store.str_public_id,
        p_store_user_public_id
      );
    EXCEPTION
      WHEN stu_service_pkg.e_invalid_role THEN
        RAISE e_member_invalid_role;
      WHEN stu_service_pkg.e_member_not_found THEN
        RAISE e_member_not_found;
    END;

    IF l_current.status = 'ACTIVE'
       AND l_current.role_code = 'ADMIN'
       AND NOT l_is_admin
       AND stu_service_pkg.count_active_admins(l_store.str_id) = 1 THEN
      RAISE e_last_admin_required;
    END IF;

    l_member := stu_service_pkg.change_role(
      l_store.str_id,
      l_store.str_public_id,
      p_store_user_public_id,
      p_role_code,
      p_actor_id
    );
    RETURN to_member_record(l_member);
  EXCEPTION
    WHEN stu_service_pkg.e_invalid_role THEN
      RAISE e_member_invalid_role;
    WHEN stu_service_pkg.e_member_not_found THEN
      RAISE e_member_not_found;
  END change_member_role;

  FUNCTION activate_member(
    p_store_public_id      IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_store_user_public_id IN BEX_STORE_USER.STU_PUBLIC_ID%TYPE,
    p_actor_id             IN BEX_ACCOUNT.ACC_ID%TYPE
  ) RETURN t_member_record IS
    l_store  str_repository_pkg.t_store_record;
    l_member stu_service_pkg.t_member_record;
  BEGIN
    l_store := require_authorized_store(
      p_store_public_id,
      p_actor_id,
      TRUE
    );
    l_member := stu_service_pkg.activate_member(
      l_store.str_id,
      l_store.str_public_id,
      p_store_user_public_id,
      p_actor_id
    );
    RETURN to_member_record(l_member);
  EXCEPTION
    WHEN stu_service_pkg.e_member_not_found THEN
      RAISE e_member_not_found;
    WHEN stu_service_pkg.e_invalid_status THEN
      RAISE e_member_invalid_status;
    WHEN stu_service_pkg.e_invalid_transition THEN
      RAISE e_member_invalid_transition;
    WHEN stu_service_pkg.e_active_link_exists THEN
      RAISE e_active_member_link_exists;
  END activate_member;

  FUNCTION deactivate_member(
    p_store_public_id      IN BEX_STORE.STR_PUBLIC_ID%TYPE,
    p_store_user_public_id IN BEX_STORE_USER.STU_PUBLIC_ID%TYPE,
    p_actor_id             IN BEX_ACCOUNT.ACC_ID%TYPE
  ) RETURN t_member_record IS
    l_store   str_repository_pkg.t_store_record;
    l_current stu_service_pkg.t_member_record;
    l_member  stu_service_pkg.t_member_record;
  BEGIN
    l_store := require_authorized_store(
      p_store_public_id,
      p_actor_id,
      TRUE
    );

    BEGIN
      l_current := stu_service_pkg.get_member(
        l_store.str_id,
        l_store.str_public_id,
        p_store_user_public_id
      );
    EXCEPTION
      WHEN stu_service_pkg.e_member_not_found THEN
        RAISE e_member_not_found;
    END;

    IF l_current.status = 'ACTIVE'
       AND l_current.role_code = 'ADMIN'
       AND stu_service_pkg.count_active_admins(l_store.str_id) = 1 THEN
      RAISE e_last_admin_required;
    END IF;

    l_member := stu_service_pkg.deactivate_member(
      l_store.str_id,
      l_store.str_public_id,
      p_store_user_public_id,
      p_actor_id
    );
    RETURN to_member_record(l_member);
  EXCEPTION
    WHEN stu_service_pkg.e_member_not_found THEN
      RAISE e_member_not_found;
    WHEN stu_service_pkg.e_invalid_status THEN
      RAISE e_member_invalid_status;
    WHEN stu_service_pkg.e_invalid_transition THEN
      RAISE e_member_invalid_transition;
  END deactivate_member;
END str_service_pkg;
/
