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

  FUNCTION resolve_account(
    p_account_public_id IN BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE
  ) RETURN BEX_ACCOUNT%ROWTYPE IS
  BEGIN
    RETURN acc_service_pkg.require_by_public_id(
      p_public_id => p_account_public_id
    );
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

  FUNCTION get_by_slug(
    p_slug IN BEX_STORE.STR_SLUG%TYPE
  ) RETURN t_store_record IS
    l_slug BEX_STORE.STR_SLUG%TYPE;
  BEGIN
    l_slug := str_rule_pkg.normalize_slug(p_slug);
    str_rule_pkg.validate_slug(l_slug);
    RETURN to_public_record(str_repository_pkg.get_by_slug(l_slug));
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
  END close_by_public_id;

  FUNCTION slug_available(
    p_slug IN BEX_STORE.STR_SLUG%TYPE
  ) RETURN BOOLEAN IS
    l_slug BEX_STORE.STR_SLUG%TYPE;
  BEGIN
    l_slug := str_rule_pkg.normalize_slug(p_slug);
    str_rule_pkg.validate_slug(l_slug);
    RETURN NOT str_repository_pkg.slug_exists(l_slug);
  END slug_available;
END str_service_pkg;
/
