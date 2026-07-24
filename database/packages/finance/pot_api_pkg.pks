CREATE OR REPLACE PACKAGE pot_api_pkg AS
  PROCEDURE request_payout(p_store VARCHAR2,p_body CLOB,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE get_payout(p_public VARCHAR2,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
END pot_api_pkg;
/
