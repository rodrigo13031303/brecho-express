CREATE OR REPLACE PACKAGE acc_password_pkg AS
  -- Componente criptografico do modulo ACCOUNT.
  -- Produz e verifica credenciais de senha sem persistencia, SQL, contexto de
  -- negocio ou dependencia de transporte.
  --
  -- HASH_PASSWORD rejeita senha NULL ou vazia com VALUE_ERROR.
  -- VERIFY_PASSWORD retorna FALSE para senha NULL ou vazia, credencial NULL,
  -- formato invalido, versao ou algoritmo desconhecido e parametros invalidos.
  -- O formato atual e v1$SHA512$<salt>$<hash>.

  FUNCTION hash_password(
    p_password IN VARCHAR2
  ) RETURN VARCHAR2;

  FUNCTION verify_password(
    p_password   IN VARCHAR2,
    p_credential IN VARCHAR2
  ) RETURN BOOLEAN;
END acc_password_pkg;
/
