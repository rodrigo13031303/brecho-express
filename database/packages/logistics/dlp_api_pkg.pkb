CREATE OR REPLACE PACKAGE BODY dlp_api_pkg AS
  FUNCTION js(p dlp_service_pkg.t_record) RETURN JSON_OBJECT_T IS j JSON_OBJECT_T:=JSON_OBJECT_T();
  BEGIN core_json_pkg.put_string(j,'deliveryProfilePublicId',TRIM(p.dlp_public_id));
    core_json_pkg.put_string(j,'code',p.dlp_code);core_json_pkg.put_string(j,'name',p.dlp_name);
    IF p.dlp_description IS NULL THEN core_json_pkg.put_null(j,'description');
    ELSE core_json_pkg.put_string(j,'description',p.dlp_description);END IF;
    IF p.dlp_base_price IS NULL THEN core_json_pkg.put_null(j,'basePrice');
    ELSE core_json_pkg.put_number(j,'basePrice',p.dlp_base_price);END IF;
    core_json_pkg.put_boolean(j,'isExpress',p.dlp_is_express=1);
    core_json_pkg.put_string(j,'status',p.dlp_status);RETURN j;END;
  PROCEDURE get_profile(p_public VARCHAR2,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS r dlp_service_pkg.t_record;
  BEGIN r:=dlp_service_pkg.get_profile(p_public);o_body:=core_response_pkg.build_success(js(r));o_status:=200;
  EXCEPTION WHEN dlp_service_pkg.e_not_found THEN o_status:=404;o_body:=NULL;
    WHEN OTHERS THEN o_status:=500;o_body:=NULL;END;
  PROCEDURE list_profiles(p_status VARCHAR2,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS
    r dlp_service_pkg.t_table;a JSON_ARRAY_T:=JSON_ARRAY_T();i PLS_INTEGER;
  BEGIN r:=dlp_service_pkg.list_profiles(NVL(p_status,'ACTIVE'));i:=r.FIRST;WHILE i IS NOT NULL LOOP
    core_json_pkg.append_element(a,js(r(i)));i:=r.NEXT(i);END LOOP;
    o_body:=core_response_pkg.build_success(a);o_status:=200;
  EXCEPTION WHEN dlp_service_pkg.e_invalid THEN o_status:=422;o_body:=NULL;
    WHEN OTHERS THEN o_status:=500;o_body:=NULL;END;
END dlp_api_pkg;
/
