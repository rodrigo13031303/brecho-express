SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  g_test_count   PLS_INTEGER := 0;
  g_current_test VARCHAR2(200);

  PROCEDURE assert_true(
    p_condition IN BOOLEAN,
    p_message   IN VARCHAR2
  ) IS
  BEGIN
    IF p_condition IS NULL OR NOT p_condition THEN
      RAISE_APPLICATION_ERROR(-20999, p_message);
    END IF;
  END assert_true;

  PROCEDURE assert_false(
    p_condition IN BOOLEAN,
    p_message   IN VARCHAR2
  ) IS
  BEGIN
    IF p_condition IS NULL OR p_condition THEN
      RAISE_APPLICATION_ERROR(-20999, p_message);
    END IF;
  END assert_false;

  PROCEDURE assert_equals(
    p_actual   IN VARCHAR2,
    p_expected IN VARCHAR2,
    p_message  IN VARCHAR2
  ) IS
  BEGIN
    IF p_actual IS NULL
       OR p_expected IS NULL
       OR p_actual <> p_expected THEN
      RAISE_APPLICATION_ERROR(-20999, p_message);
    END IF;
  END assert_equals;

  PROCEDURE assert_number_equals(
    p_actual   IN NUMBER,
    p_expected IN NUMBER,
    p_message  IN VARCHAR2
  ) IS
  BEGIN
    IF p_actual IS NULL
       OR p_expected IS NULL
       OR p_actual <> p_expected THEN
      RAISE_APPLICATION_ERROR(-20999, p_message);
    END IF;
  END assert_number_equals;

  PROCEDURE assert_raises(
    p_raised  IN BOOLEAN,
    p_message IN VARCHAR2
  ) IS
  BEGIN
    assert_true(p_raised, p_message);
  END assert_raises;

  PROCEDURE free_temporary_clob(
    io_clob IN OUT NOCOPY CLOB
  ) IS
  BEGIN
    IF io_clob IS NOT NULL
       AND DBMS_LOB.ISTEMPORARY(io_clob) = 1 THEN
      DBMS_LOB.FREETEMPORARY(io_clob);
    END IF;

    io_clob := NULL;
  END free_temporary_clob;

  PROCEDURE assert_clob_equals(
    p_actual   IN CLOB,
    p_expected IN VARCHAR2,
    p_message  IN VARCHAR2
  ) IS
  BEGIN
    IF p_actual IS NULL
       OR DBMS_LOB.GETLENGTH(p_actual) <> LENGTH(p_expected)
       OR DBMS_LOB.SUBSTR(p_actual, 32767, 1) <> p_expected THEN
      RAISE_APPLICATION_ERROR(-20999, p_message);
    END IF;
  END assert_clob_equals;

  PROCEDURE set_nls_format(
    p_parameter IN VARCHAR2,
    p_value     IN VARCHAR2
  ) IS
  BEGIN
    DBMS_SESSION.SET_NLS(
      p_parameter,
      '''' || REPLACE(p_value, '''', '''''') || ''''
    );
  END set_nls_format;

  PROCEDURE start_test(
    p_test_name IN VARCHAR2
  ) IS
  BEGIN
    g_current_test := p_test_name;
  END start_test;

  PROCEDURE pass IS
  BEGIN
    g_test_count := g_test_count + 1;
    DBMS_OUTPUT.PUT_LINE(
      'PASS ' || LPAD(g_test_count, 2, '0') || ' - ' || g_current_test
    );
  END pass;

  PROCEDURE test_01_put_string_simple_and_type IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
    l_element JSON_ELEMENT_T;
  BEGIN
    start_test('put_string adiciona string e preserva tipo');
    core_json_pkg.put_string(l_object, 'name', 'Brecho');
    l_element := l_object.get('name');
    assert_equals(l_object.get_string('name'), 'Brecho', 'String incorreta.');
    assert_true(l_element.is_string, 'Valor deve ser JSON string.');
    pass;
  END test_01_put_string_simple_and_type;

  PROCEDURE test_02_put_string_quotes IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
    l_value  VARCHAR2(100) := 'Ele disse "ola"';
  BEGIN
    start_test('put_string preserva aspas com escaping nativo');
    core_json_pkg.put_string(l_object, 'text', l_value);
    assert_equals(l_object.get_string('text'), l_value, 'Aspas nao foram preservadas.');
    assert_true(INSTR(l_object.to_string, '\"') > 0, 'Aspas devem ser escapadas no JSON.');
    pass;
  END test_02_put_string_quotes;

  PROCEDURE test_03_put_string_backslash IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
    l_value  VARCHAR2(100) := 'C:\temp\file';
  BEGIN
    start_test('put_string preserva barra invertida');
    core_json_pkg.put_string(l_object, 'path', l_value);
    assert_equals(l_object.get_string('path'), l_value, 'Barra invertida nao foi preservada.');
    assert_true(INSTR(l_object.to_string, '\\') > 0, 'Barra deve ser escapada no JSON.');
    pass;
  END test_03_put_string_backslash;

  PROCEDURE test_04_put_string_newline IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
    l_value  VARCHAR2(100) := 'linha1' || CHR(10) || 'linha2';
  BEGIN
    start_test('put_string preserva quebra de linha');
    core_json_pkg.put_string(l_object, 'text', l_value);
    assert_equals(l_object.get_string('text'), l_value, 'Quebra de linha nao foi preservada.');
    assert_true(INSTR(l_object.to_string, '\n') > 0, 'Quebra deve ser escapada no JSON.');
    pass;
  END test_04_put_string_newline;

  PROCEDURE test_05_put_string_unicode IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
    l_value  VARCHAR2(100) := UNISTR('Brech\00F3 \65E5\672C');
  BEGIN
    start_test('put_string preserva Unicode');
    core_json_pkg.put_string(l_object, 'text', l_value);
    assert_equals(l_object.get_string('text'), l_value, 'Unicode nao foi preservado.');
    pass;
  END test_05_put_string_unicode;

  PROCEDURE test_06_put_string_replaces IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
  BEGIN
    start_test('put_string substitui atributo existente');
    core_json_pkg.put_string(l_object, 'name', 'first');
    core_json_pkg.put_string(l_object, 'name', 'second');
    assert_equals(l_object.get_string('name'), 'second', 'Atributo nao foi substituido.');
    assert_number_equals(l_object.get_size, 1, 'Objeto deve manter um atributo.');
    pass;
  END test_06_put_string_replaces;

  PROCEDURE test_07_put_string_preserves_name IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
  BEGIN
    start_test('put_string preserva nome exatamente');
    core_json_pkg.put_string(l_object, 'CamelCase', 'value');
    assert_true(l_object.has('CamelCase'), 'Nome original deve existir.');
    assert_false(l_object.has('camelcase'), 'Nome nao deve ser normalizado.');
    pass;
  END test_07_put_string_preserves_name;

  PROCEDURE test_08_put_string_preserves_spaced_name IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
  BEGIN
    start_test('put_string preserva espacos nas extremidades do nome');
    core_json_pkg.put_string(l_object, ' name ', 'value');
    assert_true(l_object.has(' name '), 'Nome com espacos deve existir.');
    assert_false(l_object.has('name'), 'Nome nao deve sofrer TRIM.');
    pass;
  END test_08_put_string_preserves_spaced_name;

  PROCEDURE test_09_put_string_rejects_null_value IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('put_string rejeita valor NULL');
    BEGIN
      core_json_pkg.put_string(l_object, 'name', NULL);
    EXCEPTION
      WHEN core_json_pkg.e_invalid_json_element THEN l_raised := TRUE;
    END;
    assert_raises(l_raised, 'Valor NULL deve ser rejeitado.');
    assert_number_equals(l_object.get_size, 0, 'Objeto nao pode ser alterado.');
    pass;
  END test_09_put_string_rejects_null_value;

  PROCEDURE test_10_put_string_rejects_invalid_names IS
    l_object      JSON_OBJECT_T := JSON_OBJECT_T();
    l_null_raised BOOLEAN := FALSE;
    l_empty_raised BOOLEAN := FALSE;
    l_space_raised BOOLEAN := FALSE;
  BEGIN
    start_test('put_string rejeita nomes NULL vazios e com espacos');
    BEGIN core_json_pkg.put_string(l_object, NULL, 'x');
    EXCEPTION WHEN core_json_pkg.e_invalid_attribute_name THEN l_null_raised := TRUE; END;
    BEGIN core_json_pkg.put_string(l_object, '', 'x');
    EXCEPTION WHEN core_json_pkg.e_invalid_attribute_name THEN l_empty_raised := TRUE; END;
    BEGIN core_json_pkg.put_string(l_object, '   ', 'x');
    EXCEPTION WHEN core_json_pkg.e_invalid_attribute_name THEN l_space_raised := TRUE; END;
    assert_raises(l_null_raised, 'Nome NULL deve ser rejeitado.');
    assert_raises(l_empty_raised, 'Nome vazio deve ser rejeitado.');
    assert_raises(l_space_raised, 'Nome com espacos deve ser rejeitado.');
    assert_number_equals(l_object.get_size, 0, 'Falhas nao podem alterar o objeto.');
    pass;
  END test_10_put_string_rejects_invalid_names;

  PROCEDURE test_11_put_string_rejects_null_object IS
    l_object JSON_OBJECT_T;
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('put_string rejeita objeto NULL');
    BEGIN core_json_pkg.put_string(l_object, 'name', 'value');
    EXCEPTION WHEN core_json_pkg.e_json_object_required THEN l_raised := TRUE; END;
    assert_raises(l_raised, 'Objeto NULL deve ser rejeitado.');
    pass;
  END test_11_put_string_rejects_null_object;

  PROCEDURE test_12_put_string_failure_is_atomic IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('falha de put_string preserva objeto existente');
    l_object.put('keep', 'original');
    BEGIN core_json_pkg.put_string(l_object, 'new', NULL);
    EXCEPTION WHEN core_json_pkg.e_invalid_json_element THEN l_raised := TRUE; END;
    assert_raises(l_raised, 'Falha esperada nao ocorreu.');
    assert_equals(l_object.get_string('keep'), 'original', 'Valor existente mudou.');
    assert_false(l_object.has('new'), 'Atributo parcial nao pode existir.');
    pass;
  END test_12_put_string_failure_is_atomic;

  PROCEDURE test_13_put_number_integer_and_type IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
    l_element JSON_ELEMENT_T;
  BEGIN
    start_test('put_number adiciona inteiro e preserva tipo');
    core_json_pkg.put_number(l_object, 'value', 42);
    l_element := l_object.get('value');
    assert_number_equals(l_object.get_number('value'), 42, 'Inteiro incorreto.');
    assert_true(l_element.is_number, 'Valor deve ser JSON number.');
    pass;
  END test_13_put_number_integer_and_type;

  PROCEDURE test_14_put_number_decimal IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
  BEGIN
    start_test('put_number adiciona decimal');
    core_json_pkg.put_number(l_object, 'value', 12.75);
    assert_number_equals(l_object.get_number('value'), 12.75, 'Decimal incorreto.');
    pass;
  END test_14_put_number_decimal;

  PROCEDURE test_15_put_number_negative IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
  BEGIN
    start_test('put_number adiciona numero negativo');
    core_json_pkg.put_number(l_object, 'value', -7);
    assert_number_equals(l_object.get_number('value'), -7, 'Numero negativo incorreto.');
    pass;
  END test_15_put_number_negative;

  PROCEDURE test_16_put_number_zero IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
  BEGIN
    start_test('put_number adiciona zero');
    core_json_pkg.put_number(l_object, 'value', 0);
    assert_number_equals(l_object.get_number('value'), 0, 'Zero incorreto.');
    pass;
  END test_16_put_number_zero;

  PROCEDURE test_17_put_number_rejects_null IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('put_number rejeita NULL sem alterar objeto');
    BEGIN core_json_pkg.put_number(l_object, 'value', NULL);
    EXCEPTION WHEN core_json_pkg.e_invalid_json_element THEN l_raised := TRUE; END;
    assert_raises(l_raised, 'NUMBER NULL deve ser rejeitado.');
    assert_number_equals(l_object.get_size, 0, 'Objeto nao pode ser alterado.');
    pass;
  END test_17_put_number_rejects_null;

  PROCEDURE test_18_put_number_rejects_name IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('put_number rejeita nome invalido');
    BEGIN core_json_pkg.put_number(l_object, '   ', 1);
    EXCEPTION WHEN core_json_pkg.e_invalid_attribute_name THEN l_raised := TRUE; END;
    assert_raises(l_raised, 'Nome invalido deve ser rejeitado.');
    assert_number_equals(l_object.get_size, 0, 'Objeto nao pode ser alterado.');
    pass;
  END test_18_put_number_rejects_name;

  PROCEDURE test_19_put_number_rejects_object IS
    l_object JSON_OBJECT_T;
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('put_number rejeita objeto NULL');
    BEGIN core_json_pkg.put_number(l_object, 'value', 1);
    EXCEPTION WHEN core_json_pkg.e_json_object_required THEN l_raised := TRUE; END;
    assert_raises(l_raised, 'Objeto NULL deve ser rejeitado.');
    pass;
  END test_19_put_number_rejects_object;

  PROCEDURE test_20_put_boolean_true IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
    l_element JSON_ELEMENT_T;
  BEGIN
    start_test('put_boolean adiciona TRUE sem aspas');
    core_json_pkg.put_boolean(l_object, 'flag', TRUE);
    l_element := l_object.get('flag');
    assert_true(l_object.get_boolean('flag'), 'TRUE deve ser preservado.');
    assert_true(l_element.is_boolean, 'Valor deve ser JSON boolean.');
    assert_equals(l_object.to_string, '{"flag":true}', 'TRUE deve ser serializado sem aspas.');
    pass;
  END test_20_put_boolean_true;

  PROCEDURE test_21_put_boolean_false IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
  BEGIN
    start_test('put_boolean adiciona FALSE sem aspas');
    core_json_pkg.put_boolean(l_object, 'flag', FALSE);
    assert_false(l_object.get_boolean('flag'), 'FALSE deve ser preservado.');
    assert_equals(l_object.to_string, '{"flag":false}', 'FALSE deve ser serializado sem aspas.');
    pass;
  END test_21_put_boolean_false;

  PROCEDURE test_22_put_boolean_rejects_null IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('put_boolean rejeita NULL');
    BEGIN core_json_pkg.put_boolean(l_object, 'flag', NULL);
    EXCEPTION WHEN core_json_pkg.e_invalid_json_element THEN l_raised := TRUE; END;
    assert_raises(l_raised, 'BOOLEAN NULL deve ser rejeitado.');
    assert_number_equals(l_object.get_size, 0, 'Objeto nao pode ser alterado.');
    pass;
  END test_22_put_boolean_rejects_null;

  PROCEDURE test_23_put_boolean_rejects_name IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('put_boolean rejeita nome invalido');
    BEGIN core_json_pkg.put_boolean(l_object, ' ', TRUE);
    EXCEPTION WHEN core_json_pkg.e_invalid_attribute_name THEN l_raised := TRUE; END;
    assert_raises(l_raised, 'Nome invalido deve ser rejeitado.');
    pass;
  END test_23_put_boolean_rejects_name;

  PROCEDURE test_24_put_boolean_rejects_object IS
    l_object JSON_OBJECT_T;
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('put_boolean rejeita objeto NULL');
    BEGIN core_json_pkg.put_boolean(l_object, 'flag', TRUE);
    EXCEPTION WHEN core_json_pkg.e_json_object_required THEN l_raised := TRUE; END;
    assert_raises(l_raised, 'Objeto NULL deve ser rejeitado.');
    pass;
  END test_24_put_boolean_rejects_object;

  PROCEDURE test_25_put_null_adds_present_null IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
    l_element JSON_ELEMENT_T;
  BEGIN
    start_test('put_null adiciona atributo presente com JSON null');
    core_json_pkg.put_null(l_object, 'value');
    l_element := l_object.get('value');
    assert_true(l_object.has('value'), 'Atributo null deve permanecer presente.');
    assert_true(l_element.is_null, 'Valor deve ser JSON null.');
    assert_equals(l_object.to_string, '{"value":null}', 'JSON null incorreto.');
    pass;
  END test_25_put_null_adds_present_null;

  PROCEDURE test_26_put_null_differs_from_absent IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
  BEGIN
    start_test('JSON null e diferente de atributo ausente');
    core_json_pkg.put_null(l_object, 'present');
    assert_true(l_object.has('present'), 'Atributo null deve existir.');
    assert_false(l_object.has('absent'), 'Atributo nao inserido deve estar ausente.');
    pass;
  END test_26_put_null_differs_from_absent;

  PROCEDURE test_27_put_null_rejects_name IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('put_null rejeita nome invalido');
    BEGIN core_json_pkg.put_null(l_object, '   ');
    EXCEPTION WHEN core_json_pkg.e_invalid_attribute_name THEN l_raised := TRUE; END;
    assert_raises(l_raised, 'Nome invalido deve ser rejeitado.');
    assert_number_equals(l_object.get_size, 0, 'Objeto nao pode ser alterado.');
    pass;
  END test_27_put_null_rejects_name;

  PROCEDURE test_28_put_null_rejects_object IS
    l_object JSON_OBJECT_T;
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('put_null rejeita objeto NULL');
    BEGIN core_json_pkg.put_null(l_object, 'value');
    EXCEPTION WHEN core_json_pkg.e_json_object_required THEN l_raised := TRUE; END;
    assert_raises(l_raised, 'Objeto NULL deve ser rejeitado.');
    pass;
  END test_28_put_null_rejects_object;

  PROCEDURE test_29_put_element_object IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
    l_child  JSON_OBJECT_T := JSON_OBJECT_T();
    l_result JSON_OBJECT_T;
  BEGIN
    start_test('put_element adiciona objeto filho');
    l_child.put('name', 'child');
    core_json_pkg.put_element(l_object, 'child', l_child);
    l_result := l_object.get_object('child');
    assert_equals(l_result.get_string('name'), 'child', 'Objeto filho incorreto.');
    pass;
  END test_29_put_element_object;

  PROCEDURE test_30_put_element_array IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
    l_child  JSON_ARRAY_T := JSON_ARRAY_T();
    l_result JSON_ARRAY_T;
  BEGIN
    start_test('put_element adiciona array filho');
    l_child.append('item');
    core_json_pkg.put_element(l_object, 'items', l_child);
    l_result := l_object.get_array('items');
    assert_equals(l_result.get_string(0), 'item', 'Array filho incorreto.');
    pass;
  END test_30_put_element_array;

  PROCEDURE test_31_put_element_scalar IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
    l_source JSON_ARRAY_T := JSON_ARRAY_T();
    l_scalar JSON_ELEMENT_T;
  BEGIN
    start_test('put_element adiciona elemento escalar');
    l_source.append('scalar');
    l_scalar := l_source.get(0);
    core_json_pkg.put_element(l_object, 'value', l_scalar);
    assert_equals(l_object.get_string('value'), 'scalar', 'Escalar incorreto.');
    pass;
  END test_31_put_element_scalar;

  PROCEDURE test_32_put_element_rejects_null IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
    l_element JSON_ELEMENT_T;
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('put_element rejeita elemento NULL sem alterar objeto');
    BEGIN core_json_pkg.put_element(l_object, 'value', l_element);
    EXCEPTION WHEN core_json_pkg.e_invalid_json_element THEN l_raised := TRUE; END;
    assert_raises(l_raised, 'Elemento NULL deve ser rejeitado.');
    assert_number_equals(l_object.get_size, 0, 'Objeto nao pode ser alterado.');
    pass;
  END test_32_put_element_rejects_null;

  PROCEDURE test_33_put_element_rejects_name IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
    l_child  JSON_OBJECT_T := JSON_OBJECT_T();
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('put_element rejeita nome invalido');
    BEGIN core_json_pkg.put_element(l_object, ' ', l_child);
    EXCEPTION WHEN core_json_pkg.e_invalid_attribute_name THEN l_raised := TRUE; END;
    assert_raises(l_raised, 'Nome invalido deve ser rejeitado.');
    assert_number_equals(l_object.get_size, 0, 'Objeto nao pode ser alterado.');
    pass;
  END test_33_put_element_rejects_name;

  PROCEDURE test_34_put_element_rejects_object IS
    l_object JSON_OBJECT_T;
    l_child  JSON_OBJECT_T := JSON_OBJECT_T();
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('put_element rejeita objeto NULL');
    BEGIN core_json_pkg.put_element(l_object, 'child', l_child);
    EXCEPTION WHEN core_json_pkg.e_json_object_required THEN l_raised := TRUE; END;
    assert_raises(l_raised, 'Objeto NULL deve ser rejeitado.');
    pass;
  END test_34_put_element_rejects_object;

  PROCEDURE test_35_append_string IS
    l_array JSON_ARRAY_T := JSON_ARRAY_T();
    l_element JSON_ELEMENT_T;
  BEGIN
    start_test('append_string adiciona string');
    core_json_pkg.append_string(l_array, 'item');
    l_element := l_array.get(0);
    assert_equals(l_array.get_string(0), 'item', 'String incorreta.');
    assert_true(l_element.is_string, 'Elemento deve ser JSON string.');
    pass;
  END test_35_append_string;

  PROCEDURE test_36_append_string_escaping IS
    l_array JSON_ARRAY_T := JSON_ARRAY_T();
    l_value VARCHAR2(100) := 'valor "com" \ barra';
  BEGIN
    start_test('append_string preserva escaping');
    core_json_pkg.append_string(l_array, l_value);
    assert_equals(l_array.get_string(0), l_value, 'String escapada incorreta.');
    assert_true(INSTR(l_array.to_string, '\"') > 0, 'Aspas devem ser escapadas.');
    pass;
  END test_36_append_string_escaping;

  PROCEDURE test_37_append_number IS
    l_array JSON_ARRAY_T := JSON_ARRAY_T();
    l_element JSON_ELEMENT_T;
  BEGIN
    start_test('append_number adiciona inteiro');
    core_json_pkg.append_number(l_array, 42);
    l_element := l_array.get(0);
    assert_number_equals(l_array.get_number(0), 42, 'Numero incorreto.');
    assert_true(l_element.is_number, 'Elemento deve ser JSON number.');
    pass;
  END test_37_append_number;

  PROCEDURE test_38_append_decimal IS
    l_array JSON_ARRAY_T := JSON_ARRAY_T();
  BEGIN
    start_test('append_number adiciona decimal');
    core_json_pkg.append_number(l_array, 12.75);
    assert_number_equals(l_array.get_number(0), 12.75, 'Decimal incorreto.');
    pass;
  END test_38_append_decimal;

  PROCEDURE test_39_append_preserves_order IS
    l_array JSON_ARRAY_T := JSON_ARRAY_T();
  BEGIN
    start_test('append preserva ordem de insercao');
    core_json_pkg.append_string(l_array, 'first');
    core_json_pkg.append_number(l_array, 2);
    core_json_pkg.append_string(l_array, 'third');
    assert_equals(l_array.get_string(0), 'first', 'Primeiro elemento incorreto.');
    assert_number_equals(l_array.get_number(1), 2, 'Segundo elemento incorreto.');
    assert_equals(l_array.get_string(2), 'third', 'Terceiro elemento incorreto.');
    pass;
  END test_39_append_preserves_order;

  PROCEDURE test_40_append_string_rejects_null IS
    l_array JSON_ARRAY_T := JSON_ARRAY_T();
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('append_string rejeita NULL sem alterar array');
    BEGIN core_json_pkg.append_string(l_array, NULL);
    EXCEPTION WHEN core_json_pkg.e_invalid_json_element THEN l_raised := TRUE; END;
    assert_raises(l_raised, 'String NULL deve ser rejeitada.');
    assert_number_equals(l_array.get_size, 0, 'Array nao pode ser alterado.');
    pass;
  END test_40_append_string_rejects_null;

  PROCEDURE test_41_append_number_rejects_null IS
    l_array JSON_ARRAY_T := JSON_ARRAY_T();
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('append_number rejeita NULL sem alterar array');
    BEGIN core_json_pkg.append_number(l_array, NULL);
    EXCEPTION WHEN core_json_pkg.e_invalid_json_element THEN l_raised := TRUE; END;
    assert_raises(l_raised, 'NUMBER NULL deve ser rejeitado.');
    assert_number_equals(l_array.get_size, 0, 'Array nao pode ser alterado.');
    pass;
  END test_41_append_number_rejects_null;

  PROCEDURE test_42_append_rejects_null_array IS
    l_array JSON_ARRAY_T;
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('append rejeita array NULL');
    BEGIN core_json_pkg.append_string(l_array, 'item');
    EXCEPTION WHEN core_json_pkg.e_json_array_required THEN l_raised := TRUE; END;
    assert_raises(l_raised, 'Array NULL deve ser rejeitado.');
    pass;
  END test_42_append_rejects_null_array;

  PROCEDURE test_43_append_booleans IS
    l_array JSON_ARRAY_T := JSON_ARRAY_T();
  BEGIN
    start_test('append_boolean adiciona TRUE e FALSE');
    core_json_pkg.append_boolean(l_array, TRUE);
    core_json_pkg.append_boolean(l_array, FALSE);
    assert_true(l_array.get_boolean(0), 'TRUE incorreto.');
    assert_false(l_array.get_boolean(1), 'FALSE incorreto.');
    assert_equals(l_array.to_string, '[true,false]', 'Booleans devem permanecer nativos.');
    pass;
  END test_43_append_booleans;

  PROCEDURE test_44_append_null IS
    l_array JSON_ARRAY_T := JSON_ARRAY_T();
    l_element JSON_ELEMENT_T;
  BEGIN
    start_test('append_null adiciona JSON null');
    core_json_pkg.append_null(l_array);
    l_element := l_array.get(0);
    assert_number_equals(l_array.get_size, 1, 'Array deve conter um elemento.');
    assert_true(l_element.is_null, 'Elemento deve ser JSON null.');
    pass;
  END test_44_append_null;

  PROCEDURE test_45_append_object_and_array IS
    l_array        JSON_ARRAY_T := JSON_ARRAY_T();
    l_object       JSON_OBJECT_T := JSON_OBJECT_T();
    l_child_array  JSON_ARRAY_T := JSON_ARRAY_T();
    l_result_object JSON_OBJECT_T;
    l_result_array  JSON_ARRAY_T;
  BEGIN
    start_test('append_element adiciona objeto e array');
    l_object.put('name', 'child');
    l_child_array.append('item');
    core_json_pkg.append_element(l_array, l_object);
    core_json_pkg.append_element(l_array, l_child_array);
    l_result_object := TREAT(l_array.get(0) AS JSON_OBJECT_T);
    l_result_array := TREAT(l_array.get(1) AS JSON_ARRAY_T);
    assert_equals(l_result_object.get_string('name'), 'child', 'Objeto incorreto.');
    assert_equals(l_result_array.get_string(0), 'item', 'Array incorreto.');
    pass;
  END test_45_append_object_and_array;

  PROCEDURE test_46_append_scalar IS
    l_array  JSON_ARRAY_T := JSON_ARRAY_T();
    l_source JSON_ARRAY_T := JSON_ARRAY_T();
    l_scalar JSON_ELEMENT_T;
  BEGIN
    start_test('append_element adiciona escalar');
    l_source.append(42);
    l_scalar := l_source.get(0);
    core_json_pkg.append_element(l_array, l_scalar);
    assert_number_equals(l_array.get_number(0), 42, 'Escalar incorreto.');
    pass;
  END test_46_append_scalar;

  PROCEDURE test_47_append_boolean_rejects_null IS
    l_array JSON_ARRAY_T := JSON_ARRAY_T();
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('append_boolean rejeita NULL');
    BEGIN core_json_pkg.append_boolean(l_array, NULL);
    EXCEPTION WHEN core_json_pkg.e_invalid_json_element THEN l_raised := TRUE; END;
    assert_raises(l_raised, 'BOOLEAN NULL deve ser rejeitado.');
    assert_number_equals(l_array.get_size, 0, 'Array nao pode ser alterado.');
    pass;
  END test_47_append_boolean_rejects_null;

  PROCEDURE test_48_append_element_rejects_null IS
    l_array JSON_ARRAY_T := JSON_ARRAY_T();
    l_element JSON_ELEMENT_T;
    l_raised BOOLEAN := FALSE;
  BEGIN
    start_test('append_element rejeita NULL');
    BEGIN core_json_pkg.append_element(l_array, l_element);
    EXCEPTION WHEN core_json_pkg.e_invalid_json_element THEN l_raised := TRUE; END;
    assert_raises(l_raised, 'Elemento NULL deve ser rejeitado.');
    assert_number_equals(l_array.get_size, 0, 'Array nao pode ser alterado.');
    pass;
  END test_48_append_element_rejects_null;

  PROCEDURE test_49_serialize_object IS
    l_object JSON_OBJECT_T := JSON_OBJECT_T();
    l_clob   CLOB;
  BEGIN
    start_test('serialize converte objeto para CLOB');
    l_object.put('name', 'value');
    l_clob := core_json_pkg.serialize(l_object);
    assert_true(l_clob IS NOT NULL, 'CLOB nao pode ser NULL.');
    assert_clob_equals(l_clob, '{"name":"value"}', 'Objeto serializado incorreto.');
    free_temporary_clob(l_clob);
    pass;
  EXCEPTION
    WHEN OTHERS THEN free_temporary_clob(l_clob); RAISE;
  END test_49_serialize_object;

  PROCEDURE test_50_serialize_array IS
    l_array JSON_ARRAY_T := JSON_ARRAY_T();
    l_clob  CLOB;
  BEGIN
    start_test('serialize converte array para CLOB');
    l_array.append('item');
    l_clob := core_json_pkg.serialize(l_array);
    assert_true(l_clob IS NOT NULL, 'CLOB nao pode ser NULL.');
    assert_clob_equals(l_clob, '["item"]', 'Array serializado incorreto.');
    free_temporary_clob(l_clob);
    pass;
  EXCEPTION
    WHEN OTHERS THEN free_temporary_clob(l_clob); RAISE;
  END test_50_serialize_array;

  PROCEDURE test_51_serialize_scalar IS
    l_source JSON_ARRAY_T := JSON_ARRAY_T();
    l_scalar JSON_ELEMENT_T;
    l_clob   CLOB;
  BEGIN
    start_test('serialize converte escalar para CLOB');
    l_source.append(TRUE);
    l_scalar := l_source.get(0);
    l_clob := core_json_pkg.serialize(l_scalar);
    assert_true(l_clob IS NOT NULL, 'CLOB nao pode ser NULL.');
    assert_clob_equals(l_clob, 'true', 'Escalar serializado incorreto.');
    free_temporary_clob(l_clob);
    pass;
  EXCEPTION
    WHEN OTHERS THEN free_temporary_clob(l_clob); RAISE;
  END test_51_serialize_scalar;

  PROCEDURE test_52_serialize_rejects_null IS
    l_element JSON_ELEMENT_T;
    l_clob    CLOB;
    l_raised  BOOLEAN := FALSE;
  BEGIN
    start_test('serialize rejeita elemento NULL');
    BEGIN l_clob := core_json_pkg.serialize(l_element);
    EXCEPTION WHEN core_json_pkg.e_invalid_json_element THEN l_raised := TRUE; END;
    assert_raises(l_raised, 'Elemento NULL deve ser rejeitado nominalmente.');
    free_temporary_clob(l_clob);
    pass;
  EXCEPTION
    WHEN OTHERS THEN free_temporary_clob(l_clob); RAISE;
  END test_52_serialize_rejects_null;

  PROCEDURE test_53_format_timestamp_six_digits IS
    l_value TIMESTAMP := TIMESTAMP '2026-07-19 14:35:27.123456';
  BEGIN
    start_test('format_timestamp retorna seis casas decimais');
    assert_equals(
      core_json_pkg.format_timestamp(l_value),
      '2026-07-19T14:35:27.123456',
      'Timestamp ISO-8601 incorreto.'
    );
    pass;
  END test_53_format_timestamp_six_digits;

  PROCEDURE test_54_format_timestamp_rejects_null IS
    l_raised BOOLEAN := FALSE;
    l_result core_json_pkg.t_iso8601_value;
  BEGIN
    start_test('format_timestamp rejeita NULL');
    BEGIN l_result := core_json_pkg.format_timestamp(NULL);
    EXCEPTION WHEN core_json_pkg.e_invalid_temporal_value THEN l_raised := TRUE; END;
    assert_raises(l_raised, 'TIMESTAMP NULL deve ser rejeitado.');
    pass;
  END test_54_format_timestamp_rejects_null;

  PROCEDURE test_55_format_timestamp_ignores_nls IS
    l_original VARCHAR2(100);
    l_result   core_json_pkg.t_iso8601_value;
  BEGIN
    start_test('format_timestamp independe de NLS_TIMESTAMP_FORMAT');
    SELECT value INTO l_original
      FROM nls_session_parameters
     WHERE parameter = 'NLS_TIMESTAMP_FORMAT';
    set_nls_format('NLS_TIMESTAMP_FORMAT', 'DD-MON-RR HH.MI.SSXFF AM');
    l_result := core_json_pkg.format_timestamp(
      TIMESTAMP '2026-07-19 14:35:27.123456'
    );
    set_nls_format('NLS_TIMESTAMP_FORMAT', l_original);
    assert_equals(l_result, '2026-07-19T14:35:27.123456', 'Resultado dependeu de NLS.');
    pass;
  EXCEPTION
    WHEN OTHERS THEN
      IF l_original IS NOT NULL THEN
        set_nls_format('NLS_TIMESTAMP_FORMAT', l_original);
      END IF;
      RAISE;
  END test_55_format_timestamp_ignores_nls;

  PROCEDURE test_56_format_timestamp_tz_negative IS
    l_value TIMESTAMP WITH TIME ZONE;
  BEGIN
    start_test('format_timestamp_tz preserva offset negativo');
    l_value := TO_TIMESTAMP_TZ(
      '2026-07-19 14:35:27.123456 -03:00',
      'YYYY-MM-DD HH24:MI:SS.FF6 TZH:TZM'
    );
    assert_equals(
      core_json_pkg.format_timestamp_tz(l_value),
      '2026-07-19T14:35:27.123456-03:00',
      'Offset negativo incorreto.'
    );
    pass;
  END test_56_format_timestamp_tz_negative;

  PROCEDURE test_57_format_timestamp_tz_positive IS
    l_value TIMESTAMP WITH TIME ZONE;
  BEGIN
    start_test('format_timestamp_tz preserva offset positivo');
    l_value := TO_TIMESTAMP_TZ(
      '2026-07-19 14:35:27.123456 +05:30',
      'YYYY-MM-DD HH24:MI:SS.FF6 TZH:TZM'
    );
    assert_equals(
      core_json_pkg.format_timestamp_tz(l_value),
      '2026-07-19T14:35:27.123456+05:30',
      'Offset positivo incorreto.'
    );
    pass;
  END test_57_format_timestamp_tz_positive;

  PROCEDURE test_58_format_timestamp_tz_zero IS
    l_value  TIMESTAMP WITH TIME ZONE;
    l_result core_json_pkg.t_iso8601_value;
  BEGIN
    start_test('format_timestamp_tz preserva +00:00 sem Z');
    l_value := TO_TIMESTAMP_TZ(
      '2026-07-19 14:35:27.123456 +00:00',
      'YYYY-MM-DD HH24:MI:SS.FF6 TZH:TZM'
    );
    l_result := core_json_pkg.format_timestamp_tz(l_value);
    assert_equals(l_result, '2026-07-19T14:35:27.123456+00:00', 'Offset zero incorreto.');
    assert_false(SUBSTR(l_result, -1) = 'Z', 'Offset zero nao pode virar Z.');
    pass;
  END test_58_format_timestamp_tz_zero;

  PROCEDURE test_59_format_timestamp_tz_rejects_null IS
    l_raised BOOLEAN := FALSE;
    l_result core_json_pkg.t_iso8601_value;
  BEGIN
    start_test('format_timestamp_tz rejeita NULL');
    BEGIN l_result := core_json_pkg.format_timestamp_tz(NULL);
    EXCEPTION WHEN core_json_pkg.e_invalid_temporal_value THEN l_raised := TRUE; END;
    assert_raises(l_raised, 'TIMESTAMP WITH TIME ZONE NULL deve ser rejeitado.');
    pass;
  END test_59_format_timestamp_tz_rejects_null;

  PROCEDURE test_60_format_timestamp_tz_ignores_nls IS
    l_original VARCHAR2(100);
    l_value    TIMESTAMP WITH TIME ZONE;
    l_result   core_json_pkg.t_iso8601_value;
  BEGIN
    start_test('format_timestamp_tz independe de NLS_TIMESTAMP_TZ_FORMAT');
    SELECT value INTO l_original
      FROM nls_session_parameters
     WHERE parameter = 'NLS_TIMESTAMP_TZ_FORMAT';
    set_nls_format('NLS_TIMESTAMP_TZ_FORMAT', 'DD-MON-RR HH.MI.SSXFF AM TZR');
    l_value := TO_TIMESTAMP_TZ(
      '2026-07-19 14:35:27.123456 -03:00',
      'YYYY-MM-DD HH24:MI:SS.FF6 TZH:TZM'
    );
    l_result := core_json_pkg.format_timestamp_tz(l_value);
    set_nls_format('NLS_TIMESTAMP_TZ_FORMAT', l_original);
    assert_equals(l_result, '2026-07-19T14:35:27.123456-03:00', 'Resultado dependeu de NLS.');
    pass;
  EXCEPTION
    WHEN OTHERS THEN
      IF l_original IS NOT NULL THEN
        set_nls_format('NLS_TIMESTAMP_TZ_FORMAT', l_original);
      END IF;
      RAISE;
  END test_60_format_timestamp_tz_ignores_nls;
