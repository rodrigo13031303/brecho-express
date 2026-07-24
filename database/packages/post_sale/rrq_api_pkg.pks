CREATE OR REPLACE PACKAGE rrq_api_pkg AS
  PROCEDURE create_request(p_order VARCHAR2,p_store VARCHAR2,p_body CLOB,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE get_request(p_public VARCHAR2,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
END rrq_api_pkg;
/
