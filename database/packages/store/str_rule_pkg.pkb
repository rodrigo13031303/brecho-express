CREATE OR REPLACE PACKAGE BODY str_rule_pkg AS
  c_name_min_length        CONSTANT PLS_INTEGER := 2;
  c_name_max_length        CONSTANT PLS_INTEGER := 200;
  c_slug_max_length        CONSTANT PLS_INTEGER := 100;
  c_description_max_length CONSTANT PLS_INTEGER := 1000;
  c_url_max_length         CONSTANT PLS_INTEGER := 1000;
  c_locale_pt_br           CONSTANT VARCHAR2(10) := 'pt-BR';
  c_timezone_sao_paulo     CONSTANT VARCHAR2(64) := 'America/Sao_Paulo';

  FUNCTION is_true(p_value IN BOOLEAN) RETURN BOOLEAN IS
  BEGIN
    RETURN p_value IS NOT NULL AND p_value;
  END is_true;

  FUNCTION normalize_name(p_name IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    IF p_name IS NULL THEN
      RETURN NULL;
    END IF;
    RETURN REGEXP_REPLACE(TRIM(p_name), '[[:space:]]+', ' ');
  END normalize_name;

  FUNCTION normalize_slug(p_slug IN VARCHAR2) RETURN VARCHAR2 IS
    l_slug VARCHAR2(32767);
  BEGIN
    IF p_slug IS NULL THEN
      RETURN NULL;
    END IF;
    l_slug := LOWER(TRIM(p_slug));
    l_slug := TRANSLATE(
      l_slug,
      UNISTR(
        '\00E1\00E0\00E2\00E3\00E4' ||
        '\00E9\00E8\00EA\00EB' ||
        '\00ED\00EC\00EE\00EF' ||
        '\00F3\00F2\00F4\00F5\00F6' ||
        '\00FA\00F9\00FB\00FC' ||
        '\00E7\00F1'
      ),
      'aaaaaeeeeiiiiooooouuuucn'
    );
    l_slug := REGEXP_REPLACE(l_slug, '[[:space:]]+', '-');
    l_slug := REGEXP_REPLACE(l_slug, '[^a-z0-9-]', '');
    l_slug := REGEXP_REPLACE(l_slug, '-+', '-');
    l_slug := REGEXP_REPLACE(l_slug, '^-+|-+$', '');
    RETURN l_slug;
  END normalize_slug;

  FUNCTION normalize_optional_text(p_value IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN TRIM(p_value);
  END normalize_optional_text;

  FUNCTION normalize_url(p_url IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN TRIM(p_url);
  END normalize_url;

  FUNCTION normalize_status(p_status IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    RETURN UPPER(TRIM(p_status));
  END normalize_status;

  PROCEDURE validate_name(p_name IN VARCHAR2) IS
    l_name VARCHAR2(32767) := normalize_name(p_name);
  BEGIN
    IF l_name IS NULL THEN
      RAISE e_name_required;
    ELSIF LENGTH(l_name) < c_name_min_length
       OR LENGTH(l_name) > c_name_max_length THEN
      RAISE e_invalid_name;
    END IF;
  END validate_name;

  PROCEDURE validate_slug(p_slug IN VARCHAR2) IS
    l_slug VARCHAR2(32767) := normalize_slug(p_slug);
  BEGIN
    IF l_slug IS NULL THEN
      RAISE e_slug_required;
    ELSIF LENGTH(l_slug) > c_slug_max_length
       OR NOT REGEXP_LIKE(l_slug, '^[a-z0-9]+(-[a-z0-9]+)*$') THEN
      RAISE e_invalid_slug;
    END IF;
  END validate_slug;

  PROCEDURE validate_description(p_description IN VARCHAR2) IS
    l_description VARCHAR2(32767) := normalize_optional_text(p_description);
  BEGIN
    IF l_description IS NOT NULL
       AND LENGTH(l_description) > c_description_max_length THEN
      RAISE e_invalid_description;
    END IF;
  END validate_description;

  PROCEDURE validate_url(
    p_url       IN VARCHAR2,
    p_is_logo   IN BOOLEAN
  ) IS
    l_url VARCHAR2(32767) := normalize_url(p_url);
  BEGIN
    IF l_url IS NOT NULL
       AND (
         LENGTH(l_url) > c_url_max_length
         OR NOT REGEXP_LIKE(l_url, '^https?://[^[:space:]]+$', 'i')
       ) THEN
      IF p_is_logo THEN
        RAISE e_invalid_logo_url;
      ELSE
        RAISE e_invalid_cover_url;
      END IF;
    END IF;
  END validate_url;

  PROCEDURE validate_logo_url(p_logo_url IN VARCHAR2) IS
  BEGIN
    validate_url(p_logo_url, TRUE);
  END validate_logo_url;

  PROCEDURE validate_cover_url(p_cover_url IN VARCHAR2) IS
  BEGIN
    validate_url(p_cover_url, FALSE);
  END validate_cover_url;

  PROCEDURE validate_locale_code(p_locale_code IN VARCHAR2) IS
  BEGIN
    IF TRIM(p_locale_code) IS NULL
       OR TRIM(p_locale_code) <> c_locale_pt_br THEN
      RAISE e_invalid_locale;
    END IF;
  END validate_locale_code;

  PROCEDURE validate_timezone_name(p_timezone_name IN VARCHAR2) IS
  BEGIN
    IF TRIM(p_timezone_name) IS NULL
       OR TRIM(p_timezone_name) <> c_timezone_sao_paulo THEN
      RAISE e_invalid_timezone;
    END IF;
  END validate_timezone_name;

  PROCEDURE validate_status(p_status IN VARCHAR2) IS
    l_status VARCHAR2(32767) := normalize_status(p_status);
  BEGIN
    IF l_status IS NULL
       OR l_status NOT IN (
         c_status_draft,
         c_status_active,
         c_status_suspended,
         c_status_closed
       ) THEN
      RAISE e_invalid_status;
    END IF;
  END validate_status;

  PROCEDURE validate_status_transition(
    p_current_status IN VARCHAR2,
    p_new_status     IN VARCHAR2
  ) IS
    l_current VARCHAR2(32767);
    l_new     VARCHAR2(32767);
  BEGIN
    validate_status(p_current_status);
    validate_status(p_new_status);
    l_current := normalize_status(p_current_status);
    l_new := normalize_status(p_new_status);

    IF (l_current = c_status_draft AND l_new IN (c_status_active, c_status_closed))
       OR (l_current = c_status_active AND l_new IN (c_status_suspended, c_status_closed))
       OR (l_current = c_status_suspended AND l_new IN (c_status_active, c_status_closed)) THEN
      RETURN;
    END IF;
    RAISE e_invalid_transition;
  END validate_status_transition;

  PROCEDURE assert_store_editable(p_current_status IN VARCHAR2) IS
  BEGIN
    validate_status(p_current_status);
    IF normalize_status(p_current_status) = c_status_closed THEN
      RAISE e_store_closed;
    END IF;
  END assert_store_editable;

  PROCEDURE validate_slug_change(
    p_current_status IN VARCHAR2,
    p_slug_present   IN BOOLEAN,
    p_current_slug   IN VARCHAR2,
    p_new_slug       IN VARCHAR2
  ) IS
  BEGIN
    IF p_slug_present IS NULL THEN
      RAISE VALUE_ERROR;
    ELSIF NOT p_slug_present THEN
      RETURN;
    END IF;
    validate_status(p_current_status);
    IF normalize_slug(p_current_slug) = normalize_slug(p_new_slug) THEN
      RETURN;
    END IF;
    IF normalize_status(p_current_status) <> c_status_draft THEN
      RAISE e_slug_not_editable;
    END IF;
  END validate_slug_change;

  PROCEDURE validate_patch_not_empty(p_patch IN t_store_patch) IS
  BEGIN
    IF NOT is_true(p_patch.set_name)
       AND NOT is_true(p_patch.set_slug)
       AND NOT is_true(p_patch.set_description)
       AND NOT is_true(p_patch.set_logo_url)
       AND NOT is_true(p_patch.set_cover_url)
       AND NOT is_true(p_patch.set_locale_code)
       AND NOT is_true(p_patch.set_timezone_name) THEN
      RAISE e_empty_patch;
    END IF;
  END validate_patch_not_empty;

  PROCEDURE normalize_and_validate_patch(
    p_current_status IN VARCHAR2,
    p_current_slug   IN VARCHAR2,
    io_patch         IN OUT NOCOPY t_store_patch
  ) IS
  BEGIN
    assert_store_editable(p_current_status);
    validate_patch_not_empty(io_patch);

    IF is_true(io_patch.set_name) THEN
      io_patch.name_value := normalize_name(io_patch.name_value);
      validate_name(io_patch.name_value);
    END IF;
    IF is_true(io_patch.set_slug) THEN
      io_patch.slug_value := normalize_slug(io_patch.slug_value);
      validate_slug(io_patch.slug_value);
      validate_slug_change(
        p_current_status, TRUE, p_current_slug, io_patch.slug_value
      );
    END IF;
    IF is_true(io_patch.set_description) THEN
      io_patch.description_value := normalize_optional_text(io_patch.description_value);
      validate_description(io_patch.description_value);
    END IF;
    IF is_true(io_patch.set_logo_url) THEN
      io_patch.logo_url_value := normalize_url(io_patch.logo_url_value);
      validate_logo_url(io_patch.logo_url_value);
    END IF;
    IF is_true(io_patch.set_cover_url) THEN
      io_patch.cover_url_value := normalize_url(io_patch.cover_url_value);
      validate_cover_url(io_patch.cover_url_value);
    END IF;
    IF is_true(io_patch.set_locale_code) THEN
      io_patch.locale_code_value := TRIM(io_patch.locale_code_value);
      validate_locale_code(io_patch.locale_code_value);
    END IF;
    IF is_true(io_patch.set_timezone_name) THEN
      io_patch.timezone_value := TRIM(io_patch.timezone_value);
      validate_timezone_name(io_patch.timezone_value);
    END IF;
  END normalize_and_validate_patch;

  PROCEDURE normalize_and_validate_creation(
    io_creation IN OUT NOCOPY t_store_creation
  ) IS
  BEGIN
    io_creation.name_value := normalize_name(io_creation.name_value);
    io_creation.slug_value := normalize_slug(io_creation.slug_value);
    io_creation.description_value := normalize_optional_text(io_creation.description_value);
    io_creation.logo_url_value := normalize_url(io_creation.logo_url_value);
    io_creation.cover_url_value := normalize_url(io_creation.cover_url_value);
    io_creation.locale_code_value := NVL(TRIM(io_creation.locale_code_value), c_locale_pt_br);
    io_creation.timezone_value := NVL(TRIM(io_creation.timezone_value), c_timezone_sao_paulo);
    io_creation.status_value := c_status_draft;

    validate_name(io_creation.name_value);
    validate_slug(io_creation.slug_value);
    validate_description(io_creation.description_value);
    validate_logo_url(io_creation.logo_url_value);
    validate_cover_url(io_creation.cover_url_value);
    validate_locale_code(io_creation.locale_code_value);
    validate_timezone_name(io_creation.timezone_value);
  END normalize_and_validate_creation;

  PROCEDURE assert_account_eligible(
    p_account_exists IN BOOLEAN,
    p_account_status IN VARCHAR2
  ) IS
    l_account_status VARCHAR2(30);
  BEGIN
    l_account_status := UPPER(TRIM(p_account_status));

    IF p_account_exists IS NULL
       OR NOT p_account_exists
       OR l_account_status IS NULL
       OR l_account_status <> c_status_active THEN
      RAISE e_account_ineligible;
    END IF;
  END assert_account_eligible;

  PROCEDURE build_known_error(
    p_code         IN core_error_pkg.t_error_code,
    o_public_error OUT NOCOPY core_error_pkg.t_public_error,
    o_error_policy OUT NOCOPY core_error_pkg.t_error_policy
  ) IS
    l_category core_error_pkg.t_category;
    l_message  core_error_pkg.t_external_message;
  BEGIN
    CASE p_code
      WHEN c_code_name_required THEN l_category := core_error_pkg.c_category_validation; l_message := 'O nome da STORE e obrigatorio.';
      WHEN c_code_invalid_name THEN l_category := core_error_pkg.c_category_validation; l_message := 'O nome da STORE e invalido.';
      WHEN c_code_slug_required THEN l_category := core_error_pkg.c_category_validation; l_message := 'O slug da STORE e obrigatorio.';
      WHEN c_code_invalid_slug THEN l_category := core_error_pkg.c_category_validation; l_message := 'O slug da STORE e invalido.';
      WHEN c_code_invalid_description THEN l_category := core_error_pkg.c_category_validation; l_message := 'A descricao da STORE e invalida.';
      WHEN c_code_invalid_logo_url THEN l_category := core_error_pkg.c_category_validation; l_message := 'A URL do logo da STORE e invalida.';
      WHEN c_code_invalid_cover_url THEN l_category := core_error_pkg.c_category_validation; l_message := 'A URL da capa da STORE e invalida.';
      WHEN c_code_invalid_locale THEN l_category := core_error_pkg.c_category_validation; l_message := 'O locale da STORE e invalido.';
      WHEN c_code_invalid_timezone THEN l_category := core_error_pkg.c_category_validation; l_message := 'O timezone da STORE e invalido.';
      WHEN c_code_invalid_status THEN l_category := core_error_pkg.c_category_validation; l_message := 'O status da STORE e invalido.';
      WHEN c_code_invalid_transition THEN l_category := core_error_pkg.c_category_business; l_message := 'A transicao de status da STORE e invalida.';
      WHEN c_code_empty_patch THEN l_category := core_error_pkg.c_category_validation; l_message := 'A atualizacao da STORE nao possui campos.';
      WHEN c_code_slug_not_editable THEN l_category := core_error_pkg.c_category_business; l_message := 'O slug da STORE nao pode ser alterado neste estado.';
      WHEN c_code_store_closed THEN l_category := core_error_pkg.c_category_business; l_message := 'A STORE encerrada nao pode ser alterada.';
      WHEN c_code_account_ineligible THEN l_category := core_error_pkg.c_category_business; l_message := 'A ACCOUNT nao esta elegivel para possuir STORE.';
      WHEN c_code_slug_already_used THEN l_category := core_error_pkg.c_category_conflict; l_message := 'O slug da STORE ja esta em uso.';
      ELSE RAISE VALUE_ERROR;
    END CASE;

    core_error_pkg.build_known_error(
      p_code             => p_code,
      p_category         => l_category,
      p_external_message => l_message,
      p_severity         => core_error_pkg.c_severity_error,
      p_retryable        => FALSE,
      p_should_log       => FALSE,
      o_public_error     => o_public_error,
      o_error_policy     => o_error_policy
    );
  END build_known_error;
END str_rule_pkg;
/
