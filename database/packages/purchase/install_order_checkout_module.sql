WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT Installing order checkout API...

CREATE OR REPLACE PACKAGE och_api_pkg AS
  PROCEDURE create_order(
    p_request_public_id VARCHAR2,p_actor_id NUMBER,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB
  );
  PROCEDURE get_order(
    p_order_public_id VARCHAR2,p_actor_id NUMBER,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB
  );
END och_api_pkg;
/

CREATE OR REPLACE PACKAGE BODY och_api_pkg AS
  e_bad EXCEPTION;e_not_found EXCEPTION;e_forbidden EXCEPTION;e_not_ready EXCEPTION;

  FUNCTION order_json(p_order_id NUMBER) RETURN JSON_OBJECT_T IS
    j JSON_OBJECT_T:=JSON_OBJECT_T();items JSON_ARRAY_T:=JSON_ARRAY_T();
    shipping JSON_ARRAY_T:=JSON_ARRAY_T();x JSON_OBJECT_T;
    order_public CHAR(32);order_number VARCHAR2(50);status VARCHAR2(20);
    subtotal NUMBER;shipping_amount NUMBER;total NUMBER;created_at TIMESTAMP;
  BEGIN
    SELECT ORD_PUBLIC_ID,ORD_NUMBER,ORD_STATUS,ORD_SUBTOTAL_AMOUNT,
      ORD_SHIPPING_AMOUNT,ORD_TOTAL_AMOUNT,ORD_CREATED_AT
    INTO order_public,order_number,status,subtotal,shipping_amount,total,created_at
    FROM BEX_ORDER WHERE ORD_ID=p_order_id;
    core_json_pkg.put_string(j,'orderPublicId',TRIM(order_public));
    core_json_pkg.put_string(j,'orderNumber',order_number);
    core_json_pkg.put_string(j,'status',status);
    core_json_pkg.put_number(j,'subtotalAmount',subtotal);
    core_json_pkg.put_number(j,'shippingAmount',shipping_amount);
    core_json_pkg.put_number(j,'totalAmount',total);
    core_json_pkg.put_string(j,'createdAt',core_json_pkg.format_timestamp(created_at));
    FOR r IN(
      SELECT oi.ORI_PUBLIC_ID,p.PRD_PUBLIC_ID,s.STR_PUBLIC_ID,p.PRD_TITLE,
        oi.ORI_QUANTITY,oi.ORI_UNIT_PRICE,oi.ORI_TOTAL_PRICE
      FROM BEX_ORDER_ITEM oi
      JOIN BEX_PRODUCT p ON p.PRD_ID=oi.PRD_ID
      JOIN BEX_STORE s ON s.STR_ID=oi.STR_ID
      WHERE oi.ORD_ID=p_order_id ORDER BY oi.ORI_ID
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
    FOR r IN(
      SELECT os.OSH_PUBLIC_ID,s.STR_PUBLIC_ID,s.STR_NAME,os.OSH_METHOD,
        os.OSH_PRICE,os.OSH_DISTANCE_KM,os.OSH_ESTIMATED_MIN_DAYS,
        os.OSH_ESTIMATED_MAX_DAYS
      FROM BEX_ORDER_SHIPPING os
      JOIN BEX_STORE s ON s.STR_ID=os.STR_ID
      WHERE os.ORD_ID=p_order_id ORDER BY s.STR_NAME
    ) LOOP
      x:=JSON_OBJECT_T();
      core_json_pkg.put_string(x,'shippingPublicId',TRIM(r.OSH_PUBLIC_ID));
      core_json_pkg.put_string(x,'storePublicId',TRIM(r.STR_PUBLIC_ID));
      core_json_pkg.put_string(x,'storeName',r.STR_NAME);
      core_json_pkg.put_string(x,'method',r.OSH_METHOD);
      core_json_pkg.put_number(x,'price',r.OSH_PRICE);
      IF r.OSH_DISTANCE_KM IS NULL THEN core_json_pkg.put_null(x,'distanceKm');
      ELSE core_json_pkg.put_number(x,'distanceKm',r.OSH_DISTANCE_KM);END IF;
      core_json_pkg.put_number(x,'estimatedMinDays',r.OSH_ESTIMATED_MIN_DAYS);
      core_json_pkg.put_number(x,'estimatedMaxDays',r.OSH_ESTIMATED_MAX_DAYS);
      core_json_pkg.append_element(shipping,x);
    END LOOP;
    j.put('items',items);j.put('shipping',shipping);RETURN j;
  END;

  PROCEDURE error_response(
    p_status NUMBER,p_code VARCHAR2,p_message VARCHAR2,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB
  ) IS e core_error_pkg.t_public_error;p core_error_pkg.t_error_policy;
  BEGIN
    core_error_pkg.build_known_error(
      p_code,
      CASE WHEN p_status=404 THEN core_error_pkg.c_category_not_found
        WHEN p_status=403 THEN core_error_pkg.c_category_authorization
        ELSE core_error_pkg.c_category_validation END,
      p_message,core_error_pkg.c_severity_warn,FALSE,FALSE,e,p
    );
    o_body:=core_response_pkg.build_error(e);o_status:=p_status;
  END;

  PROCEDURE create_order(
    p_request_public_id VARCHAR2,p_actor_id NUMBER,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB
  ) IS
    request_id NUMBER;profile_id NUMBER;request_status VARCHAR2(30);
    owner_profile NUMBER;order_id NUMBER;store_count NUMBER;selected_count NUMBER;
    subtotal NUMBER;shipping_amount NUMBER;order_public CHAR(32);
    order_number VARCHAR2(50);
  BEGIN
    IF TRIM(p_request_public_id) IS NULL OR p_actor_id IS NULL THEN RAISE e_bad;END IF;
    BEGIN
      SELECT PUR_ID,PFL_ID,PUR_STATUS INTO request_id,profile_id,request_status
      FROM BEX_PURCHASE_REQUEST
      WHERE PUR_PUBLIC_ID=LOWER(TRIM(p_request_public_id)) FOR UPDATE;
    EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_found;END;
    BEGIN SELECT PFL_ID INTO owner_profile FROM BEX_PROFILE WHERE ACC_ID=p_actor_id;
    EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_forbidden;END;
    IF owner_profile<>profile_id THEN RAISE e_forbidden;END IF;

    BEGIN
      SELECT ORD_ID INTO order_id FROM BEX_ORDER WHERE PUR_ID=request_id;
      o_body:=core_response_pkg.build_success(order_json(order_id));
      o_status:=200;RETURN;
    EXCEPTION WHEN NO_DATA_FOUND THEN NULL;END;

    IF request_status NOT IN('APPROVED','PARTIALLY_APPROVED') THEN RAISE e_not_ready;END IF;
    SELECT COUNT(DISTINCT STR_ID) INTO store_count
    FROM BEX_PURCHASE_REQUEST_ITEM
    WHERE PUR_ID=request_id AND NVL(PRI_CONFIRMED_QUANTITY,0)>0;
    SELECT COUNT(DISTINCT STR_ID),NVL(SUM(PSO_PRICE),0)
    INTO selected_count,shipping_amount
    FROM BEX_PURCHASE_SHIPPING_OPTION
    WHERE PUR_ID=request_id AND PSO_STATUS='ACTIVE' AND PSO_IS_SELECTED=1
      AND PSO_EXPIRES_AT>SYSTIMESTAMP;
    IF store_count=0 OR selected_count<>store_count THEN RAISE e_not_ready;END IF;
    SELECT SUM(PRI_CONFIRMED_QUANTITY*PRI_UNIT_PRICE) INTO subtotal
    FROM BEX_PURCHASE_REQUEST_ITEM
    WHERE PUR_ID=request_id AND NVL(PRI_CONFIRMED_QUANTITY,0)>0;

    order_public:=LOWER(RAWTOHEX(SYS_GUID()));
    order_number:='BEX-'||TO_CHAR(SYSTIMESTAMP,'YYYYMMDDHH24MISSFF3')
      ||'-'||UPPER(SUBSTR(RAWTOHEX(SYS_GUID()),1,6));
    INSERT INTO BEX_ORDER(
      ORD_PUBLIC_ID,PUR_ID,PFL_ID,ORD_NUMBER,ORD_SUBTOTAL_AMOUNT,
      ORD_DISCOUNT_AMOUNT,ORD_SHIPPING_AMOUNT,ORD_TOTAL_AMOUNT,ORD_STATUS,
      ORD_PAID_AT,ORD_CREATED_BY,ORD_UPDATED_BY
    ) VALUES(
      order_public,request_id,profile_id,order_number,subtotal,0,
      shipping_amount,subtotal+shipping_amount,'PAYMENT_PENDING',
      NULL,p_actor_id,p_actor_id
    ) RETURNING ORD_ID INTO order_id;

    INSERT INTO BEX_ORDER_ITEM(
      ORI_PUBLIC_ID,ORD_ID,PRD_ID,STR_ID,ORI_QUANTITY,ORI_UNIT_PRICE,
      ORI_DISCOUNT_AMOUNT,ORI_TOTAL_PRICE,ORI_CREATED_BY,ORI_UPDATED_BY
    )
    SELECT LOWER(RAWTOHEX(SYS_GUID())),order_id,PRD_ID,STR_ID,
      PRI_CONFIRMED_QUANTITY,PRI_UNIT_PRICE,0,
      PRI_CONFIRMED_QUANTITY*PRI_UNIT_PRICE,p_actor_id,p_actor_id
    FROM BEX_PURCHASE_REQUEST_ITEM
    WHERE PUR_ID=request_id AND NVL(PRI_CONFIRMED_QUANTITY,0)>0;

    INSERT INTO BEX_ORDER_SHIPPING(
      OSH_PUBLIC_ID,ORD_ID,STR_ID,PSO_ID,OSH_METHOD,OSH_PRICE,
      OSH_DISTANCE_KM,OSH_ESTIMATED_MIN_DAYS,OSH_ESTIMATED_MAX_DAYS,
      OSH_CREATED_BY
    )
    SELECT LOWER(RAWTOHEX(SYS_GUID())),order_id,STR_ID,PSO_ID,PSO_METHOD,
      PSO_PRICE,PSO_DISTANCE_KM,PSO_ESTIMATED_MIN_DAYS,
      PSO_ESTIMATED_MAX_DAYS,p_actor_id
    FROM BEX_PURCHASE_SHIPPING_OPTION
    WHERE PUR_ID=request_id AND PSO_STATUS='ACTIVE' AND PSO_IS_SELECTED=1
      AND PSO_EXPIRES_AT>SYSTIMESTAMP;

    o_body:=core_response_pkg.build_success(order_json(order_id));
    COMMIT;o_status:=201;
  EXCEPTION
    WHEN e_bad THEN ROLLBACK;error_response(400,'BEX-REQ-004','Valores obrigatorios.',o_status,o_body);
    WHEN e_not_found THEN ROLLBACK;error_response(404,'BEX-OCH-001','Solicitacao nao encontrada.',o_status,o_body);
    WHEN e_forbidden THEN ROLLBACK;error_response(403,'BEX-OCH-003','Operacao nao autorizada.',o_status,o_body);
    WHEN e_not_ready THEN ROLLBACK;error_response(422,'BEX-OCH-004','Escolha o frete de todos os brechos antes de continuar.',o_status,o_body);
    WHEN DUP_VAL_ON_INDEX THEN ROLLBACK;
      SELECT ORD_ID INTO order_id FROM BEX_ORDER WHERE PUR_ID=request_id;
      o_body:=core_response_pkg.build_success(order_json(order_id));o_status:=200;
    WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=core_response_pkg.build_technical_error;
  END;

  PROCEDURE get_order(
    p_order_public_id VARCHAR2,p_actor_id NUMBER,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB
  ) IS order_id NUMBER;owner_account NUMBER;
  BEGIN
    IF TRIM(p_order_public_id) IS NULL OR p_actor_id IS NULL THEN RAISE e_bad;END IF;
    BEGIN
      SELECT o.ORD_ID,p.ACC_ID INTO order_id,owner_account
      FROM BEX_ORDER o JOIN BEX_PROFILE p ON p.PFL_ID=o.PFL_ID
      WHERE o.ORD_PUBLIC_ID=LOWER(TRIM(p_order_public_id));
    EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_found;END;
    IF owner_account<>p_actor_id THEN RAISE e_forbidden;END IF;
    o_body:=core_response_pkg.build_success(order_json(order_id));o_status:=200;
  EXCEPTION
    WHEN e_bad THEN error_response(400,'BEX-REQ-004','Valores obrigatorios.',o_status,o_body);
    WHEN e_not_found THEN error_response(404,'BEX-OCH-001','Pedido nao encontrado.',o_status,o_body);
    WHEN e_forbidden THEN error_response(403,'BEX-OCH-003','Operacao nao autorizada.',o_status,o_body);
    WHEN OTHERS THEN o_status:=500;o_body:=core_response_pkg.build_technical_error;
  END;
END och_api_pkg;
/

PROMPT Order checkout API installed.
