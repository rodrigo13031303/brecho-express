CREATE OR REPLACE PACKAGE BODY stp_api_pkg AS
  PROCEDURE list_plans(o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB)IS xs stp_query_pkg.t_records;a JSON_ARRAY_T:=JSON_ARRAY_T();j JSON_OBJECT_T;i PLS_INTEGER;
  BEGIN xs:=stp_query_pkg.list_active;i:=xs.FIRST;WHILE i IS NOT NULL LOOP j:=JSON_OBJECT_T();
    core_json_pkg.put_string(j,'publicId',TRIM(xs(i).public_id));core_json_pkg.put_string(j,'code',xs(i).code);
    core_json_pkg.put_string(j,'name',xs(i).name);core_json_pkg.put_number(j,'price',xs(i).price);a.append(j);i:=xs.NEXT(i);END LOOP;
    o_status:=200;o_body:=core_response_pkg.build_success(a);EXCEPTION WHEN OTHERS THEN o_status:=500;o_body:=NULL;END;
END stp_api_pkg;
/
