CREATE OR REPLACE PACKAGE BODY acc_social_auth_api_pkg AS
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
