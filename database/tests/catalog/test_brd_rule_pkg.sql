SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
  l_creation brd_rule_pkg.t_brand_creation;
  l_count PLS_INTEGER;
  l_raised BOOLEAN;
  PROCEDURE fail(p VARCHAR2) IS BEGIN RAISE_APPLICATION_ERROR(-20999,p); END;
  PROCEDURE ok(p BOOLEAN,m VARCHAR2) IS BEGIN IF p IS NULL OR NOT p THEN fail(m); END IF; END;
BEGIN
  SELECT COUNT(*) INTO l_count FROM USER_OBJECTS
   WHERE OBJECT_NAME='BRD_RULE_PKG' AND STATUS='VALID'
     AND OBJECT_TYPE IN ('PACKAGE','PACKAGE BODY');
  ok(l_count=2,'Package invalida.');
  SELECT COUNT(*) INTO l_count FROM USER_ERRORS WHERE NAME='BRD_RULE_PKG';
  ok(l_count=0,'Package possui erros.');
  ok(brd_rule_pkg.normalize_name('  Minha   Marca ')='Minha Marca','Nome.');
  ok(
    brd_rule_pkg.normalize_slug(
      ' Marca '||UNISTR('\00DAnica')||' & Nacional '
    )='marca-unica-nacional',
    'Slug.'
  );
  l_raised:=FALSE;
  BEGIN brd_rule_pkg.validate_name(' ');
  EXCEPTION WHEN brd_rule_pkg.e_name_required THEN l_raised:=TRUE; END;
  ok(l_raised,'Nome vazio.');
  l_raised:=FALSE;
  BEGIN brd_rule_pkg.validate_slug('!!!');
  EXCEPTION WHEN brd_rule_pkg.e_slug_required THEN l_raised:=TRUE; END;
  ok(l_raised,'Slug vazio.');
  l_raised:=FALSE;
  BEGIN brd_rule_pkg.validate_description(RPAD('x',1001,'x'));
  EXCEPTION WHEN brd_rule_pkg.e_invalid_description THEN l_raised:=TRUE; END;
  ok(l_raised,'Descricao longa.');
  ok(
    brd_rule_pkg.normalize_status(' active ')='ACTIVE',
    'Status.'
  );
  l_raised:=FALSE;
  BEGIN brd_rule_pkg.validate_status('BLOCKED');
  EXCEPTION WHEN brd_rule_pkg.e_invalid_status THEN l_raised:=TRUE; END;
  ok(l_raised,'Status invalido.');
  brd_rule_pkg.validate_status_transition('ACTIVE','INACTIVE');
  l_raised:=FALSE;
  BEGIN brd_rule_pkg.validate_status_transition('ACTIVE',' active ');
  EXCEPTION WHEN brd_rule_pkg.e_invalid_transition THEN l_raised:=TRUE; END;
  ok(l_raised,'Transicao igual.');
  l_creation.name_value:='  Marca   Circular ';
  l_creation.slug_value:=' Marca Circular ';
  l_creation.description_value:='  Descricao  ';
  l_creation.status_value:=' active ';
  brd_rule_pkg.normalize_and_validate_creation(l_creation);
  ok(
    l_creation.name_value='Marca Circular'
    AND l_creation.slug_value='marca-circular'
    AND l_creation.description_value='Descricao'
    AND l_creation.status_value='ACTIVE',
    'Criacao.'
  );
  SELECT COUNT(*) INTO l_count FROM USER_SOURCE
   WHERE NAME='BRD_RULE_PKG'
     AND REGEXP_LIKE(
       UPPER(TEXT),
       '(^|[^A-Z_])(SELECT|INSERT|UPDATE|DELETE|MERGE|COMMIT|ROLLBACK)([^A-Z_]|$)|CORE_|JSON|HTTP'
     );
  ok(l_count=0,'Dependencia proibida.');
  DBMS_OUTPUT.PUT_LINE('BRD_RULE_PKG: PASSED');
END;
/
