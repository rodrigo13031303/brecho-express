CREATE OR REPLACE PACKAGE pay_api_pkg AS
  PROCEDURE create_payment(p_body CLOB,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE get_payment(p_public VARCHAR2,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
END pay_api_pkg;
/
