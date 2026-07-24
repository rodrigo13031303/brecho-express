CREATE OR REPLACE PACKAGE stp_api_pkg AS
  PROCEDURE list_plans(o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
END stp_api_pkg;
/
