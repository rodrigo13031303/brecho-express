CREATE OR REPLACE PACKAGE stf_api_pkg AS
  PROCEDURE follow_store(p_store VARCHAR2,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE unfollow_store(p_store VARCHAR2,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
END stf_api_pkg;
/
