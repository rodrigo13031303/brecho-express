CREATE OR REPLACE PACKAGE dlp_api_pkg AS
  PROCEDURE get_profile(p_public VARCHAR2,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
  PROCEDURE list_profiles(p_status VARCHAR2,o_status OUT PLS_INTEGER,o_body OUT NOCOPY CLOB);
END dlp_api_pkg;
/
