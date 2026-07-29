WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT Installing store shipping configuration API...

CREATE OR REPLACE PACKAGE ssc_api_pkg AS
  PROCEDURE get_config(
    p_store_public_id VARCHAR2,p_actor_id NUMBER,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB
  );
  PROCEDURE save_config(
    p_store_public_id VARCHAR2,p_body CLOB,p_actor_id NUMBER,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB
  );
END ssc_api_pkg;
/

CREATE OR REPLACE PACKAGE BODY ssc_api_pkg AS
  e_bad EXCEPTION;e_forbidden EXCEPTION;

  FUNCTION store_id(p_public VARCHAR2,p_actor NUMBER) RETURN NUMBER IS id NUMBER;
  BEGIN
    SELECT STR_ID INTO id FROM BEX_STORE
    WHERE STR_PUBLIC_ID=LOWER(TRIM(p_public)) AND ACC_ID=p_actor
      AND STR_STATUS IN('DRAFT','ACTIVE');
    RETURN id;
  EXCEPTION WHEN NO_DATA_FOUND THEN RAISE e_forbidden;END;

  FUNCTION config_json(p_store NUMBER) RETURN JSON_OBJECT_T IS
    pickup NUMBER:=1;local_delivery NUMBER:=1;base_price NUMBER:=7;
    price_per_km NUMBER:=1.8;max_distance NUMBER:=20;preparation_days NUMBER:=1;
    j JSON_OBJECT_T:=JSON_OBJECT_T();
  BEGIN
    BEGIN
      SELECT SSC_PICKUP_ENABLED,SSC_LOCAL_ENABLED,SSC_LOCAL_BASE_PRICE,
        SSC_LOCAL_PRICE_PER_KM,SSC_LOCAL_MAX_DISTANCE_KM,SSC_PREPARATION_DAYS
      INTO pickup,local_delivery,base_price,price_per_km,max_distance,
        preparation_days
      FROM BEX_STORE_SHIPPING_CONFIG WHERE STR_ID=p_store;
    EXCEPTION WHEN NO_DATA_FOUND THEN NULL;END;
    core_json_pkg.put_boolean(j,'pickupEnabled',pickup=1);
    core_json_pkg.put_boolean(j,'localDeliveryEnabled',local_delivery=1);
    core_json_pkg.put_number(j,'localBasePrice',base_price);
    core_json_pkg.put_number(j,'localPricePerKm',price_per_km);
    core_json_pkg.put_number(j,'localMaxDistanceKm',max_distance);
    core_json_pkg.put_number(j,'preparationDays',preparation_days);
    RETURN j;
  END;

  PROCEDURE error_response(
    p_status NUMBER,p_code VARCHAR2,p_message VARCHAR2,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB
  ) IS e core_error_pkg.t_public_error;p core_error_pkg.t_error_policy;
  BEGIN
    core_error_pkg.build_known_error(
      p_code,
      CASE WHEN p_status=403 THEN core_error_pkg.c_category_authorization
        ELSE core_error_pkg.c_category_validation END,
      p_message,core_error_pkg.c_severity_warn,FALSE,FALSE,e,p
    );
    o_body:=core_response_pkg.build_error(e);o_status:=p_status;
  END;

  PROCEDURE get_config(
    p_store_public_id VARCHAR2,p_actor_id NUMBER,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB
  ) IS id NUMBER;
  BEGIN
    IF TRIM(p_store_public_id) IS NULL OR p_actor_id IS NULL THEN RAISE e_bad;END IF;
    id:=store_id(p_store_public_id,p_actor_id);
    o_body:=core_response_pkg.build_success(config_json(id));o_status:=200;
  EXCEPTION
    WHEN e_bad THEN error_response(400,'BEX-REQ-004','Valores obrigatorios.',o_status,o_body);
    WHEN e_forbidden THEN error_response(403,'BEX-SSC-003','Operacao nao autorizada.',o_status,o_body);
    WHEN OTHERS THEN o_status:=500;o_body:=core_response_pkg.build_technical_error;
  END;

  PROCEDURE save_config(
    p_store_public_id VARCHAR2,p_body CLOB,p_actor_id NUMBER,
    o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB
  ) IS
    id NUMBER;j JSON_OBJECT_T;pickup NUMBER;local_delivery NUMBER;
    base_price NUMBER;price_per_km NUMBER;max_distance NUMBER;
    preparation_days NUMBER;
  BEGIN
    IF TRIM(p_store_public_id) IS NULL OR p_actor_id IS NULL THEN RAISE e_bad;END IF;
    id:=store_id(p_store_public_id,p_actor_id);
    j:=core_json_pkg.parse_object(p_body);
    core_json_pkg.assert_allowed_attributes(
      j,'pickupEnabled,localDeliveryEnabled,localBasePrice,localPricePerKm,localMaxDistanceKm,preparationDays'
    );
    pickup:=CASE WHEN core_json_pkg.required_boolean(j,'pickupEnabled') THEN 1 ELSE 0 END;
    local_delivery:=CASE WHEN core_json_pkg.required_boolean(j,'localDeliveryEnabled') THEN 1 ELSE 0 END;
    base_price:=core_json_pkg.required_number(j,'localBasePrice');
    price_per_km:=core_json_pkg.required_number(j,'localPricePerKm');
    max_distance:=core_json_pkg.required_number(j,'localMaxDistanceKm');
    preparation_days:=core_json_pkg.required_number(j,'preparationDays');
    IF pickup=0 AND local_delivery=0 OR base_price<0 OR price_per_km<0
      OR max_distance<=0 OR max_distance>500
      OR preparation_days<0 OR preparation_days>90
      OR preparation_days<>TRUNC(preparation_days)
    THEN RAISE e_bad;END IF;

    MERGE INTO BEX_STORE_SHIPPING_CONFIG c
    USING(SELECT id str_id FROM dual) x ON(c.STR_ID=x.str_id)
    WHEN MATCHED THEN UPDATE SET
      c.SSC_PICKUP_ENABLED=pickup,c.SSC_LOCAL_ENABLED=local_delivery,
      c.SSC_LOCAL_BASE_PRICE=base_price,c.SSC_LOCAL_PRICE_PER_KM=price_per_km,
      c.SSC_LOCAL_MAX_DISTANCE_KM=max_distance,
      c.SSC_PREPARATION_DAYS=preparation_days,
      c.SSC_UPDATED_AT=SYSTIMESTAMP,c.SSC_UPDATED_BY=p_actor_id
    WHEN NOT MATCHED THEN INSERT(
      STR_ID,SSC_PICKUP_ENABLED,SSC_LOCAL_ENABLED,SSC_LOCAL_BASE_PRICE,
      SSC_LOCAL_PRICE_PER_KM,SSC_LOCAL_MAX_DISTANCE_KM,
      SSC_PREPARATION_DAYS,SSC_UPDATED_BY
    ) VALUES(
      id,pickup,local_delivery,base_price,price_per_km,max_distance,
      preparation_days,p_actor_id
    );
    UPDATE BEX_PURCHASE_SHIPPING_OPTION SET PSO_STATUS='EXPIRED',
      PSO_IS_SELECTED=0,PSO_UPDATED_AT=SYSTIMESTAMP,PSO_UPDATED_BY=p_actor_id
    WHERE STR_ID=id AND PSO_STATUS='ACTIVE';
    o_body:=core_response_pkg.build_success(config_json(id));COMMIT;o_status:=200;
  EXCEPTION
    WHEN core_json_pkg.e_unknown_attribute OR core_json_pkg.e_invalid_json
      OR core_json_pkg.e_json_object_required OR core_json_pkg.e_required_attribute
      OR core_json_pkg.e_invalid_attribute_type OR e_bad
      THEN ROLLBACK;error_response(400,'BEX-SSC-002','Configuracao de frete invalida.',o_status,o_body);
    WHEN e_forbidden THEN ROLLBACK;error_response(403,'BEX-SSC-003','Operacao nao autorizada.',o_status,o_body);
    WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=core_response_pkg.build_technical_error;
  END;
END ssc_api_pkg;
/

PROMPT Store shipping configuration API installed.
