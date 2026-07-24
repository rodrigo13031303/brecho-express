CREATE OR REPLACE PACKAGE pev_api_pkg AS
  PROCEDURE receive_event(p_payment_public VARCHAR2,p_body CLOB,p_actor NUMBER,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
END pev_api_pkg;
/
