WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT Installing shipping quote packages...

CREATE OR REPLACE PACKAGE psq_service_pkg AS
  TYPE t_option IS RECORD(
    option_public_id CHAR(32),store_public_id CHAR(32),
    store_name VARCHAR2(200),method_code VARCHAR2(20),
    price NUMBER,distance_km NUMBER,min_days NUMBER,max_days NUMBER,
    expires_at TIMESTAMP,is_selected NUMBER
  );
  TYPE t_options IS TABLE OF t_option INDEX BY PLS_INTEGER;
  e_not_found EXCEPTION;e_forbidden EXCEPTION;e_not_ready EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_not_found,-20698);
  PRAGMA EXCEPTION_INIT(e_forbidden,-20699);
  PRAGMA EXCEPTION_INIT(e_not_ready,-20710);
  FUNCTION quote(p_request_public_id VARCHAR2,p_actor_id NUMBER) RETURN t_options;
  FUNCTION select_option(
    p_request_public_id VARCHAR2,p_option_public_id VARCHAR2,p_actor_id NUMBER
  ) RETURN t_options;
END psq_service_pkg;
/

CREATE OR REPLACE PACKAGE BODY psq_service_pkg AS
  FUNCTION owned_request(
    p_public VARCHAR2,p_actor NUMBER
  ) RETURN pur_repository_pkg.t_request IS
    q pur_repository_pkg.t_request;p BEX_PROFILE%ROWTYPE;
  BEGIN
    BEGIN q:=pur_repository_pkg.get_request_by_public(p_public);
    EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_found;END;
    BEGIN p:=pfl_service_pkg.get_by_account_id(p_actor);
    EXCEPTION WHEN pfl_service_pkg.e_profile_not_found THEN RAISE e_forbidden;END;
    IF q.pfl_id<>p.pfl_id THEN RAISE e_forbidden;END IF;
    IF q.pur_status NOT IN('APPROVED','PARTIALLY_APPROVED') THEN RAISE e_not_ready;END IF;
    RETURN q;
  END;

  FUNCTION list_options(p_request NUMBER) RETURN t_options IS r t_options;
  BEGIN
    SELECT o.PSO_PUBLIC_ID,s.STR_PUBLIC_ID,s.STR_NAME,o.PSO_METHOD,
      o.PSO_PRICE,o.PSO_DISTANCE_KM,o.PSO_ESTIMATED_MIN_DAYS,
      o.PSO_ESTIMATED_MAX_DAYS,o.PSO_EXPIRES_AT,o.PSO_IS_SELECTED
    BULK COLLECT INTO r
    FROM BEX_PURCHASE_SHIPPING_OPTION o
    JOIN BEX_STORE s ON s.STR_ID=o.STR_ID
    WHERE o.PUR_ID=p_request AND o.PSO_STATUS='ACTIVE'
      AND o.PSO_EXPIRES_AT>SYSTIMESTAMP
    ORDER BY s.STR_NAME,
      CASE o.PSO_METHOD WHEN 'PICKUP' THEN 1 ELSE 2 END;
    RETURN r;
  END;

  PROCEDURE upsert_option(
    p_request NUMBER,p_store NUMBER,p_method VARCHAR2,p_price NUMBER,
    p_distance NUMBER,p_min_days NUMBER,p_max_days NUMBER,p_actor NUMBER
  ) IS
  BEGIN
    MERGE INTO BEX_PURCHASE_SHIPPING_OPTION o
    USING(SELECT p_request pur_id,p_store str_id,p_method method_code FROM dual) x
    ON(o.PUR_ID=x.pur_id AND o.STR_ID=x.str_id AND o.PSO_METHOD=x.method_code)
    WHEN MATCHED THEN UPDATE SET
      o.PSO_PRICE=p_price,o.PSO_DISTANCE_KM=p_distance,
      o.PSO_ESTIMATED_MIN_DAYS=p_min_days,
      o.PSO_ESTIMATED_MAX_DAYS=p_max_days,
      o.PSO_EXPIRES_AT=SYSTIMESTAMP+INTERVAL '30' MINUTE,
      o.PSO_STATUS='ACTIVE',o.PSO_UPDATED_AT=SYSTIMESTAMP,
      o.PSO_UPDATED_BY=p_actor
    WHEN NOT MATCHED THEN INSERT(
      PSO_PUBLIC_ID,PUR_ID,STR_ID,PSO_METHOD,PSO_PRICE,PSO_DISTANCE_KM,
      PSO_ESTIMATED_MIN_DAYS,PSO_ESTIMATED_MAX_DAYS,PSO_EXPIRES_AT,
      PSO_CREATED_BY,PSO_UPDATED_BY
    ) VALUES(
      LOWER(RAWTOHEX(SYS_GUID())),p_request,p_store,p_method,p_price,
      p_distance,p_min_days,p_max_days,SYSTIMESTAMP+INTERVAL '30' MINUTE,
      p_actor,p_actor
    );
  END;

  FUNCTION quote(p_request_public_id VARCHAR2,p_actor_id NUMBER)
    RETURN t_options IS
    q pur_repository_pkg.t_request;
    delivery_lat NUMBER;delivery_lon NUMBER;
    pickup_enabled NUMBER;local_enabled NUMBER;base_price NUMBER;
    price_per_km NUMBER;max_distance NUMBER;prep_days NUMBER;
    store_lat NUMBER;store_lon NUMBER;distance NUMBER;
  BEGIN
    q:=owned_request(p_request_public_id,p_actor_id);
    BEGIN
      SELECT PDL_LATITUDE,PDL_LONGITUDE INTO delivery_lat,delivery_lon
      FROM BEX_PURCHASE_DELIVERY
      WHERE PUR_ID=q.pur_id AND PDL_STATUS='ADDRESS_SELECTED';
    EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_ready;END;

    UPDATE BEX_PURCHASE_SHIPPING_OPTION SET PSO_STATUS='EXPIRED',
      PSO_IS_SELECTED=0,PSO_UPDATED_AT=SYSTIMESTAMP,PSO_UPDATED_BY=p_actor_id
    WHERE PUR_ID=q.pur_id AND PSO_EXPIRES_AT<=SYSTIMESTAMP;

    FOR store_row IN(
      SELECT DISTINCT i.STR_ID
      FROM BEX_PURCHASE_REQUEST_ITEM i
      WHERE i.PUR_ID=q.pur_id AND NVL(i.PRI_CONFIRMED_QUANTITY,0)>0
    ) LOOP
      BEGIN
        SELECT SSC_PICKUP_ENABLED,SSC_LOCAL_ENABLED,SSC_LOCAL_BASE_PRICE,
          SSC_LOCAL_PRICE_PER_KM,SSC_LOCAL_MAX_DISTANCE_KM,
          SSC_PREPARATION_DAYS
        INTO pickup_enabled,local_enabled,base_price,price_per_km,
          max_distance,prep_days
        FROM BEX_STORE_SHIPPING_CONFIG WHERE STR_ID=store_row.STR_ID;
      EXCEPTION WHEN NO_DATA_FOUND THEN
        pickup_enabled:=1;local_enabled:=1;base_price:=7;
        price_per_km:=1.8;max_distance:=20;prep_days:=1;
      END;

      IF pickup_enabled=1 THEN
        upsert_option(q.pur_id,store_row.STR_ID,'PICKUP',0,NULL,
          prep_days,prep_days+2,p_actor_id);
      END IF;

      IF local_enabled=1 AND delivery_lat IS NOT NULL AND delivery_lon IS NOT NULL THEN
        BEGIN
          SELECT STL_LATITUDE,STL_LONGITUDE INTO store_lat,store_lon
          FROM BEX_STORE_LOCATION WHERE STR_ID=store_row.STR_ID;
          distance:=ROUND(
            6371*ACOS(LEAST(1,GREATEST(-1,
              COS(delivery_lat*ACOS(-1)/180)*COS(store_lat*ACOS(-1)/180)
              *COS((store_lon-delivery_lon)*ACOS(-1)/180)
              +SIN(delivery_lat*ACOS(-1)/180)*SIN(store_lat*ACOS(-1)/180)
            ))),2
          );
          IF distance<=max_distance THEN
            upsert_option(q.pur_id,store_row.STR_ID,'LOCAL',
              ROUND(base_price+(distance*price_per_km),2),distance,
              prep_days+1,prep_days+3,p_actor_id);
          ELSE
            UPDATE BEX_PURCHASE_SHIPPING_OPTION SET PSO_STATUS='EXPIRED',
              PSO_IS_SELECTED=0,PSO_UPDATED_AT=SYSTIMESTAMP
            WHERE PUR_ID=q.pur_id AND STR_ID=store_row.STR_ID
              AND PSO_METHOD='LOCAL';
          END IF;
        EXCEPTION WHEN NO_DATA_FOUND THEN NULL;END;
      END IF;
    END LOOP;
    RETURN list_options(q.pur_id);
  END;

  FUNCTION select_option(
    p_request_public_id VARCHAR2,p_option_public_id VARCHAR2,p_actor_id NUMBER
  ) RETURN t_options IS
    q pur_repository_pkg.t_request;option_id NUMBER;store_id NUMBER;
  BEGIN
    q:=owned_request(p_request_public_id,p_actor_id);
    BEGIN
      SELECT PSO_ID,STR_ID INTO option_id,store_id
      FROM BEX_PURCHASE_SHIPPING_OPTION
      WHERE PSO_PUBLIC_ID=p_option_public_id AND PUR_ID=q.pur_id
        AND PSO_STATUS='ACTIVE' AND PSO_EXPIRES_AT>SYSTIMESTAMP
      FOR UPDATE;
    EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_not_found;END;
    UPDATE BEX_PURCHASE_SHIPPING_OPTION SET PSO_IS_SELECTED=0,
      PSO_UPDATED_AT=SYSTIMESTAMP,PSO_UPDATED_BY=p_actor_id
    WHERE PUR_ID=q.pur_id AND STR_ID=store_id AND PSO_IS_SELECTED=1;
    UPDATE BEX_PURCHASE_SHIPPING_OPTION SET PSO_IS_SELECTED=1,
      PSO_UPDATED_AT=SYSTIMESTAMP,PSO_UPDATED_BY=p_actor_id
    WHERE PSO_ID=option_id;
    RETURN list_options(q.pur_id);
  END;
