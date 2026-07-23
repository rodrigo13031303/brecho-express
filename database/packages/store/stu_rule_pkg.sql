CREATE OR REPLACE PACKAGE stu_rule_pkg AS
  SUBTYPE t_role   IS VARCHAR2(50);
  SUBTYPE t_status IS VARCHAR2(20);

  c_role_admin        CONSTANT t_role := 'ADMIN';
  c_role_manager      CONSTANT t_role := 'MANAGER';
  c_role_attendant    CONSTANT t_role := 'ATTENDANT';
  c_role_collaborator CONSTANT t_role := 'COLLABORATOR';

  c_status_active   CONSTANT t_status := 'ACTIVE';
  c_status_inactive CONSTANT t_status := 'INACTIVE';

  c_code_invalid_role       CONSTANT core_error_pkg.t_error_code :=
    'BEX-STU-001';
  c_code_invalid_status     CONSTANT core_error_pkg.t_error_code :=
    'BEX-STU-002';
  c_code_invalid_transition CONSTANT core_error_pkg.t_error_code :=
    'BEX-STU-003';

  e_invalid_role       EXCEPTION;
  e_invalid_status     EXCEPTION;
  e_invalid_transition EXCEPTION;

  FUNCTION normalize_role(
    p_role IN VARCHAR2
  ) RETURN t_role;

  FUNCTION normalize_status(
    p_status IN VARCHAR2
  ) RETURN t_status;

  FUNCTION is_valid_role(
    p_role IN VARCHAR2
  ) RETURN BOOLEAN;

  FUNCTION is_valid_status(
    p_status IN VARCHAR2
  ) RETURN BOOLEAN;

  PROCEDURE require_valid_role(
    p_role IN VARCHAR2
  );

  PROCEDURE require_valid_status(
    p_status IN VARCHAR2
  );

  PROCEDURE validate_transition(
    p_old_status IN VARCHAR2,
    p_new_status IN VARCHAR2
  );

  PROCEDURE build_known_error(
    p_code         IN core_error_pkg.t_error_code,
    o_public_error OUT NOCOPY core_error_pkg.t_public_error,
    o_error_policy OUT NOCOPY core_error_pkg.t_error_policy
  );
END stu_rule_pkg;
/

CREATE OR REPLACE PACKAGE BODY stu_rule_pkg AS
  FUNCTION normalize_role(
    p_role IN VARCHAR2
  ) RETURN t_role IS
  BEGIN
    RETURN UPPER(TRIM(p_role));
  END normalize_role;

  FUNCTION normalize_status(
    p_status IN VARCHAR2
  ) RETURN t_status IS
  BEGIN
    RETURN UPPER(TRIM(p_status));
  END normalize_status;

  FUNCTION is_valid_role(
    p_role IN VARCHAR2
  ) RETURN BOOLEAN IS
    l_role t_role;
  BEGIN
    l_role := normalize_role(p_role);

    RETURN l_role IS NOT NULL
       AND l_role IN (
             c_role_admin,
             c_role_manager,
             c_role_attendant,
             c_role_collaborator
           );
  END is_valid_role;

  FUNCTION is_valid_status(
    p_status IN VARCHAR2
  ) RETURN BOOLEAN IS
    l_status t_status;
  BEGIN
    l_status := normalize_status(p_status);

    RETURN l_status IS NOT NULL
       AND l_status IN (
             c_status_active,
             c_status_inactive
           );
  END is_valid_status;

  PROCEDURE require_valid_role(
    p_role IN VARCHAR2
  ) IS
  BEGIN
    IF NOT is_valid_role(p_role) THEN
      RAISE e_invalid_role;
    END IF;
  END require_valid_role;

  PROCEDURE require_valid_status(
    p_status IN VARCHAR2
  ) IS
  BEGIN
    IF NOT is_valid_status(p_status) THEN
      RAISE e_invalid_status;
    END IF;
  END require_valid_status;

  PROCEDURE validate_transition(
    p_old_status IN VARCHAR2,
    p_new_status IN VARCHAR2
  ) IS
    l_old_status t_status;
    l_new_status t_status;
  BEGIN
    require_valid_status(p_old_status);
    require_valid_status(p_new_status);

    l_old_status := normalize_status(p_old_status);
    l_new_status := normalize_status(p_new_status);

    IF l_old_status = l_new_status
       OR (l_old_status = c_status_active
           AND l_new_status = c_status_inactive)
       OR (l_old_status = c_status_inactive
           AND l_new_status = c_status_active) THEN
      RETURN;
    END IF;

    RAISE e_invalid_transition;
  END validate_transition;

  PROCEDURE build_known_error(
    p_code         IN core_error_pkg.t_error_code,
    o_public_error OUT NOCOPY core_error_pkg.t_public_error,
    o_error_policy OUT NOCOPY core_error_pkg.t_error_policy
  ) IS
    l_category core_error_pkg.t_category;
    l_message  core_error_pkg.t_external_message;
  BEGIN
    CASE p_code
      WHEN c_code_invalid_role THEN
        l_category := core_error_pkg.c_category_validation;
        l_message := 'O papel do usuario da STORE e invalido.';
      WHEN c_code_invalid_status THEN
        l_category := core_error_pkg.c_category_validation;
        l_message := 'O status do usuario da STORE e invalido.';
      WHEN c_code_invalid_transition THEN
        l_category := core_error_pkg.c_category_business;
        l_message := 'A transicao de status do usuario da STORE e invalida.';
      ELSE
        RAISE VALUE_ERROR;
    END CASE;

    core_error_pkg.build_known_error(
      p_code             => p_code,
      p_category         => l_category,
      p_external_message => l_message,
      p_severity         => core_error_pkg.c_severity_error,
      p_retryable        => FALSE,
      p_should_log       => FALSE,
      o_public_error     => o_public_error,
      o_error_policy     => o_error_policy
    );
  END build_known_error;
END stu_rule_pkg;
/