BEGIN
  test_01_put_string_simple_and_type;
  test_02_put_string_quotes;
  test_03_put_string_backslash;
  test_04_put_string_newline;
  test_05_put_string_unicode;
  test_06_put_string_replaces;
  test_07_put_string_preserves_name;
  test_08_put_string_preserves_spaced_name;
  test_09_put_string_rejects_null_value;
  test_10_put_string_rejects_invalid_names;
  test_11_put_string_rejects_null_object;
  test_12_put_string_failure_is_atomic;
  test_13_put_number_integer_and_type;
  test_14_put_number_decimal;
  test_15_put_number_negative;
  test_16_put_number_zero;
  test_17_put_number_rejects_null;
  test_18_put_number_rejects_name;
  test_19_put_number_rejects_object;
  test_20_put_boolean_true;
  test_21_put_boolean_false;
  test_22_put_boolean_rejects_null;
  test_23_put_boolean_rejects_name;
  test_24_put_boolean_rejects_object;
  test_25_put_null_adds_present_null;
  test_26_put_null_differs_from_absent;
  test_27_put_null_rejects_name;
  test_28_put_null_rejects_object;
  test_29_put_element_object;
  test_30_put_element_array;
  test_31_put_element_scalar;
  test_32_put_element_rejects_null;
  test_33_put_element_rejects_name;
  test_34_put_element_rejects_object;
  test_35_append_string;
  test_36_append_string_escaping;
  test_37_append_number;
  test_38_append_decimal;
  test_39_append_preserves_order;
  test_40_append_string_rejects_null;
  test_41_append_number_rejects_null;
  test_42_append_rejects_null_array;
  test_43_append_booleans;
  test_44_append_null;
  test_45_append_object_and_array;
  test_46_append_scalar;
  test_47_append_boolean_rejects_null;
  test_48_append_element_rejects_null;
  test_49_serialize_object;
  test_50_serialize_array;
  test_51_serialize_scalar;
  test_52_serialize_rejects_null;
  test_53_format_timestamp_six_digits;
  test_54_format_timestamp_rejects_null;
  test_55_format_timestamp_ignores_nls;
  test_56_format_timestamp_tz_negative;
  test_57_format_timestamp_tz_positive;
  test_58_format_timestamp_tz_zero;
  test_59_format_timestamp_tz_rejects_null;
  test_60_format_timestamp_tz_ignores_nls;

  DBMS_OUTPUT.PUT_LINE('SUCCESS - CORE_JSON_PKG (60 testes)');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('FAIL - ' || g_current_test);
    RAISE;
END;
/
