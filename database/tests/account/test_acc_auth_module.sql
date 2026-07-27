SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE a NUMBER;email VARCHAR2(255);body CLOB;out_body CLOB;status NUMBER;o JSON_OBJECT_T;d JSON_OBJECT_T;token VARCHAR2(64);sid VARCHAR2(32);s BEX_SESSION%ROWTYPE;BEGIN
 email:='auth.'||LOWER(SUBSTR(RAWTOHEX(SYS_GUID()),1,12))||'@example.invalid';INSERT INTO BEX_ACCOUNT(ACC_PUBLIC_ID,ACC_EMAIL,ACC_PASSWORD_HASH,ACC_PASSWORD_CHANGED_AT,ACC_STATUS)VALUES(LOWER(RAWTOHEX(SYS_GUID())),email,acc_password_pkg.hash_password('ValidPassword123'),SYSTIMESTAMP,'ACTIVE') RETURNING ACC_ID INTO a;
 core_trace_pkg.initialize;core_context_pkg.initialize(p_execution_origin=>core_context_pkg.c_origin_external,p_execution_mode=>core_context_pkg.c_mode_synchronous,p_actor_public_id=>NULL,p_authenticated=>FALSE);
 body:='{"email":"'||email||'","password":"ValidPassword123"}';
 acc_auth_api_pkg.login(body,'127.0.0.1','Oracle test',status,out_body);IF status<>200 THEN DBMS_OUTPUT.PUT_LINE('LOGIN STATUS='||status);DBMS_OUTPUT.PUT_LINE('LOGIN BODY='||out_body);RAISE_APPLICATION_ERROR(-20999,'Login falhou.');END IF;o:=JSON_OBJECT_T.parse(out_body);d:=o.get_object('data');token:=d.get_string('accessToken');sid:=d.get_string('sessionPublicId');IF LENGTH(token)<>64 OR LENGTH(sid)<>32 THEN RAISE_APPLICATION_ERROR(-20999,'Token invalido.');END IF;DBMS_OUTPUT.PUT_LINE('PASS 01 - Login retorna sessao segura');
 s:=acc_session_api_pkg.validate_session(token);IF s.ACC_ID<>a THEN RAISE_APPLICATION_ERROR(-20999,'Sessao invalida.');END IF;DBMS_OUTPUT.PUT_LINE('PASS 02 - Token valida sessao');
 acc_auth_api_pkg.logout(sid,a,status,out_body);s:=acc_session_api_pkg.get_session_by_public_id(sid);IF s.SESSION_STATUS<>'REVOKED' THEN RAISE_APPLICATION_ERROR(-20999,'Logout nao revogou.');END IF;DBMS_OUTPUT.PUT_LINE('PASS 03 - Logout revoga sessao');
 DELETE FROM BEX_SESSION WHERE ACC_ID=a;DELETE FROM BEX_ACCOUNT WHERE ACC_ID=a;COMMIT;
 DBMS_OUTPUT.PUT_LINE('ACCOUNT AUTH MODULE: PASSED');
EXCEPTION WHEN OTHERS THEN
 DELETE FROM BEX_SESSION WHERE ACC_ID=a;DELETE FROM BEX_ACCOUNT WHERE ACC_ID=a;COMMIT;RAISE;
END;
/
