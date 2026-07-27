WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
SET DEFINE OFF

BEGIN
  ORDS.DELETE_MODULE(
    p_module_name => 'brecho-express-v1'
  );
  COMMIT;
END;
/

PROMPT Brecho Express ORDS v1 module removed. Schema remains REST-enabled.
