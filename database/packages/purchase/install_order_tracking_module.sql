WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT Installing order tracking API...

CREATE OR REPLACE PACKAGE otr_api_pkg AS
  PROCEDURE list_buyer(p_actor_id NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE list_store(p_store_public_id VARCHAR2,p_actor_id NUMBER,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE cancel_order(p_order_public_id VARCHAR2,p_actor_id NUMBER,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
END otr_api_pkg;
/

CREATE OR REPLACE PACKAGE BODY otr_api_pkg AS
  e_forbidden EXCEPTION;e_not_found EXCEPTION;e_invalid EXCEPTION;

  PROCEDURE expire_pending IS
  BEGIN
    UPDATE BEX_ORDER_RESERVATION r SET r.ORV_STATUS='RELEASED',
      r.ORV_UPDATED_AT=SYSTIMESTAMP
    WHERE r.ORV_STATUS='ACTIVE' AND r.ORV_EXPIRES_AT<=SYSTIMESTAMP;
    UPDATE BEX_ORDER o SET o.ORD_STATUS='CANCELLED',o.ORD_UPDATED_AT=SYSTIMESTAMP
    WHERE o.ORD_STATUS='PAYMENT_PENDING' AND o.ORD_PAYMENT_EXPIRES_AT<=SYSTIMESTAMP;
  END;

  FUNCTION summary_json(p_order NUMBER,p_store NUMBER DEFAULT NULL)
    RETURN JSON_OBJECT_T IS
    j JSON_OBJECT_T:=JSON_OBJECT_T();items JSON_ARRAY_T:=JSON_ARRAY_T();
    x JSON_OBJECT_T;pub CHAR(32);num VARCHAR2(50);st VARCHAR2(20);
    created TIMESTAMP;expires TIMESTAMP;subtotal NUMBER;shipping NUMBER;
  BEGIN
    SELECT ORD_PUBLIC_ID,ORD_NUMBER,ORD_STATUS,ORD_CREATED_AT,
      ORD_PAYMENT_EXPIRES_AT
    INTO pub,num,st,created,expires FROM BEX_ORDER WHERE ORD_ID=p_order;
    IF p_store IS NULL THEN
      SELECT ORD_SUBTOTAL_AMOUNT,ORD_SHIPPING_AMOUNT INTO subtotal,shipping
      FROM BEX_ORDER WHERE ORD_ID=p_order;
    ELSE
      SELECT NVL(SUM(ORI_TOTAL_PRICE),0) INTO subtotal FROM BEX_ORDER_ITEM
      WHERE ORD_ID=p_order AND STR_ID=p_store;
      SELECT NVL(SUM(OSH_PRICE),0) INTO shipping FROM BEX_ORDER_SHIPPING
      WHERE ORD_ID=p_order AND STR_ID=p_store;
    END IF;
    core_json_pkg.put_string(j,'orderPublicId',TRIM(pub));
    core_json_pkg.put_string(j,'orderNumber',num);
    core_json_pkg.put_string(j,'status',st);
    core_json_pkg.put_number(j,'subtotalAmount',subtotal);
    core_json_pkg.put_number(j,'shippingAmount',shipping);
    core_json_pkg.put_number(j,'totalAmount',subtotal+shipping);
    core_json_pkg.put_string(j,'createdAt',core_json_pkg.format_timestamp(created));
    IF expires IS NULL THEN core_json_pkg.put_null(j,'paymentExpiresAt');
    ELSE core_json_pkg.put_string(j,'paymentExpiresAt',core_json_pkg.format_timestamp(expires));END IF;
    FOR r IN(
      SELECT oi.ORI_PUBLIC_ID,p.PRD_PUBLIC_ID,s.STR_PUBLIC_ID,p.PRD_TITLE,
        oi.ORI_QUANTITY,oi.ORI_UNIT_PRICE,oi.ORI_TOTAL_PRICE
      FROM BEX_ORDER_ITEM oi JOIN BEX_PRODUCT p ON p.PRD_ID=oi.PRD_ID
      JOIN BEX_STORE s ON s.STR_ID=oi.STR_ID
      WHERE oi.ORD_ID=p_order AND(p_store IS NULL OR oi.STR_ID=p_store)
      ORDER BY oi.ORI_ID
    ) LOOP
      x:=JSON_OBJECT_T();
      core_json_pkg.put_string(x,'itemPublicId',TRIM(r.ORI_PUBLIC_ID));
      core_json_pkg.put_string(x,'productPublicId',TRIM(r.PRD_PUBLIC_ID));
      core_json_pkg.put_string(x,'storePublicId',TRIM(r.STR_PUBLIC_ID));
      core_json_pkg.put_string(x,'title',r.PRD_TITLE);
      core_json_pkg.put_number(x,'quantity',r.ORI_QUANTITY);
      core_json_pkg.put_number(x,'unitPrice',r.ORI_UNIT_PRICE);
      core_json_pkg.put_number(x,'totalPrice',r.ORI_TOTAL_PRICE);
      core_json_pkg.append_element(items,x);
    END LOOP;
    j.put('items',items);RETURN j;
  END;

  PROCEDURE error_response(p_status NUMBER,p_code VARCHAR2,p_message VARCHAR2,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS
    e core_error_pkg.t_public_error;p core_error_pkg.t_error_policy;
  BEGIN core_error_pkg.build_known_error(p_code,
    CASE WHEN p_status=404 THEN core_error_pkg.c_category_not_found
      WHEN p_status=403 THEN core_error_pkg.c_category_authorization
      ELSE core_error_pkg.c_category_validation END,
    p_message,core_error_pkg.c_severity_warn,FALSE,FALSE,e,p);
    o_body:=core_response_pkg.build_error(e);o_status:=p_status;END;

  PROCEDURE list_buyer(p_actor_id NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS
    profile_id NUMBER;a JSON_ARRAY_T:=JSON_ARRAY_T();
  BEGIN
    BEGIN SELECT PFL_ID INTO profile_id FROM BEX_PROFILE WHERE ACC_ID=p_actor_id;
    EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_forbidden;END;
    expire_pending;
    FOR r IN(SELECT ORD_ID FROM BEX_ORDER WHERE PFL_ID=profile_id
      ORDER BY ORD_CREATED_AT DESC,ORD_ID DESC)
    LOOP core_json_pkg.append_element(a,summary_json(r.ORD_ID));END LOOP;
    o_body:=core_response_pkg.build_success(a);COMMIT;o_status:=200;
  EXCEPTION WHEN e_forbidden THEN ROLLBACK;error_response(403,'BEX-OTR-003',
    'Operacao nao autorizada.',o_status,o_body);
    WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=core_response_pkg.build_technical_error;END;

  PROCEDURE list_store(p_store_public_id VARCHAR2,p_actor_id NUMBER,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS
    store_id NUMBER;a JSON_ARRAY_T:=JSON_ARRAY_T();
  BEGIN
    BEGIN SELECT STR_ID INTO store_id FROM BEX_STORE
      WHERE STR_PUBLIC_ID=LOWER(TRIM(p_store_public_id)) AND ACC_ID=p_actor_id;
    EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_forbidden;END;
    expire_pending;
    FOR r IN(SELECT DISTINCT o.ORD_ID,o.ORD_CREATED_AT FROM BEX_ORDER o
      JOIN BEX_ORDER_ITEM i ON i.ORD_ID=o.ORD_ID WHERE i.STR_ID=store_id
      ORDER BY o.ORD_CREATED_AT DESC,o.ORD_ID DESC)
    LOOP core_json_pkg.append_element(a,summary_json(r.ORD_ID,store_id));END LOOP;
    o_body:=core_response_pkg.build_success(a);COMMIT;o_status:=200;
  EXCEPTION WHEN e_forbidden THEN ROLLBACK;error_response(403,'BEX-OTR-003',
    'Operacao nao autorizada.',o_status,o_body);
    WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=core_response_pkg.build_technical_error;END;

  PROCEDURE cancel_order(p_order_public_id VARCHAR2,p_actor_id NUMBER,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS
    order_id NUMBER;owner NUMBER;status VARCHAR2(20);
  BEGIN
    BEGIN SELECT o.ORD_ID,p.ACC_ID,o.ORD_STATUS INTO order_id,owner,status
      FROM BEX_ORDER o JOIN BEX_PROFILE p ON p.PFL_ID=o.PFL_ID
      WHERE o.ORD_PUBLIC_ID=LOWER(TRIM(p_order_public_id)) FOR UPDATE;
    EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_found;END;
    IF owner<>p_actor_id THEN RAISE e_forbidden;END IF;
    IF status<>'PAYMENT_PENDING' THEN RAISE e_invalid;END IF;
    UPDATE BEX_ORDER SET ORD_STATUS='CANCELLED',ORD_UPDATED_AT=SYSTIMESTAMP,
      ORD_UPDATED_BY=p_actor_id WHERE ORD_ID=order_id;
    UPDATE BEX_ORDER_RESERVATION SET ORV_STATUS='RELEASED',
      ORV_UPDATED_AT=SYSTIMESTAMP,ORV_UPDATED_BY=p_actor_id
    WHERE ORD_ID=order_id AND ORV_STATUS='ACTIVE';
    o_body:=core_response_pkg.build_success(summary_json(order_id));
    COMMIT;o_status:=200;
  EXCEPTION WHEN e_not_found THEN ROLLBACK;error_response(404,'BEX-OTR-001',
    'Pedido nao encontrado.',o_status,o_body);
    WHEN e_forbidden THEN ROLLBACK;error_response(403,'BEX-OTR-003',
    'Operacao nao autorizada.',o_status,o_body);
    WHEN e_invalid THEN ROLLBACK;error_response(422,'BEX-OTR-004',
    'Somente pedidos aguardando pagamento podem ser cancelados.',o_status,o_body);
    WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=core_response_pkg.build_technical_error;END;
END otr_api_pkg;
/

PROMPT Order tracking API installed.
