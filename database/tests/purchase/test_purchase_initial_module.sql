SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  l_token VARCHAR2(12):=LOWER(SUBSTR(RAWTOHEX(SYS_GUID()),1,12));
  l_buyer NUMBER;l_owner NUMBER;l_profile NUMBER;l_store NUMBER;l_category NUMBER;l_product NUMBER;
  l_buyer_public CHAR(32):=LOWER(RAWTOHEX(SYS_GUID()));
  l_cart_public CHAR(32);l_cart_item_public CHAR(32);l_product_public CHAR(32);
  l_request_public CHAR(32);l_request_item_public CHAR(32);
  l_store_public CHAR(32):=LOWER(RAWTOHEX(SYS_GUID()));
  l_status PLS_INTEGER;l_body CLOB;l_count PLS_INTEGER;l_raised BOOLEAN;
  PROCEDURE fail(p VARCHAR2) IS BEGIN RAISE_APPLICATION_ERROR(-20999,p);END;
  PROCEDURE ok(p BOOLEAN,m VARCHAR2) IS BEGIN IF p IS NULL OR NOT p THEN fail(m);END IF;END;
  PROCEDURE pass(n NUMBER,m VARCHAR2) IS BEGIN DBMS_OUTPUT.PUT_LINE('PASS '||LPAD(n,2,'0')||' - '||m);END;
