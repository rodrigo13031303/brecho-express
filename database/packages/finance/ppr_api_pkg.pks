CREATE OR REPLACE PACKAGE ppr_api_pkg AS
  PROCEDURE get_provider(p_public VARCHAR2,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE list_providers(o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
END ppr_api_pkg;
/
