CREATE OR REPLACE PACKAGE BODY shp_api_pkg AS
  FUNCTION js(p shp_service_pkg.t_record) RETURN JSON_OBJECT_T IS j JSON_OBJECT_T:=JSON_OBJECT_T();
    a JSON_ARRAY_T:=JSON_ARRAY_T();x JSON_OBJECT_T;i PLS_INTEGER:=p.items.FIRST;
  BEGIN core_json_pkg.put_string(j,'shipmentPublicId',TRIM(p.shipment_public_id));
    core_json_pkg.put_string(j,'orderPublicId',TRIM(p.order_public_id));core_json_pkg.put_string(j,'storePublicId',TRIM(p.store_public_id));
    core_json_pkg.put_string(j,'addressPublicId',TRIM(p.address_public_id));
    core_json_pkg.put_string(j,'deliveryProfilePublicId',TRIM(p.delivery_profile_public_id));
    core_json_pkg.put_string(j,'status',p.status);IF p.tracking_code IS NULL THEN core_json_pkg.put_null(j,'trackingCode');
    ELSE core_json_pkg.put_string(j,'trackingCode',p.tracking_code);END IF;
    WHILE i IS NOT NULL LOOP x:=JSON_OBJECT_T();core_json_pkg.put_string(x,'itemPublicId',TRIM(p.items(i).item_public_id));
      core_json_pkg.put_string(x,'orderItemPublicId',TRIM(p.items(i).order_item_public_id));
      core_json_pkg.put_number(x,'quantity',p.items(i).quantity);core_json_pkg.append_element(a,x);i:=p.items.NEXT(i);END LOOP;
    j.put('items',a);RETURN j;END;
  PROCEDURE create_shipment(p_body CLOB,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS
    j JSON_OBJECT_T;a JSON_ARRAY_T;ids shp_service_pkg.t_public_ids;r shp_service_pkg.t_record;
  BEGIN j:=JSON_OBJECT_T.parse(p_body);a:=j.get_array('orderItemPublicIds');
    FOR i IN 0..a.get_size-1 LOOP ids(ids.COUNT+1):=a.get_string(i);END LOOP;
    r:=shp_service_pkg.create_shipment(j.get_string('orderPublicId'),j.get_string('storePublicId'),
      j.get_string('addressPublicId'),j.get_string('deliveryProfilePublicId'),ids,NULL,p_actor);
    COMMIT;o_body:=core_response_pkg.build_success(js(r));o_status:=201;
  EXCEPTION WHEN shp_service_pkg.e_forbidden THEN ROLLBACK;o_status:=403;o_body:=NULL;
    WHEN shp_service_pkg.e_conflict THEN ROLLBACK;o_status:=409;o_body:=NULL;
    WHEN shp_service_pkg.e_invalid THEN ROLLBACK;o_status:=422;o_body:=NULL;
    WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=NULL;END;
  PROCEDURE get_shipment(p_public VARCHAR2,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS r shp_service_pkg.t_record;
  BEGIN r:=shp_service_pkg.get_shipment(p_public,p_actor);o_body:=core_response_pkg.build_success(js(r));o_status:=200;
  EXCEPTION WHEN shp_service_pkg.e_not_found THEN o_status:=404;o_body:=NULL;
    WHEN shp_service_pkg.e_forbidden THEN o_status:=403;o_body:=NULL;WHEN OTHERS THEN o_status:=500;o_body:=NULL;END;
  PROCEDURE change_status(p_public VARCHAR2,p_body CLOB,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS
    j JSON_OBJECT_T;r shp_service_pkg.t_record;
  BEGIN j:=JSON_OBJECT_T.parse(p_body);r:=shp_service_pkg.change_status(p_public,j.get_string('status'),
    j.get_string('trackingCode'),p_actor);COMMIT;o_body:=core_response_pkg.build_success(js(r));o_status:=200;
  EXCEPTION WHEN shp_service_pkg.e_not_found THEN ROLLBACK;o_status:=404;o_body:=NULL;
    WHEN shp_service_pkg.e_forbidden THEN ROLLBACK;o_status:=403;o_body:=NULL;
    WHEN shp_service_pkg.e_invalid THEN ROLLBACK;o_status:=422;o_body:=NULL;
    WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=NULL;END;
END shp_api_pkg;
/
