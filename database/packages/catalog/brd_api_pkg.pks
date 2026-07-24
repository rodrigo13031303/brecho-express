CREATE OR REPLACE PACKAGE brd_api_pkg AS
  PROCEDURE get_brand(p_brand_public_id VARCHAR2,o_status_code OUT PLS_INTEGER,o_response_body OUT NOCOPY CLOB);
  PROCEDURE get_brand_by_slug(p_slug VARCHAR2,o_status_code OUT PLS_INTEGER,o_response_body OUT NOCOPY CLOB);
  PROCEDURE list_brands(o_status_code OUT PLS_INTEGER,o_response_body OUT NOCOPY CLOB);
END brd_api_pkg;
/
