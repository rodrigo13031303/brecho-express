SET SERVEROUTPUT ON
SET VERIFY OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

ACCEPT admin_email CHAR PROMPT 'E-mail da conta que recebera ADMIN: '

DECLARE
  l_profile_id     BEX_PROFILE.PFL_ID%TYPE;
  l_profile_public BEX_PROFILE.PFL_PUBLIC_ID%TYPE;
  l_result         PRL_SERVICE_PKG.t_record;
  l_already_admin  BOOLEAN;
BEGIN
  SELECT profile_data.PFL_ID, profile_data.PFL_PUBLIC_ID
    INTO l_profile_id, l_profile_public
    FROM BEX_ACCOUNT account_data
    JOIN BEX_PROFILE profile_data
      ON profile_data.ACC_ID = account_data.ACC_ID
   WHERE LOWER(account_data.ACC_EMAIL) = LOWER(TRIM('&admin_email'))
     AND account_data.ACC_STATUS = 'ACTIVE';

  SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END
    INTO l_profile_id
    FROM BEX_PROFILE_ROLE profile_role
    JOIN BEX_ROLE role_data ON role_data.ROL_ID = profile_role.ROL_ID
   WHERE profile_role.PFL_ID = (
     SELECT PFL_ID FROM BEX_PROFILE
      WHERE PFL_PUBLIC_ID = l_profile_public
   )
     AND role_data.ROL_CODE = 'ADMIN'
     AND role_data.ROL_STATUS = 'ACTIVE'
     AND profile_role.PRL_STATUS = 'ACTIVE'
     AND (
       profile_role.PRL_EXPIRES_AT IS NULL
       OR profile_role.PRL_EXPIRES_AT > SYSTIMESTAMP
     );

  l_already_admin := l_profile_id = 1;
  IF NOT l_already_admin THEN
    SELECT PFL_ID INTO l_profile_id
      FROM BEX_PROFILE WHERE PFL_PUBLIC_ID = l_profile_public;
    l_result := PRL_SERVICE_PKG.grant_role(
      TRIM(l_profile_public), 'ADMIN', NULL, l_profile_id
    );
    COMMIT;
  END IF;

  DBMS_OUTPUT.PUT_LINE(
    CASE WHEN l_already_admin
      THEN 'A conta ja possui o papel ADMIN.'
      ELSE 'Papel ADMIN concedido com sucesso.'
    END
  );
  DBMS_OUTPUT.PUT_LINE('Profile Public ID: ' || TRIM(l_profile_public));
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(
      -20001, 'Conta ACTIVE com PROFILE nao encontrada para o e-mail informado.'
    );
END;
/

EXIT SUCCESS
