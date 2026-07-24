CREATE OR REPLACE PACKAGE BODY ppr_api_pkg AS
  FUNCTION js(p ppr_service_pkg.t_record) RETURN JSON_OBJECT_T IS j JSON_OBJECT_T:=JSON_OBJECT_T();
  BEGIN core_json_pkg.put_string(j,'providerPublicId',TRIM(p.ppr_public_id));
    core_json_pkg.put_string(j,'code',p.ppr_code);core_json_pkg.put_string(j,'name',p.ppr_name);
    core_json_pkg.put_string(j,'status',p.ppr_status);RETURN j;END;
  PROCEDURE get_provider(p_public VARCHAR2,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS r ppr_service_pkg.t_record;
  BEGIN r:=ppr_service_pkg.get_provider(p_public);o_body:=core_response_pkg.build_success(js(r));o_status:=200;
  EXCEPTION WHEN ppr_service_pkg.e_not_found THEN o_status:=404;o_body:=NULL;WHEN OTHERS THEN o_status:=500;o_body:=NULL;END;
  PROCEDURE list_providers(o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB) IS r ppr_service_pkg.t_table;
    a JSON_ARRAY_T:=JSON_ARRAY_T();i PLS_INTEGER;
  BEGIN r:=ppr_service_pkg.list_active;i:=r.FIRST;WHILE i IS NOT NULL LOOP core_json_pkg.append_element(a,js(r(i)));i:=r.NEXT(i);END LOOP;
    o_body:=core_response_pkg.build_success(a);o_status:=200;EXCEPTION WHEN OTHERS THEN o_status:=500;o_body:=NULL;END;
END ppr_api_pkg;
/
