CREATE OR REPLACE PACKAGE rat_api_pkg AS
  PROCEDURE add_attachment(p_request VARCHAR2,p_body CLOB,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
END rat_api_pkg;
/
