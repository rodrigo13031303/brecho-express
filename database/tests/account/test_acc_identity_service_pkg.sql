SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

DECLARE
  l_token       VARCHAR2(12) := LOWER(SUBSTR(RAWTOHEX(SYS_GUID()), 1, 12));
  l_email       VARCHAR2(255);
  l_account     BEX_ACCOUNT%ROWTYPE;
  l_repeat      BEX_ACCOUNT%ROWTYPE;
  l_count       PLS_INTEGER;
  l_expected    BOOLEAN := FALSE;

  PROCEDURE assert_true(
    p_condition IN BOOLEAN,
    p_message   IN VARCHAR2
  ) IS
  BEGIN
    IF p_condition IS NULL OR NOT p_condition THEN
      RAISE_APPLICATION_ERROR(-20999, p_message);
    END IF;
  END assert_true;
BEGIN
  l_email := 'google.' || l_token || '@example.invalid';
  l_account := acc_identity_service_pkg.authenticate_google(
    'https://accounts.google.com',
    'google-subject-' || l_token,
    l_email,
    'Y'
  );

  assert_true(l_account.ACC_STATUS = 'ACTIVE', 'Conta social deve estar ativa.');
  assert_true(l_account.ACC_PASSWORD_HASH IS NULL, 'Conta social nao deve possuir senha.');
  assert_true(l_account.ACC_EMAIL_VERIFIED_AT IS NOT NULL, 'Email social deve estar verificado.');
  DBMS_OUTPUT.put_line('PASS 01 - Conta exclusivamente social criada');

  l_repeat := acc_identity_service_pkg.authenticate_google(
    'https://accounts.google.com',
    'google-subject-' || l_token,
    l_email,
    'Y'
  );
  assert_true(l_repeat.ACC_ID = l_account.ACC_ID, 'Identidade deve retornar a mesma conta.');
  DBMS_OUTPUT.put_line('PASS 02 - Identidade conhecida e idempotente');

  SELECT COUNT(*)
    INTO l_count
    FROM BEX_ACCOUNT_IDENTITY
   WHERE ACC_ID = l_account.ACC_ID
     AND AID_PROVIDER = 'GOOGLE';
  assert_true(l_count = 1, 'Login repetido nao pode duplicar identidade.');
  DBMS_OUTPUT.put_line('PASS 03 - Identidade Google nao duplicada');

  BEGIN
    l_repeat := acc_identity_service_pkg.authenticate_google(
      'https://accounts.google.com',
      'different-subject-' || l_token,
      l_email,
      'Y'
    );
  EXCEPTION
    WHEN acc_identity_service_pkg.e_existing_email THEN
      l_expected := TRUE;
  END;
  assert_true(l_expected, 'Email existente nao pode causar auto-link.');
  DBMS_OUTPUT.put_line('PASS 04 - Auto-link por email impedido');

  l_expected := FALSE;
  BEGIN
    l_repeat := acc_identity_service_pkg.authenticate_google(
      'https://accounts.google.com',
      'unverified-subject-' || l_token,
      'unverified.' || l_token || '@example.invalid',
      'N'
    );
  EXCEPTION
    WHEN acc_identity_service_pkg.e_invalid_claims THEN
      l_expected := TRUE;
  END;
  assert_true(l_expected, 'Identidade nova exige email verificado.');
  DBMS_OUTPUT.put_line('PASS 05 - Email nao verificado rejeitado');

  ROLLBACK;
  DBMS_OUTPUT.put_line('ACC_IDENTITY_SERVICE_PKG: PASSED');
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END;
/
