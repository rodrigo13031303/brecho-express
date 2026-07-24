CREATE OR REPLACE PACKAGE ste_api_pkg AS
  PROCEDURE create_event(p_store VARCHAR2,p_body CLOB,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
END ste_api_pkg;
/
