CREATE OR REPLACE PACKAGE cat_api_pkg AS
  -- Fronteira publica somente leitura de CATEGORY.
  -- Pressupoe Core Context inicializado pelo handler ORDS.

  PROCEDURE get_category(
    p_category_public_id IN  VARCHAR2,
    o_status_code        OUT PLS_INTEGER,
    o_response_body      OUT NOCOPY CLOB
  );

  PROCEDURE get_category_by_slug(
    p_slug          IN  VARCHAR2,
    o_status_code   OUT PLS_INTEGER,
    o_response_body OUT NOCOPY CLOB
  );

  PROCEDURE list_categories(
    o_status_code   OUT PLS_INTEGER,
    o_response_body OUT NOCOPY CLOB
  );
END cat_api_pkg;
/