END psq_service_pkg;
/

CREATE OR REPLACE PACKAGE psq_api_pkg AS
  PROCEDURE quote(p_request_public_id VARCHAR2,p_actor_id NUMBER,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE select_option(p_request_public_id VARCHAR2,p_body CLOB,
    p_actor_id NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
END psq_api_pkg;
/

CREATE OR REPLACE PACKAGE BODY psq_api_pkg AS
  e_bad EXCEPTION;
  FUNCTION js(p psq_service_pkg.t_option) RETURN JSON_OBJECT_T IS
    j JSON_OBJECT_T:=JSON_OBJECT_T();
  BEGIN
    core_json_pkg.put_string(j,'optionPublicId',TRIM(p.option_public_id));
    core_json_pkg.put_string(j,'storePublicId',TRIM(p.store_public_id));
    core_json_pkg.put_string(j,'storeName',p.store_name);
    core_json_pkg.put_string(j,'method',p.method_code);
    core_json_pkg.put_number(j,'price',p.price);
    IF p.distance_km IS NULL THEN core_json_pkg.put_null(j,'distanceKm');
    ELSE core_json_pkg.put_number(j,'distanceKm',p.distance_km);END IF;
    core_json_pkg.put_number(j,'estimatedMinDays',p.min_days);
    core_json_pkg.put_number(j,'estimatedMaxDays',p.max_days);
    core_json_pkg.put_string(j,'expiresAt',core_json_pkg.format_timestamp(p.expires_at));
    core_json_pkg.put_boolean(j,'isSelected',p.is_selected=1);
    RETURN j;
  END;
  FUNCTION array_json(p psq_service_pkg.t_options) RETURN JSON_ARRAY_T IS
    a JSON_ARRAY_T:=JSON_ARRAY_T();i PLS_INTEGER:=p.FIRST;
  BEGIN WHILE i IS NOT NULL LOOP core_json_pkg.append_element(a,js(p(i)));
    i:=p.NEXT(i);END LOOP;RETURN a;END;
  PROCEDURE err(s NUMBER,c VARCHAR2,m VARCHAR2,os OUT PLS_INTEGER,ob OUT NOCOPY CLOB) IS
    e core_error_pkg.t_public_error;p core_error_pkg.t_error_policy;
  BEGIN core_error_pkg.build_known_error(c,
    CASE WHEN s=404 THEN core_error_pkg.c_category_not_found
      WHEN s=403 THEN core_error_pkg.c_category_authorization
      ELSE core_error_pkg.c_category_validation END,
    m,core_error_pkg.c_severity_warn,FALSE,FALSE,e,p);
    ob:=core_response_pkg.build_error(e);os:=s;END;
  PROCEDURE quote(p_request_public_id VARCHAR2,p_actor_id NUMBER,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS r psq_service_pkg.t_options;
  BEGIN IF TRIM(p_request_public_id) IS NULL OR p_actor_id IS NULL THEN RAISE e_bad;END IF;
    r:=psq_service_pkg.quote(p_request_public_id,p_actor_id);
    o_body:=core_response_pkg.build_success(array_json(r));COMMIT;o_status:=200;
  EXCEPTION WHEN e_bad THEN ROLLBACK;err(400,'BEX-REQ-004','Valores obrigatorios.',o_status,o_body);
    WHEN psq_service_pkg.e_not_found THEN ROLLBACK;err(404,'BEX-PSQ-001','Solicitacao nao encontrada.',o_status,o_body);
    WHEN psq_service_pkg.e_forbidden THEN ROLLBACK;err(403,'BEX-PSQ-003','Operacao nao autorizada.',o_status,o_body);
    WHEN psq_service_pkg.e_not_ready THEN ROLLBACK;err(422,'BEX-PSQ-004','Confirme o endereco antes de calcular o frete.',o_status,o_body);
    WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=core_response_pkg.build_technical_error;END;
  PROCEDURE select_option(p_request_public_id VARCHAR2,p_body CLOB,
    p_actor_id NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS
    j JSON_OBJECT_T;r psq_service_pkg.t_options;option_id VARCHAR2(32);
  BEGIN IF TRIM(p_request_public_id) IS NULL OR p_actor_id IS NULL THEN RAISE e_bad;END IF;
    j:=core_json_pkg.parse_object(p_body);
    core_json_pkg.assert_allowed_attributes(j,'optionPublicId');
    option_id:=core_json_pkg.required_string(j,'optionPublicId');
    r:=psq_service_pkg.select_option(p_request_public_id,option_id,p_actor_id);
    o_body:=core_response_pkg.build_success(array_json(r));COMMIT;o_status:=200;
  EXCEPTION WHEN core_json_pkg.e_unknown_attribute OR core_json_pkg.e_invalid_json
      OR core_json_pkg.e_json_object_required OR core_json_pkg.e_required_attribute
      OR core_json_pkg.e_invalid_attribute_type OR e_bad
      THEN ROLLBACK;err(400,'BEX-REQ-002','Opcao de frete invalida.',o_status,o_body);
    WHEN psq_service_pkg.e_not_found THEN ROLLBACK;err(404,'BEX-PSQ-001','Opcao expirada ou inexistente.',o_status,o_body);
    WHEN psq_service_pkg.e_forbidden THEN ROLLBACK;err(403,'BEX-PSQ-003','Operacao nao autorizada.',o_status,o_body);
    WHEN psq_service_pkg.e_not_ready THEN ROLLBACK;err(422,'BEX-PSQ-004','Solicitacao indisponivel para frete.',o_status,o_body);
    WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=core_response_pkg.build_technical_error;END;
END psq_api_pkg;
/

PROMPT Shipping quote packages installed.