BEGIN
  SELECT COUNT(*) INTO l_count FROM USER_TABLES WHERE TABLE_NAME IN(
    'BEX_CART','BEX_CART_ITEM','BEX_PURCHASE_REQUEST','BEX_PURCHASE_REQUEST_ITEM');
  ok(l_count=4,'Estruturas da Compra Inicial ausentes.');pass(1,'Quatro tabelas existem');

  SELECT COUNT(*) INTO l_count FROM USER_OBJECTS
   WHERE OBJECT_NAME IN('CRT_RULE_PKG','CRT_REPOSITORY_PKG','CRT_SERVICE_PKG','CRT_API_PKG',
     'PUR_RULE_PKG','PUR_REPOSITORY_PKG','PUR_SERVICE_PKG','PUR_API_PKG')
     AND OBJECT_TYPE IN('PACKAGE','PACKAGE BODY') AND STATUS='VALID';
  ok(l_count=16,'Packages invalidas.');pass(2,'Oito packages possuem specification e body validos');
  SELECT COUNT(*) INTO l_count FROM USER_ERRORS WHERE NAME IN(
    'CRT_RULE_PKG','CRT_REPOSITORY_PKG','CRT_SERVICE_PKG','CRT_API_PKG',
    'PUR_RULE_PKG','PUR_REPOSITORY_PKG','PUR_SERVICE_PKG','PUR_API_PKG');
  ok(l_count=0,'Packages possuem USER_ERRORS.');pass(3,'Packages nao possuem USER_ERRORS');

  SELECT COUNT(*) INTO l_count FROM USER_CONSTRAINTS WHERE CONSTRAINT_NAME IN(
    'FK_CRT_PROFILE','FK_CTI_CART','FK_CTI_PRODUCT_STORE','FK_PUR_PROFILE',
    'FK_PRI_REQUEST','FK_PRI_PRODUCT_STORE') AND CONSTRAINT_TYPE='R';
  ok(l_count=6,'Relacionamentos fisicos incorretos.');pass(4,'Relacionamentos estruturais estao protegidos');
  SELECT COUNT(*) INTO l_count FROM USER_CONSTRAINTS WHERE CONSTRAINT_NAME IN(
    'CK_CRT_STATUS','CK_CTI_STATUS','CK_CTI_QUANTITY','CK_CTI_PRICE',
    'CK_PUR_STATUS','CK_PUR_TIMESTAMPS','CK_PRI_STATUS','CK_PRI_STATE',
    'CK_PRI_REQUESTED_QTY','CK_PRI_CONFIRMED_QTY','CK_PRI_PRICE') AND CONSTRAINT_TYPE='C';
  ok(l_count=11,'Checks de dominio incorretos.');pass(5,'Estados, quantidades e valores possuem checks');
  SELECT COUNT(*) INTO l_count FROM USER_INDEXES WHERE INDEX_NAME IN(
    'UK_CART_ACTIVE_PROFILE','UK_CART_ITEM_ACTIVE_PRODUCT');
  ok(l_count=2,'Unicidades condicionais ausentes.');pass(6,'Unicidades ativas estao protegidas');

  l_raised:=FALSE;BEGIN crt_rule_pkg.validate_quantity(0);
  EXCEPTION WHEN crt_rule_pkg.e_invalid_quantity THEN l_raised:=TRUE;END;
  ok(l_raised,'Quantidade zero aceita.');pass(7,'Rule do carrinho rejeita quantidade invalida');
  DECLARE s VARCHAR2(30);r VARCHAR2(500);BEGIN
    pur_rule_pkg.validate_response(3,2,NULL,s,r);
    ok(s='PARTIALLY_APPROVED','Resposta parcial incorreta.');
  END;pass(8,'Rule comercial classifica aprovacao parcial');

  INSERT INTO BEX_ACCOUNT(ACC_PUBLIC_ID,ACC_EMAIL,ACC_PASSWORD_HASH,ACC_PASSWORD_CHANGED_AT,ACC_STATUS)
  VALUES(l_buyer_public,'buyer.'||l_token||'@example.invalid','test',SYSTIMESTAMP,'ACTIVE')
  RETURNING ACC_ID INTO l_buyer;
  INSERT INTO BEX_PROFILE(ACC_ID,PFL_PUBLIC_ID,PFL_DISPLAY_NAME,PFL_CREATED_BY,PFL_UPDATED_BY)
  VALUES(l_buyer,LOWER(RAWTOHEX(SYS_GUID())),'Buyer '||l_token,l_buyer,l_buyer)
  RETURNING PFL_ID INTO l_profile;
  INSERT INTO BEX_ACCOUNT(ACC_PUBLIC_ID,ACC_EMAIL,ACC_PASSWORD_HASH,ACC_PASSWORD_CHANGED_AT,ACC_STATUS)
  VALUES(LOWER(RAWTOHEX(SYS_GUID())),'owner.'||l_token||'@example.invalid','test',SYSTIMESTAMP,'ACTIVE')
  RETURNING ACC_ID INTO l_owner;
  INSERT INTO BEX_STORE(STR_PUBLIC_ID,ACC_ID,STR_NAME,STR_SLUG,STR_STATUS)
  VALUES(l_store_public,l_owner,'Purchase Store','purchase-'||l_token,'ACTIVE')
  RETURNING STR_ID INTO l_store;
  INSERT INTO BEX_CATEGORY(CAT_PUBLIC_ID,CAT_NAME,CAT_SLUG,CAT_STATUS)
  VALUES(LOWER(RAWTOHEX(SYS_GUID())),'Purchase Category','purchase-cat-'||l_token,'ACTIVE')
  RETURNING CAT_ID INTO l_category;
  INSERT INTO BEX_PRODUCT(PRD_PUBLIC_ID,STR_ID,CAT_ID,PRD_TITLE,PRD_SLUG,PRD_PRICE,
    PRD_QUANTITY,PRD_CONDITION,PRD_STATUS,PRD_CREATED_BY,PRD_UPDATED_BY)
  VALUES(LOWER(RAWTOHEX(SYS_GUID())),l_store,l_category,'Purchase Product',
    'purchase-product-'||l_token,19.90,3,'GOOD','ACTIVE',l_owner,l_owner)
  RETURNING PRD_ID,PRD_PUBLIC_ID INTO l_product,l_product_public;
  COMMIT;
  core_security_context_pkg.clear;core_context_pkg.clear;core_trace_pkg.clear;
  core_trace_pkg.initialize;
  core_context_pkg.initialize(
    core_context_pkg.c_origin_external,
    core_context_pkg.c_mode_synchronous,
    l_buyer_public,
    TRUE
  );
  core_security_context_pkg.initialize(
    core_security_context_pkg.c_actor_type_user,
    core_security_context_pkg.c_authentication_method_session
  );

  crt_api_pkg.get_or_create_cart(l_buyer,l_status,l_body);
  ok(l_status=200 AND JSON_VALUE(l_body,'$.data.cartPublicId') IS NOT NULL
    AND JSON_VALUE(l_body,'$.data.cartId') IS NULL,'GET/CREATE cart incorreto.');
  SELECT CRT_PUBLIC_ID INTO l_cart_public FROM BEX_CART WHERE PFL_ID=l_profile AND CRT_STATUS='ACTIVE';
  pass(9,'API cria carrinho ACTIVE com payload publico');

  crt_api_pkg.add_item(l_cart_public,
    '{"productPublicId":"'||TRIM(l_product_public)||
    '","quantity":2}',l_buyer,l_status,l_body);
  ok(l_status=201 AND JSON_VALUE(l_body,'$.data.items[0].unitPrice') IS NOT NULL,'ADD item incorreto.');
  SELECT CTI_PUBLIC_ID INTO l_cart_item_public FROM BEX_CART_ITEM
   WHERE CRT_ID=(SELECT CRT_ID FROM BEX_CART WHERE CRT_PUBLIC_ID=l_cart_public) AND CTI_STATUS='ACTIVE';
  pass(10,'API adiciona item com snapshot de preco');

  crt_api_pkg.update_item(l_cart_public,l_cart_item_public,'{"quantity":3}',
    l_buyer,l_status,l_body);
  ok(l_status=200,'UPDATE item incorreto.');
  SELECT COUNT(*) INTO l_count FROM BEX_CART_ITEM WHERE CTI_PUBLIC_ID=l_cart_item_public
    AND CTI_QUANTITY=3 AND CTI_UNIT_PRICE=19.90;
  ok(l_count=1,'Quantidade/preco nao persistidos.');pass(11,'API atualiza quantidade valida');

  pur_api_pkg.checkout(l_cart_public,l_buyer,l_status,l_body);
  ok(l_status=201 AND JSON_VALUE(l_body,'$.data.requestPublicId') IS NOT NULL
    AND JSON_VALUE(l_body,'$.data.items[0].requestedQuantity') IS NOT NULL,'Checkout incorreto.');
  SELECT PUR_PUBLIC_ID INTO l_request_public FROM BEX_PURCHASE_REQUEST WHERE PFL_ID=l_profile;
  SELECT PRI_PUBLIC_ID INTO l_request_item_public FROM BEX_PURCHASE_REQUEST_ITEM
   WHERE PUR_ID=(SELECT PUR_ID FROM BEX_PURCHASE_REQUEST WHERE PUR_PUBLIC_ID=l_request_public);
  SELECT COUNT(*) INTO l_count FROM BEX_CART WHERE CRT_PUBLIC_ID=l_cart_public AND CRT_STATUS='CHECKED_OUT';
  ok(l_count=1,'Carrinho nao encerrado.');pass(12,'Checkout cria solicitacao e encerra carrinho');

  pur_api_pkg.get_request(l_request_public,l_buyer,l_status,l_body);
  ok(l_status=200 AND JSON_VALUE(l_body,'$.data.items[0].storePublicId') IS NOT NULL
    AND JSON_VALUE(l_body,'$.data.profileId') IS NULL,'GET request incorreto.');
  pass(13,'Comprador consulta solicitacao sem IDs internos');

  pur_api_pkg.respond_item(l_request_public,l_request_item_public,l_store_public,
    '{"confirmedQuantity":2}',l_owner,l_status,l_body);
  ok(l_status=200 AND JSON_VALUE(l_body,'$.data.responseAt') IS NOT NULL,'Resposta parcial incorreta.');
  SELECT COUNT(*) INTO l_count FROM BEX_PURCHASE_REQUEST_ITEM i
   JOIN BEX_PURCHASE_REQUEST r ON r.PUR_ID=i.PUR_ID
   WHERE r.PUR_PUBLIC_ID=l_request_public AND i.PRI_STATUS='PARTIALLY_APPROVED'
     AND r.PUR_STATUS='PARTIALLY_APPROVED' AND r.PUR_RESPONSE_AT IS NOT NULL;
  ok(l_count=1,'Estados agregados incorretos.');pass(14,'Loja responde item e agregado recalcula status');

  pur_api_pkg.respond_item(l_request_public,l_request_item_public,l_store_public,
    '{"confirmedQuantity":3}',l_owner,l_status,l_body);
  ok(l_status=422,'Resposta repetida deveria ser rejeitada.');pass(15,'Solicitacao encerrada rejeita nova resposta');

  SELECT COUNT(*) INTO l_count FROM USER_SOURCE WHERE NAME IN('CRT_RULE_PKG','PUR_RULE_PKG')
    AND REGEXP_LIKE(UPPER(TEXT),'(^|[^A-Z_])(SELECT|INSERT|UPDATE|DELETE|MERGE|COMMIT|ROLLBACK)([^A-Z_]|$)|JSON');
  ok(l_count=0,'Rule possui SQL ou apresentacao.');pass(16,'Rules permanecem puras');
  SELECT COUNT(*) INTO l_count FROM USER_SOURCE WHERE NAME IN('CRT_SERVICE_PKG','PUR_SERVICE_PKG')
    AND REGEXP_LIKE(UPPER(TEXT),'(^|[^A-Z_])(COMMIT|ROLLBACK)([^A-Z_]|$)|JSON_OBJECT|JSON_ARRAY|CORE_RESPONSE');
  ok(l_count=0,'Service possui transacao ou apresentacao.');pass(17,'Services preservam fronteira arquitetural');

  DELETE FROM BEX_PURCHASE_REQUEST_ITEM WHERE PUR_ID IN(
    SELECT PUR_ID FROM BEX_PURCHASE_REQUEST WHERE PFL_ID=l_profile);
  DELETE FROM BEX_PURCHASE_REQUEST WHERE PFL_ID=l_profile;
  DELETE FROM BEX_CART_ITEM WHERE CRT_ID IN(SELECT CRT_ID FROM BEX_CART WHERE PFL_ID=l_profile);
  DELETE FROM BEX_CART WHERE PFL_ID=l_profile;
  DELETE FROM BEX_PRODUCT WHERE PRD_ID=l_product;DELETE FROM BEX_CATEGORY WHERE CAT_ID=l_category;
  DELETE FROM BEX_STORE WHERE STR_ID=l_store;DELETE FROM BEX_PROFILE WHERE PFL_ID=l_profile;
  DELETE FROM BEX_ACCOUNT WHERE ACC_ID IN(l_buyer,l_owner);COMMIT;
  core_security_context_pkg.clear;core_context_pkg.clear;core_trace_pkg.clear;
  DBMS_OUTPUT.PUT_LINE('PURCHASE INITIAL MODULE: PASSED');
