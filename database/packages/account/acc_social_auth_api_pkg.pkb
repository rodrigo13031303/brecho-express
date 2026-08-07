CREATE OR REPLACE PACKAGE BODY acc_social_auth_api_pkg AS
  PROCEDURE ensure_google_profile(
    p_account_id IN NUMBER,
    p_email      IN VARCHAR2,
    p_name       IN VARCHAR2
  ) IS
    l_profile       BEX_PROFILE%ROWTYPE;
    l_name          VARCHAR2(200);
    l_display_name  VARCHAR2(100);
    l_fallback_name VARCHAR2(100);
  BEGIN
    l_name := REGEXP_REPLACE(TRIM(p_name), '[[:space:]]+', ' ');
    l_fallback_name := SUBSTR(TRIM(p_email), 1, INSTR(TRIM(p_email), '@') - 1);
    IF LENGTH(TRIM(l_fallback_name)) < 2 THEN
      l_fallback_name := 'Cliente';
    END IF;
    l_display_name := SUBSTR(NVL(l_name, l_fallback_name), 1, 100);

    BEGIN
      l_profile := pfl_service_pkg.get_by_account_id(p_account_id);
      IF l_name IS NOT NULL
         AND (
           UPPER(TRIM(l_profile.PFL_DISPLAY_NAME)) = UPPER(TRIM(l_fallback_name))
           OR UPPER(TRIM(l_profile.PFL_DISPLAY_NAME)) = 'CLIENTE'
         )
      THEN
        l_profile := pfl_service_pkg.update_profile(
          p_profile_id     => l_profile.PFL_ID,
          p_display_name   => l_display_name,
          p_full_name      => SUBSTR(l_name, 1, 200),
          p_birth_date     => l_profile.PFL_BIRTH_DATE,
          p_bio            => l_profile.PFL_BIO,
          p_avatar_url     => l_profile.PFL_AVATAR_URL,
          p_locale_code    => l_profile.PFL_LOCALE_CODE,
          p_timezone_name  => l_profile.PFL_TIMEZONE_NAME,
          p_audit_actor_id => p_account_id
        );
      END IF;
    EXCEPTION
      WHEN pfl_service_pkg.e_profile_not_found THEN
        l_profile := pfl_service_pkg.create_profile(
          p_account_id     => p_account_id,
          p_display_name   => l_display_name,
          p_full_name      => SUBSTR(l_name, 1, 200),
          p_birth_date     => NULL,
          p_bio            => NULL,
          p_avatar_url     => NULL,
          p_locale_code    => 'pt-BR',
          p_timezone_name  => 'America/Sao_Paulo',
          p_audit_actor_id => p_account_id
        );
    END;
  END ensure_google_profile;

  FUNCTION session_duration_minutes
    RETURN PLS_INTEGER IS
    l_config bcf_service_pkg.t_record;
    l_value  PLS_INTEGER;
  BEGIN
    l_config := bcf_service_pkg.get_config(
      'AUTH_SESSION_DURATION_MINUTES'
    );
    l_value := TRUNC(l_config.value_number);

    IF l_config.status <> 'ACTIVE'
       OR l_value IS NULL
       OR l_value < 1
       OR l_value > 10080
    THEN
      RAISE VALUE_ERROR;
    END IF;
    RETURN l_value;
  END session_duration_minutes;

  PROCEDURE login_google_verified(
    p_issuer         IN VARCHAR2,
    p_subject        IN VARCHAR2,
    p_email          IN VARCHAR2,
    p_email_verified IN CHAR,
    p_name           IN VARCHAR2,
    p_ip             IN VARCHAR2,
    p_user_agent     IN VARCHAR2,
    o_status_code    OUT PLS_INTEGER,
    o_response_body  OUT NOCOPY CLOB
  ) IS
    l_account           BEX_ACCOUNT%ROWTYPE;
    l_session_public_id VARCHAR2(32);
    l_session_token     VARCHAR2(64);
    l_expires_at        TIMESTAMP;
    l_data              JSON_OBJECT_T := JSON_OBJECT_T();
  BEGIN
    l_account := acc_identity_service_pkg.authenticate_google(
      p_issuer,
      p_subject,
      p_email,
      p_email_verified
    );

    ensure_google_profile(l_account.ACC_ID, p_email, p_name);

    acc_session_api_pkg.create_session(
      p_acc_id            => l_account.ACC_ID,
      p_duration_minutes  => session_duration_minutes,
      p_created_by        => l_account.ACC_ID,
      p_ip                => p_ip,
      p_user_agent        => p_user_agent,
      p_session_public_id => l_session_public_id,
      p_session_token     => l_session_token,
      p_expires_at        => l_expires_at
    );

    core_json_pkg.put_string(l_data, 'accessToken', l_session_token);
    core_json_pkg.put_string(
      l_data,
      'sessionPublicId',
      l_session_public_id
    );
    core_json_pkg.put_string(
      l_data,
      'expiresAt',
      core_json_pkg.format_timestamp(l_expires_at)
    );
    core_json_pkg.put_string(
      l_data,
      'accountPublicId',
      TRIM(l_account.ACC_PUBLIC_ID)
    );

    o_response_body := core_response_pkg.build_success(l_data);
    o_status_code := 200;
    COMMIT;
  EXCEPTION
    WHEN acc_identity_service_pkg.e_invalid_claims
      OR acc_identity_service_pkg.e_account_unavailable THEN
      ROLLBACK;
      o_status_code := 401;
      o_response_body := core_response_pkg.build_known_error(
        'BEX-AUTH-003',
        core_error_pkg.c_category_authentication,
        'Nao foi possivel autenticar com o provedor informado.'
      );
    WHEN acc_identity_service_pkg.e_existing_email THEN
      ROLLBACK;
      o_status_code := 409;
      o_response_body := core_response_pkg.build_known_error(
        'BEX-AUTH-004',
        core_error_pkg.c_category_authentication,
        'Entre na conta existente para vincular este provedor.'
      );
    WHEN OTHERS THEN
      ROLLBACK;
      o_status_code := 500;
      o_response_body := core_response_pkg.build_technical_error;
  END login_google_verified;
END acc_social_auth_api_pkg;
/
