SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

DECLARE
  l_account_id  BEX_ACCOUNT.ACC_ID%TYPE;
  l_count       PLS_INTEGER;
  l_duplicate   BOOLEAN := FALSE;
  l_invalid     BOOLEAN := FALSE;
  l_public_id   CHAR(32);
  l_run_token   VARCHAR2(12);

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
  SELECT COUNT(*)
    INTO l_count
    FROM USER_TAB_COLUMNS
   WHERE TABLE_NAME = 'BEX_ACCOUNT_IDENTITY';
  assert_true(l_count = 16, 'BEX_ACCOUNT_IDENTITY deveria ter 16 colunas.');

  SELECT COUNT(*)
    INTO l_count
    FROM USER_CONSTRAINTS
   WHERE TABLE_NAME = 'BEX_ACCOUNT_IDENTITY'
     AND CONSTRAINT_NAME IN (
       'PK_AID',
       'UK_AID_PUBLIC_ID',
       'UK_AID_PROVIDER_SUBJECT',
       'UK_AID_ACCOUNT_PROVIDER',
       'FK_AID_ACCOUNT',
       'CK_AID_PROVIDER',
       'CK_AID_EMAIL_VERIFIED',
       'CK_AID_STATUS'
     );
  assert_true(l_count = 8, 'Constraints de ACCOUNT_IDENTITY incompletas.');

  SELECT COUNT(*)
    INTO l_count
    FROM USER_TAB_COLUMNS
   WHERE TABLE_NAME = 'BEX_ACCOUNT'
     AND COLUMN_NAME = 'ACC_PASSWORD_HASH'
     AND NULLABLE = 'Y';
  assert_true(l_count = 1, 'ACC_PASSWORD_HASH deveria aceitar NULL.');
  DBMS_OUTPUT.PUT_LINE('PASS 01 - Contrato fisico instalado');

  l_run_token := LOWER(SUBSTR(RAWTOHEX(SYS_GUID()), 1, 12));
  INSERT INTO BEX_ACCOUNT(
    ACC_PUBLIC_ID,
    ACC_EMAIL,
    ACC_PASSWORD_HASH,
    ACC_PASSWORD_CHANGED_AT,
    ACC_STATUS
  )
  VALUES(
    LOWER(RAWTOHEX(SYS_GUID())),
    'social.' || l_run_token || '@example.invalid',
    NULL,
    NULL,
    'ACTIVE'
  )
  RETURNING ACC_ID INTO l_account_id;
  DBMS_OUTPUT.PUT_LINE('PASS 02 - ACCOUNT exclusivamente social e valida');

  l_public_id := LOWER(RAWTOHEX(SYS_GUID()));
  INSERT INTO BEX_ACCOUNT_IDENTITY(
    AID_PUBLIC_ID,
    ACC_ID,
    AID_PROVIDER,
    AID_ISSUER,
    AID_SUBJECT,
    AID_EMAIL,
    AID_EMAIL_VERIFIED
  )
  VALUES(
    l_public_id,
    l_account_id,
    'GOOGLE',
    'https://accounts.google.com',
    'subject-' || l_run_token,
    'social.' || l_run_token || '@example.invalid',
    'Y'
  );

  SELECT COUNT(*)
    INTO l_count
    FROM BEX_ACCOUNT_IDENTITY
   WHERE AID_PUBLIC_ID = l_public_id
     AND AID_STATUS = 'ACTIVE';
  assert_true(l_count = 1, 'Identidade social valida nao foi persistida.');
  DBMS_OUTPUT.PUT_LINE('PASS 03 - Identidade social valida e persistida');

  BEGIN
    INSERT INTO BEX_ACCOUNT_IDENTITY(
      AID_PUBLIC_ID,
      ACC_ID,
      AID_PROVIDER,
      AID_ISSUER,
      AID_SUBJECT
    )
    VALUES(
      LOWER(RAWTOHEX(SYS_GUID())),
      l_account_id,
      'GOOGLE',
      'https://accounts.google.com',
      'other-subject-' || l_run_token
    );
  EXCEPTION
    WHEN DUP_VAL_ON_INDEX THEN
      l_duplicate := TRUE;
  END;
  assert_true(
    l_duplicate,
    'Uma ACCOUNT nao pode possuir duas identidades do mesmo provedor.'
  );
  DBMS_OUTPUT.PUT_LINE('PASS 04 - Unicidade por ACCOUNT e provedor protegida');

  BEGIN
    INSERT INTO BEX_ACCOUNT_IDENTITY(
      AID_PUBLIC_ID,
      ACC_ID,
      AID_PROVIDER,
      AID_ISSUER,
      AID_SUBJECT
    )
    VALUES(
      LOWER(RAWTOHEX(SYS_GUID())),
      l_account_id,
      'UNTRUSTED',
      'https://invalid.example',
      'subject-invalid-' || l_run_token
    );
  EXCEPTION
    WHEN OTHERS THEN
      IF SQLCODE = -2290 THEN
        l_invalid := TRUE;
      ELSE
        RAISE;
      END IF;
  END;
  assert_true(l_invalid, 'Provedor nao aprovado deveria ser rejeitado.');
  DBMS_OUTPUT.PUT_LINE('PASS 05 - Dominio de provedores protegido');

  ROLLBACK;
  DBMS_OUTPUT.PUT_LINE('BEX_ACCOUNT_IDENTITY: PASSED');
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    RAISE;
END;
/
