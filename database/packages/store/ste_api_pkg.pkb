CREATE OR REPLACE PACKAGE BODY ste_api_pkg AS
  PROCEDURE create_event(p_store VARCHAR2,p_body CLOB,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB)IS
    j JSON_OBJECT_T;x JSON_OBJECT_T:=JSON_OBJECT_T();r ste_service_pkg.t_record;
  BEGIN j:=JSON_OBJECT_T.parse(p_body);r:=ste_service_pkg.create_event(p_store,j.get_string('name'),j.get_string('description'),
    TO_TIMESTAMP_TZ(j.get_string('startAt'),'YYYY-MM-DD\"T\"HH24:MI:SSTZH:TZM'),TO_TIMESTAMP_TZ(j.get_string('endAt'),'YYYY-MM-DD\"T\"HH24:MI:SSTZH:TZM'),p_actor);
    core_json_pkg.put_string(x,'eventPublicId',TRIM(r.public_id));core_json_pkg.put_string(x,'name',r.event_name);core_json_pkg.put_string(x,'status',r.status);
    COMMIT;o_status:=201;o_body:=core_response_pkg.build_success(x);
  EXCEPTION WHEN ste_service_pkg.e_forbidden THEN ROLLBACK;o_status:=403;o_body:=NULL;WHEN ste_service_pkg.e_invalid THEN ROLLBACK;o_status:=422;o_body:=NULL;
    WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=NULL;END;
END ste_api_pkg;
/
