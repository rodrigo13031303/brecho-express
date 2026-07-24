SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
  l_creation prd_rule_pkg.t_product_creation;
  l_patch prd_rule_pkg.t_product_patch;
  l_count PLS_INTEGER; l_raised BOOLEAN;
  PROCEDURE fail(p VARCHAR2) IS BEGIN RAISE_APPLICATION_ERROR(-20999,p); END;
  PROCEDURE ok(p BOOLEAN,m VARCHAR2) IS BEGIN IF p IS NULL OR NOT p THEN fail(m); END IF; END;
BEGIN
  SELECT COUNT(*) INTO l_count FROM USER_OBJECTS
   WHERE OBJECT_NAME='PRD_RULE_PKG' AND STATUS='VALID'
     AND OBJECT_TYPE IN ('PACKAGE','PACKAGE BODY');
  ok(l_count=2,'PASS 01 - Package invalida.');
  SELECT COUNT(*) INTO l_count FROM USER_ERRORS WHERE NAME='PRD_RULE_PKG';
  ok(l_count=0,'PASS 02 - Package possui erros.');

  ok(prd_rule_pkg.normalize_title('  Achado   Especial ')='Achado Especial',
     'PASS 03 - Titulo.');
  ok(prd_rule_pkg.normalize_slug(
       ' Achado '||UNISTR('\00DAnico')||' & Azul '
     )='achado-unico-azul','PASS 04 - Slug.');
  ok(prd_rule_pkg.normalize_description('  Descricao  ')='Descricao',
     'PASS 05 - Descricao.');
  ok(prd_rule_pkg.normalize_condition(' like_new ')='LIKE_NEW',
     'PASS 06 - Condicao.');
  ok(prd_rule_pkg.normalize_status(' active ')='ACTIVE','PASS 07 - Status.');

  l_raised:=FALSE;
  BEGIN prd_rule_pkg.validate_title(' ');
  EXCEPTION WHEN prd_rule_pkg.e_title_required THEN l_raised:=TRUE; END;
  ok(l_raised,'PASS 08 - Titulo obrigatorio.');
  l_raised:=FALSE;
  BEGIN prd_rule_pkg.validate_title(RPAD('x',201,'x'));
  EXCEPTION WHEN prd_rule_pkg.e_invalid_title THEN l_raised:=TRUE; END;
  ok(l_raised,'PASS 09 - Limite titulo.');
  l_raised:=FALSE;
  BEGIN prd_rule_pkg.validate_slug('!!!');
  EXCEPTION WHEN prd_rule_pkg.e_slug_required THEN l_raised:=TRUE; END;
  ok(l_raised,'PASS 10 - Slug obrigatorio.');
  l_raised:=FALSE;
  BEGIN prd_rule_pkg.validate_description(RPAD('x',4001,'x'));
  EXCEPTION WHEN prd_rule_pkg.e_invalid_description THEN l_raised:=TRUE; END;
  ok(l_raised,'PASS 11 - Limite descricao.');

  prd_rule_pkg.validate_price(0);
  l_raised:=FALSE;
  BEGIN prd_rule_pkg.validate_price(-0.01);
  EXCEPTION WHEN prd_rule_pkg.e_invalid_price THEN l_raised:=TRUE; END;
  ok(l_raised,'PASS 12 - Preco.');
  prd_rule_pkg.validate_quantity(0);
  l_raised:=FALSE;
  BEGIN prd_rule_pkg.validate_quantity(1.5);
  EXCEPTION WHEN prd_rule_pkg.e_invalid_quantity THEN l_raised:=TRUE; END;
  ok(l_raised,'PASS 13 - Quantidade inteira.');
  l_raised:=FALSE;
  BEGIN prd_rule_pkg.validate_condition('USED');
  EXCEPTION WHEN prd_rule_pkg.e_invalid_condition THEN l_raised:=TRUE; END;
  ok(l_raised,'PASS 14 - Condicao invalida.');

  prd_rule_pkg.validate_measurements(NULL,NULL,NULL,NULL);
  prd_rule_pkg.validate_measurements(0.5,10,20,30);
  l_raised:=FALSE;
  BEGIN prd_rule_pkg.validate_measurements(0,10,20,30);
  EXCEPTION WHEN prd_rule_pkg.e_invalid_weight THEN l_raised:=TRUE; END;
  ok(l_raised,'PASS 15 - Peso.');
  l_raised:=FALSE;
  BEGIN prd_rule_pkg.validate_measurements(NULL,10,NULL,30);
  EXCEPTION WHEN prd_rule_pkg.e_invalid_dimensions THEN l_raised:=TRUE; END;
  ok(l_raised,'PASS 16 - Dimensoes completas.');

  l_raised:=FALSE;
  BEGIN prd_rule_pkg.validate_status('RESERVED');
  EXCEPTION WHEN prd_rule_pkg.e_invalid_status THEN l_raised:=TRUE; END;
  ok(l_raised,'PASS 17 - Status invalido.');
  prd_rule_pkg.validate_status_transition('DRAFT','ACTIVE',1);
  prd_rule_pkg.validate_status_transition('DRAFT','ARCHIVED',0);
  prd_rule_pkg.validate_status_transition('ACTIVE','INACTIVE',1);
  prd_rule_pkg.validate_status_transition('ACTIVE','SOLD',0);
  prd_rule_pkg.validate_status_transition('ACTIVE','ARCHIVED',1);
  prd_rule_pkg.validate_status_transition('INACTIVE','ACTIVE',1);
  prd_rule_pkg.validate_status_transition('INACTIVE','ARCHIVED',0);
  prd_rule_pkg.validate_status_transition('SOLD','ACTIVE',1);
  prd_rule_pkg.validate_status_transition('SOLD','ARCHIVED',0);
  l_raised:=FALSE;
  BEGIN prd_rule_pkg.validate_status_transition('DRAFT','ACTIVE',0);
  EXCEPTION WHEN prd_rule_pkg.e_activation_no_stock THEN l_raised:=TRUE; END;
  ok(l_raised,'PASS 18 - Ativacao exige estoque.');
  l_raised:=FALSE;
  BEGIN prd_rule_pkg.validate_status_transition('ARCHIVED','ACTIVE',1);
  EXCEPTION WHEN prd_rule_pkg.e_invalid_transition THEN l_raised:=TRUE; END;
  ok(l_raised,'PASS 19 - ARCHIVED terminal.');

  l_creation.title_value:='  Vestido   Circular ';
  l_creation.slug_value:=' Vestido Circular ';
  l_creation.description_value:='  Excelente  ';
  l_creation.price_value:=49.90;
  l_creation.quantity_value:=1;
  l_creation.condition_value:=' good ';
  l_creation.weight_value:=NULL;
  l_creation.width_value:=NULL;
  l_creation.height_value:=NULL;
  l_creation.length_value:=NULL;
  l_creation.status_value:='ACTIVE';
  prd_rule_pkg.normalize_and_validate_creation(l_creation);
  ok(l_creation.title_value='Vestido Circular'
     AND l_creation.slug_value='vestido-circular'
     AND l_creation.description_value='Excelente'
     AND l_creation.condition_value='GOOD'
     AND l_creation.status_value='DRAFT','PASS 20 - Criacao.');

  l_patch.set_description:=TRUE;
  l_patch.description_value:=' ';
  l_patch.set_price:=TRUE;
  l_patch.price_value:=0;
  prd_rule_pkg.normalize_and_validate_patch(
    'ACTIVE',NULL,NULL,NULL,NULL,l_patch
  );
  ok(l_patch.description_value IS NULL AND l_patch.price_value=0,
     'PASS 21 - Patch.');
  l_patch.set_description:=FALSE;
  l_patch.set_price:=FALSE;
  l_patch.set_width:=TRUE;
  l_patch.width_value:=15;
  prd_rule_pkg.normalize_and_validate_patch(
    'ACTIVE',0.5,10,20,30,l_patch
  );
  ok(l_patch.width_value=15,'PASS 22 - Patch combina dimensoes atuais.');
  l_patch.set_width:=FALSE;
  l_raised:=FALSE;
  BEGIN
    prd_rule_pkg.normalize_and_validate_patch(
      'DRAFT',NULL,NULL,NULL,NULL,l_patch
    );
  EXCEPTION WHEN prd_rule_pkg.e_empty_patch THEN l_raised:=TRUE; END;
  ok(l_raised,'PASS 23 - Patch vazio.');
  l_patch.set_title:=TRUE; l_patch.title_value:='Outro';
  l_raised:=FALSE;
  BEGIN
    prd_rule_pkg.normalize_and_validate_patch(
      'ARCHIVED',NULL,NULL,NULL,NULL,l_patch
    );
  EXCEPTION WHEN prd_rule_pkg.e_product_archived THEN l_raised:=TRUE; END;
  ok(l_raised,'PASS 24 - Arquivado nao editavel.');

  SELECT COUNT(*) INTO l_count FROM USER_SOURCE
   WHERE NAME='PRD_RULE_PKG'
     AND REGEXP_LIKE(
       UPPER(TEXT),
       '(^|[^A-Z_])(SELECT|INSERT|UPDATE|DELETE|MERGE|COMMIT|ROLLBACK)([^A-Z_]|$)|CORE_|JSON|HTTP'
     );
  ok(l_count=0,'PASS 25 - Dependencia proibida.');
  DBMS_OUTPUT.PUT_LINE('PRD_RULE_PKG: PASSED');
END;
/
