CREATE OR REPLACE PACKAGE srv_repository_pkg AS
  TYPE t_row IS RECORD(srv_id NUMBER,srv_public_id CHAR(32),ord_id NUMBER,str_id NUMBER,pfl_id NUMBER,
    overall_rate NUMBER,product_match_rate NUMBER,conservation_rate NUMBER,service_rate NUMBER,delivery_rate NUMBER,
    packaging_rate NUMBER,would_buy_again CHAR(1),comment_text VARCHAR2(2000),store_reply VARCHAR2(2000),
    status VARCHAR2(20),reviewed_at TIMESTAMP);
  TYPE t_rows IS TABLE OF t_row INDEX BY PLS_INTEGER;
  PROCEDURE insert_row(p t_row,p_actor NUMBER,o_id OUT NUMBER);FUNCTION by_public(p VARCHAR2)RETURN t_row;
  FUNCTION by_id(p NUMBER)RETURN t_row;FUNCTION list_store(p_store NUMBER)RETURN t_rows;
  PROCEDURE reply(p_id NUMBER,p_reply VARCHAR2,p_actor NUMBER);
END srv_repository_pkg;
/
