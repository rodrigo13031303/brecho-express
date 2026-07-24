CREATE OR REPLACE PACKAGE BODY sbt_service_pkg AS
  PROCEDURE post(p_store NUMBER,p_order NUMBER,p_payment NUMBER,p_payout NUMBER,
    p_type VARCHAR2,p_amount NUMBER,p_direction VARCHAR2,p_available TIMESTAMP,
    p_description VARCHAR2,p_actor NUMBER) IS r sbt_repository_pkg.t_row;id NUMBER;
  BEGIN BEGIN sbt_rule_pkg.validate_movement(p_type,p_amount,p_direction);
    EXCEPTION WHEN sbt_rule_pkg.e_invalid THEN RAISE e_invalid;END;
    r.sbt_public_id:=LOWER(RAWTOHEX(SYS_GUID()));r.str_id:=p_store;r.ord_id:=p_order;
    r.pay_id:=p_payment;r.pot_id:=p_payout;r.sbt_type:=UPPER(TRIM(p_type));r.sbt_amount:=p_amount;
    r.sbt_direction:=UPPER(TRIM(p_direction));r.sbt_available_at:=p_available;
    r.sbt_description:=TRIM(p_description);sbt_repository_pkg.insert_row(r,p_actor,id);END;
  FUNCTION available_balance(p_store NUMBER) RETURN NUMBER IS BEGIN RETURN sbt_repository_pkg.available_balance(p_store);END;
  PROCEDURE lock_store(p_store NUMBER) IS BEGIN sbt_repository_pkg.lock_store(p_store);END;
  PROCEDURE release_hold(p_store NUMBER,p_order NUMBER,p_payment NUMBER,p_amount NUMBER,p_actor NUMBER) IS
  BEGIN sbt_repository_pkg.lock_store(p_store);
    IF sbt_repository_pkg.blocked_balance(p_store)<p_amount THEN RAISE e_insufficient_balance;END IF;
    post(p_store,p_order,p_payment,NULL,'HOLD_RELEASE',p_amount,'DEBIT',SYSTIMESTAMP,'Release from hold',p_actor);
    post(p_store,p_order,p_payment,NULL,'HOLD_RELEASE',p_amount,'CREDIT',SYSTIMESTAMP,'Credit available balance',p_actor);END;
END sbt_service_pkg;
/
