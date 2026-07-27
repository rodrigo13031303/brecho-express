SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

DECLARE
  l_account_id        BEX_ACCOUNT.ACC_ID%TYPE;
  l_account_public_id BEX_ACCOUNT.ACC_PUBLIC_ID%TYPE;
  l_email             BEX_ACCOUNT.ACC_EMAIL%TYPE;
  l_session_public_id VARCHAR2(32);
  l_session_token     VARCHAR2(64);
  l_expires_at        TIMESTAMP;
  l_authenticated     BOOLEAN;
  l_actor_id          NUMBER;
  l_bound_session_id  VARCHAR2(32);
  l_status_code       PLS_INTEGER;
  l_response_body     CLOB;
  l_response_json     JSON_OBJECT_T;
  l_error_json        JSON_OBJECT_T;

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
  l_account_public_id := LOWER(RAWTOHEX(SYS_GUID()));
  l_email := 'ord.runtime.'
    || LOWER(SUBSTR(RAWTOHEX(SYS_GUID()), 1, 12))
    || '@example.invalid';

  INSERT INTO BEX_ACCOUNT(
    ACC_PUBLIC_ID,
    ACC_EMAIL,
    ACC_PASSWORD_HASH,
    ACC_PASSWORD_CHANGED_AT,
    ACC_STATUS
  )
  VALUES(
    l_account_public_id,
    l_email,
    acc_password_pkg.hash_password('ValidPassword123'),
    SYSTIMESTAMP,
    'ACTIVE'
  )
  RETURNING ACC_ID INTO l_account_id;

  acc_session_api_pkg.create_session(
    p_acc_id            => l_account_id,
    p_duration_minutes  => 15,
    p_created_by        => l_account_id,
    p_ip                => '127.0.0.1',
    p_user_agent        => 'ORD runtime test',
    p_session_public_id => l_session_public_id,
    p_session_token     => l_session_token,
    p_expires_at        => l_expires_at
  );

  ord_runtime_pkg.begin_authenticated_request(
    p_authorization     => 'Bearer ' || l_session_token,
    o_authenticated     => l_authenticated,
    o_account_id        => l_actor_id,
    o_session_public_id => l_bound_session_id,
    o_status_code       => l_status_code,
    o_response_body     => l_response_body
  );

  assert_true(l_authenticated, 'Bearer valido deveria autenticar.');
  assert_true(l_actor_id = l_account_id, 'ACC_ID confiavel incorreto.');
  assert_true(
    l_bound_session_id = l_session_public_id,
    'SESSION_PUBLIC_ID confiavel incorreto.'
  );
  assert_true(
    core_context_pkg.is_authenticated,
    'Core Context deveria estar autenticado.'
  );
  assert_true(
    TRIM(core_context_pkg.actor_public_id) =
      UPPER(TRIM(l_account_public_id)),
    'Actor public id incorreto.'
  );
  assert_true(
    core_security_context_pkg.actor_type =
      core_security_context_pkg.c_actor_type_user,
    'Actor type deveria ser USER.'
  );
  assert_true(
    core_security_context_pkg.authentication_method =
      core_security_context_pkg.c_authentication_method_session,
    'Authentication method deveria ser SESSION.'
  );
  assert_true(
    l_status_code IS NULL AND l_response_body IS NULL,
    'Autenticacao valida nao deveria produzir erro.'
  );
  DBMS_OUTPUT.PUT_LINE('PASS 01 - Bearer valido inicializa contexto seguro');

  ord_runtime_pkg.clear_request_context;
  ROLLBACK;

  ord_runtime_pkg.begin_authenticated_request(
    p_authorization     => 'Bearer invalid',
    o_authenticated     => l_authenticated,
    o_account_id        => l_actor_id,
    o_session_public_id => l_bound_session_id,
    o_status_code       => l_status_code,
    o_response_body     => l_response_body
  );

  l_response_json := JSON_OBJECT_T.parse(l_response_body);
  l_error_json := l_response_json.get_object('error');
  assert_true(NOT l_authenticated, 'Bearer invalido nao pode autenticar.');
  assert_true(l_actor_id IS NULL, 'Bearer invalido nao pode expor ACC_ID.');
  assert_true(
    l_bound_session_id IS NULL,
    'Bearer invalido nao pode expor SESSION_PUBLIC_ID.'
  );
  assert_true(l_status_code = 401, 'Bearer invalido deveria retornar 401.');
  assert_true(
    l_error_json.get_string('code') = 'BEX-AUTH-002',
    'Bearer invalido deveria retornar BEX-AUTH-002.'
  );
  assert_true(
    NOT core_context_pkg.is_authenticated,
    'Erro de autenticacao deve manter contexto anonimo.'
  );
  DBMS_OUTPUT.PUT_LINE('PASS 02 - Bearer invalido retorna erro seguro');

  ord_runtime_pkg.clear_request_context;
  DBMS_OUTPUT.PUT_LINE('ORD RUNTIME PACKAGE: PASSED');
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    ord_runtime_pkg.clear_request_context;
    RAISE;
END;
/
