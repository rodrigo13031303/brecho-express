CREATE OR REPLACE PACKAGE srp_api_pkg AS
  PROCEDURE get_store(p_store VARCHAR2,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
END srp_api_pkg;
/