EXCEPTION WHEN OTHERS THEN
  ROLLBACK;
  core_security_context_pkg.clear;core_context_pkg.clear;core_trace_pkg.clear;
  BEGIN
    DELETE FROM BEX_PURCHASE_REQUEST_ITEM WHERE PUR_ID IN(
      SELECT PUR_ID FROM BEX_PURCHASE_REQUEST WHERE PFL_ID=l_profile);
    DELETE FROM BEX_PURCHASE_REQUEST WHERE PFL_ID=l_profile;
    DELETE FROM BEX_CART_ITEM WHERE CRT_ID IN(SELECT CRT_ID FROM BEX_CART WHERE PFL_ID=l_profile);
    DELETE FROM BEX_CART WHERE PFL_ID=l_profile;
    DELETE FROM BEX_PRODUCT WHERE PRD_ID=l_product;DELETE FROM BEX_CATEGORY WHERE CAT_ID=l_category;
    DELETE FROM BEX_STORE WHERE STR_ID=l_store;DELETE FROM BEX_PROFILE WHERE PFL_ID=l_profile;
    DELETE FROM BEX_ACCOUNT WHERE ACC_ID IN(l_buyer,l_owner);COMMIT;
  EXCEPTION WHEN OTHERS THEN ROLLBACK;END;
  RAISE;
END;
/
