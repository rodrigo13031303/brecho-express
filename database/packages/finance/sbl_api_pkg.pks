CREATE OR REPLACE PACKAGE sbl_api_pkg AS
  PROCEDURE get_balance(p_store_public VARCHAR2,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
END sbl_api_pkg;
/
