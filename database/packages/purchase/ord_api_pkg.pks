CREATE OR REPLACE PACKAGE ord_api_pkg AS
  PROCEDURE get_order(p_public VARCHAR2,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
END ord_api_pkg;
/
