CREATE OR REPLACE PACKAGE BODY acc_identity_service_pkg AS
  FUNCTION authenticate_google(
    p_issuer         IN VARCHAR2,
    p_subject        IN VARCHAR2,
    p_email          IN VARCHAR2,
    p_email_verified IN CHAR
  ) RETURN BEX_ACCOUNT%ROWTYPE IS
    l_issuer   VARCHAR2(500) := TRIM(p_issuer);
    l_subject  VARCHAR2(255) := TRIM(p_subject);
    l_email    VARCHAR2(255);
    l_identity BEX_ACCOUNT_IDENTITY%ROWTYPE;
    l_account  BEX_ACCOUNT%ROWTYPE;
  BEGIN
    IF l_issuer IS NULL
       OR l_issuer NOT IN ('accounts.google.com', 'https://accounts.google.com')
       OR l_subject IS NULL
       OR LENGTH(l_subject) > 255
    THEN
      RAISE e_invalid_claims;
    END IF;

    l_identity := acc_identity_repository_pkg.find_active(
      'GOOGLE',
      l_issuer,
      l_subject
    );

    IF l_identity.AID_ID IS NOT NULL THEN
      l_account := acc_repository_pkg.get_by_id(l_identity.ACC_ID);
      IF l_account.ACC_ID IS NULL OR l_account.ACC_STATUS <> 'ACTIVE' THEN
        RAISE e_account_unavailable;
      END IF;

      l_email := acc_rule_pkg.normalize_email(p_email);
      acc_identity_repository_pkg.register_login(
        l_identity.AID_ID,
        l_email,
        CASE WHEN p_email_verified = 'Y' THEN 'Y' ELSE 'N' END,
        l_account.ACC_ID
      );
      acc_service_pkg.register_login(l_account.ACC_ID, l_account.ACC_ID);
      RETURN acc_repository_pkg.get_by_id(l_account.ACC_ID);
    END IF;

    IF p_email_verified <> 'Y' THEN
      RAISE e_invalid_claims;
    END IF;

    l_email := acc_rule_pkg.normalize_email(p_email);
    acc_rule_pkg.validate_email(l_email);

    IF acc_repository_pkg.email_exists(l_email) THEN
      RAISE e_existing_email;
    END IF;

    l_account := acc_service_pkg.create_social_account(l_email);
    acc_identity_repository_pkg.insert_identity(
      l_account.ACC_ID,
      'GOOGLE',
      l_issuer,
      l_subject,
      l_email,
      'Y',
      l_account.ACC_ID
    );
    RETURN l_account;
  EXCEPTION
    WHEN acc_rule_pkg.e_invalid_email THEN
      RAISE e_invalid_claims;
    WHEN acc_rule_pkg.e_email_already_used THEN
      RAISE e_existing_email;
    WHEN DUP_VAL_ON_INDEX THEN
      RAISE e_existing_email;
  END authenticate_google;
END acc_identity_service_pkg;
/
