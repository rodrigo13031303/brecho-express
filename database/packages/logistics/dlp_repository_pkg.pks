CREATE OR REPLACE PACKAGE dlp_repository_pkg AS
  TYPE t_row IS RECORD(dlp_id NUMBER,dlp_public_id CHAR(32),dlp_code VARCHAR2(50),
    dlp_name VARCHAR2(100),dlp_description VARCHAR2(500),dlp_base_price NUMBER,
    dlp_max_distance_km NUMBER,dlp_max_weight_kg NUMBER,dlp_is_express NUMBER,
    dlp_status VARCHAR2(20),dlp_created_at TIMESTAMP,dlp_updated_at TIMESTAMP);
  TYPE t_rows IS TABLE OF t_row INDEX BY PLS_INTEGER;
  PROCEDURE insert_row(p t_row,p_actor NUMBER,o_id OUT NUMBER);
  FUNCTION by_public(p VARCHAR2) RETURN t_row;FUNCTION by_id(p NUMBER) RETURN t_row;
  FUNCTION list_rows(p_status VARCHAR2 DEFAULT NULL) RETURN t_rows;
END dlp_repository_pkg;
/
