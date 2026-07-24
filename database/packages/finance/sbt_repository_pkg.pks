CREATE OR REPLACE PACKAGE sbt_repository_pkg AS
  TYPE t_row IS RECORD(sbt_id NUMBER,sbt_public_id CHAR(32),str_id NUMBER,ord_id NUMBER,
    pay_id NUMBER,pot_id NUMBER,sbt_type VARCHAR2(50),sbt_amount NUMBER,
    sbt_direction VARCHAR2(10),sbt_available_at TIMESTAMP,sbt_description VARCHAR2(1000));
  PROCEDURE insert_row(p t_row,p_actor NUMBER,o_id OUT NUMBER);
  FUNCTION available_balance(p_store NUMBER) RETURN NUMBER;
  FUNCTION blocked_balance(p_store NUMBER) RETURN NUMBER;
  PROCEDURE lock_store(p_store NUMBER);
END sbt_repository_pkg;
/
