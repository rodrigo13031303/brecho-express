CREATE OR REPLACE PACKAGE BODY rat_api_pkg AS
  PROCEDURE add_attachment(p_request VARCHAR2,p_body CLOB,p_actor NUMBER,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB)IS
    j JSON_OBJECT_T;r rat_service_pkg.t_record;x JSON_OBJECT_T:=JSON_OBJECT_T();
  BEGIN j:=JSON_OBJECT_T.parse(p_body);r:=rat_service_pkg.add_attachment(p_request,j.get_string('type'),j.get_string('url'),
    j.get_string('filename'),j.get_string('mimeType'),j.get_number('sizeBytes'),j.get_string('description'),p_actor);
    core_json_pkg.put_string(x,'attachmentPublicId',TRIM(r.rat_public_id));core_json_pkg.put_string(x,'type',r.attachment_type);
    core_json_pkg.put_string(x,'url',r.attachment_url);COMMIT;o_status:=201;o_body:=core_response_pkg.build_success(x);
  EXCEPTION WHEN rat_service_pkg.e_not_found THEN ROLLBACK;o_status:=404;o_body:=NULL;WHEN rat_service_pkg.e_forbidden THEN ROLLBACK;o_status:=403;o_body:=NULL;
    WHEN rat_service_pkg.e_invalid THEN ROLLBACK;o_status:=422;o_body:=NULL;WHEN OTHERS THEN ROLLBACK;o_status:=500;o_body:=NULL;END;
END rat_api_pkg;
/
