SET SERVEROUTPUT ON
SET DEFINE ON

-- Limpeza intencional de um cadastro de teste.
-- O bloco recusa a exclusão se a STORE tiver produtos ou se o slug não
-- identificar exatamente um registro.
DECLARE
  c_store_slug CONSTANT VARCHAR2(200) := 'rodrigo';
  l_store_id BEX_STORE.STR_ID%TYPE;
  l_store_name BEX_STORE.STR_NAME%TYPE;
  l_store_status BEX_STORE.STR_STATUS%TYPE;
  l_count PLS_INTEGER;
BEGIN
  SAVEPOINT before_test_store_cleanup;

  SELECT COUNT(*)
    INTO l_count
    FROM BEX_STORE
   WHERE STR_SLUG = c_store_slug;

  IF l_count <> 1 THEN
    RAISE_APPLICATION_ERROR(
      -20991,
      'Limpeza cancelada: o slug deve identificar exatamente uma STORE.'
    );
  END IF;

  SELECT STR_ID, STR_NAME, STR_STATUS
    INTO l_store_id, l_store_name, l_store_status
    FROM BEX_STORE
   WHERE STR_SLUG = c_store_slug
   FOR UPDATE;

  SELECT COUNT(*)
    INTO l_count
    FROM BEX_PRODUCT
   WHERE STR_ID = l_store_id;

  IF l_count > 0 THEN
    RAISE_APPLICATION_ERROR(
      -20992,
      'Limpeza cancelada: a STORE possui produtos.'
    );
  END IF;

  DELETE FROM BEX_STORE_LOCATION WHERE STR_ID = l_store_id;
  DELETE FROM BEX_STORE_LOGO WHERE STR_ID = l_store_id;
  DELETE FROM BEX_STORE_USER WHERE STR_ID = l_store_id;
  DELETE FROM BEX_STORE WHERE STR_ID = l_store_id;

  COMMIT;
  DBMS_OUTPUT.PUT_LINE(
    'STORE de teste removida: ' || l_store_name ||
    ' (' || c_store_slug || ', status anterior ' || l_store_status || ').'
  );
EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK TO before_test_store_cleanup;
    DBMS_OUTPUT.PUT_LINE('Nenhum dado foi removido: ' || SQLERRM);
    RAISE;
END;
/
