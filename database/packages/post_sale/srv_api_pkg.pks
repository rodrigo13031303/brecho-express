CREATE OR REPLACE PACKAGE srv_api_pkg AS
  PROCEDURE create_review(p_order VARCHAR2,p_store VARCHAR2,p_body CLOB,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE get_review(p_public VARCHAR2,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
END srv_api_pkg;
/
