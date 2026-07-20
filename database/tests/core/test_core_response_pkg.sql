SET SERVEROUTPUT ON
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE

DECLARE
  g_test_count   PLS_INTEGER := 0;
  g_current_test VARCHAR2(200);

  c_trace_id CONSTANT core_trace_pkg.t_trace_id :=
    '0123456789ABCDEF0123456789ABCDEF';

  PROCEDURE assert_true(p_condition IN BOOLEAN, p_message IN VARCHAR2) IS
  BEGIN
    IF p_condition IS NULL OR NOT p_condition THEN
      RAISE_APPLICATION_ERROR(-20999, p_message);
    END IF;
  END assert_true;

  PROCEDURE assert_false(p_condition IN BOOLEAN, p_message IN VARCHAR2) IS
  BEGIN
    IF p_condition IS NULL OR p_condition THEN
      RAISE_APPLICATION_ERROR(-20999, p_message);
    END IF;
  END assert_false;

  PROCEDURE assert_equals(
    p_actual IN VARCHAR2, p_expected IN VARCHAR2, p_message IN VARCHAR2
  ) IS
  BEGIN
    IF p_actual IS NULL OR p_expected IS NULL OR p_actual <> p_expected THEN
      RAISE_APPLICATION_ERROR(-20999, p_message);
    END IF;
  END assert_equals;

  PROCEDURE assert_number_equals(
    p_actual IN NUMBER, p_expected IN NUMBER, p_message IN VARCHAR2
  ) IS
  BEGIN
    IF p_actual IS NULL OR p_expected IS NULL OR p_actual <> p_expected THEN
      RAISE_APPLICATION_ERROR(-20999, p_message);
    END IF;
  END assert_number_equals;

  PROCEDURE free_temporary_clob(io_clob IN OUT NOCOPY CLOB) IS
  BEGIN
    IF io_clob IS NOT NULL AND DBMS_LOB.ISTEMPORARY(io_clob) = 1 THEN
      DBMS_LOB.FREETEMPORARY(io_clob);
    END IF;
    io_clob := NULL;
  END free_temporary_clob;

  PROCEDURE clear_state IS
  BEGIN
    core_security_context_pkg.clear;
    core_context_pkg.clear;
    core_trace_pkg.clear;
  END clear_state;

  PROCEDURE initialize_context IS
  BEGIN
    core_trace_pkg.initialize(c_trace_id);
    core_context_pkg.initialize(
      core_context_pkg.c_origin_internal,
      core_context_pkg.c_mode_synchronous,
      NULL,
      FALSE
    );
  END initialize_context;

  PROCEDURE start_test(p_name IN VARCHAR2) IS
  BEGIN
    clear_state;
    g_current_test := p_name;
  END start_test;

  PROCEDURE pass IS
  BEGIN
    clear_state;
    g_test_count := g_test_count + 1;
    DBMS_OUTPUT.PUT_LINE(
      'PASS ' || LPAD(g_test_count, 2, '0') || ' - ' || g_current_test
    );
  END pass;

  FUNCTION success_object RETURN JSON_OBJECT_T IS
    l_payload JSON_OBJECT_T := JSON_OBJECT_T();
  BEGIN
    l_payload.put('name', 'Brecho');
    RETURN l_payload;
  END success_object;

  FUNCTION valid_error(
    p_retryable IN BOOLEAN := FALSE,
    p_trace_id  IN core_trace_pkg.t_trace_id := c_trace_id
  ) RETURN core_error_pkg.t_public_error IS
    l_error core_error_pkg.t_public_error;
  BEGIN
    l_error.code := 'BEX-CORE-001';
    l_error.category := core_error_pkg.c_category_technical;
    l_error.external_message := 'Falha segura.';
    l_error.retryable := p_retryable;
    l_error.trace_id := p_trace_id;
    RETURN l_error;
  END valid_error;

  FUNCTION parsed_success RETURN JSON_OBJECT_T IS
    l_body CLOB;
    l_result JSON_OBJECT_T;
  BEGIN
    l_body := core_response_pkg.build_success(success_object);
    l_result := JSON_OBJECT_T.parse(l_body);
    free_temporary_clob(l_body);
    RETURN l_result;
  EXCEPTION WHEN OTHERS THEN
    free_temporary_clob(l_body);
    RAISE;
  END parsed_success;

  FUNCTION parsed_empty RETURN JSON_OBJECT_T IS
    l_body CLOB;
    l_result JSON_OBJECT_T;
  BEGIN
    l_body := core_response_pkg.empty_success;
    l_result := JSON_OBJECT_T.parse(l_body);
    free_temporary_clob(l_body);
    RETURN l_result;
  EXCEPTION WHEN OTHERS THEN
    free_temporary_clob(l_body);
    RAISE;
  END parsed_empty;

  FUNCTION parsed_error(
    p_error IN core_error_pkg.t_public_error
  ) RETURN JSON_OBJECT_T IS
    l_body CLOB;
    l_result JSON_OBJECT_T;
  BEGIN
    l_body := core_response_pkg.build_error(p_error);
    l_result := JSON_OBJECT_T.parse(l_body);
    free_temporary_clob(l_body);
    RETURN l_result;
  EXCEPTION WHEN OTHERS THEN
    free_temporary_clob(l_body);
    RAISE;
  END parsed_error;

  PROCEDURE test_01_no_initial_context IS
  BEGIN
    start_test('sem contexto inicializado');
    assert_false(core_context_pkg.is_initialized, 'Contexto deve iniciar inativo.'); pass;
  END test_01_no_initial_context;

  PROCEDURE test_02_build_success_requires_context IS
    l_raised BOOLEAN := FALSE; l_body CLOB;
  BEGIN
    start_test('build_success exige contexto');
    BEGIN l_body := core_response_pkg.build_success(success_object);
    EXCEPTION WHEN core_response_pkg.e_execution_context_not_initialized THEN l_raised := TRUE; END;
    free_temporary_clob(l_body);
    assert_true(l_raised, 'build_success deveria exigir contexto.'); pass;
  END test_02_build_success_requires_context;

  PROCEDURE test_03_empty_success_requires_context IS
    l_raised BOOLEAN := FALSE; l_body CLOB;
  BEGIN
    start_test('empty_success exige contexto');
    BEGIN l_body := core_response_pkg.empty_success;
    EXCEPTION WHEN core_response_pkg.e_execution_context_not_initialized THEN l_raised := TRUE; END;
    free_temporary_clob(l_body);
    assert_true(l_raised, 'empty_success deveria exigir contexto.'); pass;
  END test_03_empty_success_requires_context;

  PROCEDURE test_04_build_error_requires_context IS
    l_raised BOOLEAN := FALSE; l_body CLOB; l_error core_error_pkg.t_public_error;
  BEGIN
    start_test('build_error exige contexto');
    l_error := valid_error;
    BEGIN l_body := core_response_pkg.build_error(l_error);
    EXCEPTION WHEN core_response_pkg.e_execution_context_not_initialized THEN l_raised := TRUE; END;
    free_temporary_clob(l_body);
    assert_true(l_raised, 'build_error deveria exigir contexto.'); pass;
  END test_04_build_error_requires_context;

  PROCEDURE test_05_success_object IS l_result JSON_OBJECT_T;
  BEGIN start_test('build_success aceita objeto'); initialize_context; l_result := parsed_success;
    assert_true(l_result.get('data').is_object, 'data deve ser objeto.'); pass; END test_05_success_object;

  PROCEDURE test_06_success_array IS l_payload JSON_ARRAY_T; l_body CLOB; l_result JSON_OBJECT_T;
  BEGIN start_test('build_success aceita array'); l_payload := JSON_ARRAY_T(); initialize_context; l_payload.append('item');
    l_body := core_response_pkg.build_success(l_payload); l_result := JSON_OBJECT_T.parse(l_body); free_temporary_clob(l_body);
    assert_true(l_result.get('data').is_array, 'data deve ser array.'); pass;
  EXCEPTION WHEN OTHERS THEN free_temporary_clob(l_body); RAISE; END test_06_success_array;

  PROCEDURE test_07_success_scalar IS l_source JSON_ARRAY_T; l_payload JSON_ELEMENT_T; l_body CLOB; l_result JSON_OBJECT_T;
  BEGIN start_test('build_success aceita escalar'); l_source := JSON_ARRAY_T(); l_source.append(42); l_payload := l_source.get(0); initialize_context;
    l_body := core_response_pkg.build_success(l_payload); l_result := JSON_OBJECT_T.parse(l_body); free_temporary_clob(l_body);
    assert_true(l_result.get('data').is_number, 'data deve ser numero.'); pass;
  EXCEPTION WHEN OTHERS THEN free_temporary_clob(l_body); RAISE; END test_07_success_scalar;

  PROCEDURE test_08_success_explicit_json_null IS l_source JSON_ARRAY_T; l_payload JSON_ELEMENT_T; l_body CLOB; l_result JSON_OBJECT_T;
  BEGIN start_test('build_success aceita JSON null explicito'); l_source := JSON_ARRAY_T(); l_source.append_null; l_payload := l_source.get(0); initialize_context;
    l_body := core_response_pkg.build_success(l_payload); l_result := JSON_OBJECT_T.parse(l_body); free_temporary_clob(l_body);
    assert_true(l_result.has('data'), 'data deve existir.'); assert_true(l_result.get('data').is_null, 'data deve ser JSON null.'); pass;
  EXCEPTION WHEN OTHERS THEN free_temporary_clob(l_body); RAISE; END test_08_success_explicit_json_null;

  PROCEDURE test_09_success_rejects_plsql_null IS l_payload JSON_ELEMENT_T; l_body CLOB; l_raised BOOLEAN := FALSE;
  BEGIN start_test('build_success rejeita NULL PL/SQL'); initialize_context;
    BEGIN l_body := core_response_pkg.build_success(l_payload); EXCEPTION WHEN core_response_pkg.e_response_data_required THEN l_raised := TRUE; END;
    free_temporary_clob(l_body); assert_true(l_raised, 'NULL PL/SQL deveria ser rejeitado.'); pass; END test_09_success_rejects_plsql_null;

  PROCEDURE test_10_success_true IS l_result JSON_OBJECT_T;
  BEGIN start_test('success igual a true'); initialize_context; l_result := parsed_success;
    assert_true(l_result.get_boolean('success'), 'success deve ser TRUE.'); pass; END test_10_success_true;

  PROCEDURE test_11_success_trace_present IS l_result JSON_OBJECT_T;
  BEGIN start_test('traceId presente'); initialize_context; l_result := parsed_success;
    assert_true(l_result.has('traceId'), 'traceId deve existir.'); pass; END test_11_success_trace_present;

  PROCEDURE test_12_success_data_present IS l_result JSON_OBJECT_T;
  BEGIN start_test('data presente'); initialize_context; l_result := parsed_success;
    assert_true(l_result.has('data'), 'data deve existir.'); pass; END test_12_success_data_present;

  PROCEDURE test_13_success_error_absent IS l_result JSON_OBJECT_T;
  BEGIN start_test('error ausente'); initialize_context; l_result := parsed_success;
    assert_false(l_result.has('error'), 'error deve estar ausente.'); pass; END test_13_success_error_absent;

  PROCEDURE test_14_success_trace_matches IS l_result JSON_OBJECT_T;
  BEGIN start_test('trace igual ao contexto'); initialize_context; l_result := parsed_success;
    assert_equals(l_result.get_string('traceId'), core_context_pkg.trace_id, 'Trace incorreto.'); pass; END test_14_success_trace_matches;

  PROCEDURE test_15_success_serializes IS l_body CLOB; l_result JSON_OBJECT_T;
  BEGIN start_test('envelope serializa corretamente'); initialize_context; l_body := core_response_pkg.build_success(success_object);
    l_result := JSON_OBJECT_T.parse(l_body); assert_true(l_result IS NOT NULL, 'Envelope deveria ser parseavel.'); free_temporary_clob(l_body); pass;
  EXCEPTION WHEN OTHERS THEN free_temporary_clob(l_body); RAISE; END test_15_success_serializes;

  PROCEDURE test_16_payload_preserved IS l_result JSON_OBJECT_T;
  BEGIN start_test('payload preservado'); initialize_context; l_result := parsed_success;
    assert_equals(l_result.get_object('data').get_string('name'), 'Brecho', 'Payload incorreto.'); pass; END test_16_payload_preserved;

  PROCEDURE test_17_payload_not_changed IS l_payload JSON_OBJECT_T; l_before VARCHAR2(32767); l_body CLOB;
  BEGIN start_test('payload nao e alterado'); l_payload := success_object; initialize_context; l_before := l_payload.to_string;
    l_body := core_response_pkg.build_success(l_payload); assert_equals(l_payload.to_string, l_before, 'Payload foi alterado.'); free_temporary_clob(l_body); pass;
  EXCEPTION WHEN OTHERS THEN free_temporary_clob(l_body); RAISE; END test_17_payload_not_changed;

  PROCEDURE test_18_payload_reusable IS l_payload JSON_OBJECT_T; l_first CLOB; l_second CLOB;
  BEGIN start_test('payload pode ser reutilizado'); l_payload := success_object; initialize_context;
    l_first := core_response_pkg.build_success(l_payload); l_second := core_response_pkg.build_success(l_payload);
    assert_true(JSON_OBJECT_T.parse(l_first).has('data'), 'Primeiro envelope invalido.'); assert_true(JSON_OBJECT_T.parse(l_second).has('data'), 'Segundo envelope invalido.');
    free_temporary_clob(l_first); free_temporary_clob(l_second); pass;
  EXCEPTION WHEN OTHERS THEN free_temporary_clob(l_first); free_temporary_clob(l_second); RAISE; END test_18_payload_reusable;

  PROCEDURE test_19_original_object_intact IS l_payload JSON_OBJECT_T; l_body CLOB;
  BEGIN start_test('objeto original permanece intacto'); l_payload := success_object; initialize_context; l_body := core_response_pkg.build_success(l_payload);
    assert_equals(l_payload.get_string('name'), 'Brecho', 'Objeto original mudou.'); assert_number_equals(l_payload.get_size, 1, 'Objeto original mudou.');
    free_temporary_clob(l_body); pass; EXCEPTION WHEN OTHERS THEN free_temporary_clob(l_body); RAISE; END test_19_original_object_intact;

  PROCEDURE test_20_original_array_intact IS l_payload JSON_ARRAY_T; l_body CLOB;
  BEGIN start_test('array original permanece intacto'); l_payload := JSON_ARRAY_T(); initialize_context; l_payload.append('item'); l_body := core_response_pkg.build_success(l_payload);
    assert_number_equals(l_payload.get_size, 1, 'Array original mudou.'); assert_equals(l_payload.get_string(0), 'item', 'Item original mudou.');
    free_temporary_clob(l_body); pass; EXCEPTION WHEN OTHERS THEN free_temporary_clob(l_body); RAISE; END test_20_original_array_intact;

  PROCEDURE test_21_empty_success_true IS l_result JSON_OBJECT_T;
  BEGIN start_test('empty_success success true'); initialize_context; l_result := parsed_empty; assert_true(l_result.get_boolean('success'), 'success deve ser TRUE.'); pass; END test_21_empty_success_true;
  PROCEDURE test_22_empty_trace_present IS l_result JSON_OBJECT_T;
  BEGIN start_test('empty_success trace presente'); initialize_context; l_result := parsed_empty; assert_true(l_result.has('traceId'), 'traceId deve existir.'); pass; END test_22_empty_trace_present;
  PROCEDURE test_23_empty_without_data IS l_result JSON_OBJECT_T;
  BEGIN start_test('empty_success sem data'); initialize_context; l_result := parsed_empty; assert_false(l_result.has('data'), 'data deve estar ausente.'); pass; END test_23_empty_without_data;
  PROCEDURE test_24_empty_without_error IS l_result JSON_OBJECT_T;
  BEGIN start_test('empty_success sem error'); initialize_context; l_result := parsed_empty; assert_false(l_result.has('error'), 'error deve estar ausente.'); pass; END test_24_empty_without_error;
  PROCEDURE test_25_empty_valid_envelope IS l_body CLOB; l_result JSON_OBJECT_T;
  BEGIN start_test('empty_success envelope valido'); initialize_context; l_body := core_response_pkg.empty_success; l_result := JSON_OBJECT_T.parse(l_body);
    assert_number_equals(l_result.get_size, 2, 'Envelope vazio deve ter dois atributos.'); free_temporary_clob(l_body); pass;
  EXCEPTION WHEN OTHERS THEN free_temporary_clob(l_body); RAISE; END test_25_empty_valid_envelope;

  PROCEDURE test_26_error_success_false IS l_result JSON_OBJECT_T;
  BEGIN start_test('build_error success false'); initialize_context; l_result := parsed_error(valid_error); assert_false(l_result.get_boolean('success'), 'success deve ser FALSE.'); pass; END test_26_error_success_false;
  PROCEDURE test_27_error_trace_present IS l_result JSON_OBJECT_T;
  BEGIN start_test('build_error trace presente'); initialize_context; l_result := parsed_error(valid_error); assert_true(l_result.has('traceId'), 'traceId deve existir.'); pass; END test_27_error_trace_present;
  PROCEDURE test_28_error_present IS l_result JSON_OBJECT_T;
  BEGIN start_test('build_error error presente'); initialize_context; l_result := parsed_error(valid_error); assert_true(l_result.get('error').is_object, 'error deve ser objeto.'); pass; END test_28_error_present;
  PROCEDURE test_29_error_data_absent IS l_result JSON_OBJECT_T;
  BEGIN start_test('build_error data ausente'); initialize_context; l_result := parsed_error(valid_error); assert_false(l_result.has('data'), 'data deve estar ausente.'); pass; END test_29_error_data_absent;
  PROCEDURE test_30_error_code_preserved IS l_result JSON_OBJECT_T;
  BEGIN start_test('code preservado'); initialize_context; l_result := parsed_error(valid_error); assert_equals(l_result.get_object('error').get_string('code'), 'BEX-CORE-001', 'code incorreto.'); pass; END test_30_error_code_preserved;
  PROCEDURE test_31_error_category_preserved IS l_result JSON_OBJECT_T;
  BEGIN start_test('category preservada'); initialize_context; l_result := parsed_error(valid_error); assert_equals(l_result.get_object('error').get_string('category'), core_error_pkg.c_category_technical, 'category incorreta.'); pass; END test_31_error_category_preserved;
  PROCEDURE test_32_error_message_preserved IS l_result JSON_OBJECT_T;
  BEGIN start_test('message preservada'); initialize_context; l_result := parsed_error(valid_error); assert_equals(l_result.get_object('error').get_string('message'), 'Falha segura.', 'message incorreta.'); pass; END test_32_error_message_preserved;
  PROCEDURE test_33_error_retryable_true IS l_result JSON_OBJECT_T;
  BEGIN start_test('retryable TRUE'); initialize_context; l_result := parsed_error(valid_error(TRUE)); assert_true(l_result.get_object('error').get_boolean('retryable'), 'retryable deve ser TRUE.'); pass; END test_33_error_retryable_true;
  PROCEDURE test_34_error_retryable_false IS l_result JSON_OBJECT_T;
  BEGIN start_test('retryable FALSE'); initialize_context; l_result := parsed_error(valid_error(FALSE)); assert_false(l_result.get_object('error').get_boolean('retryable'), 'retryable deve ser FALSE.'); pass; END test_34_error_retryable_false;
  PROCEDURE test_35_error_trace_matches IS l_result JSON_OBJECT_T;
  BEGIN start_test('trace coincide'); initialize_context; l_result := parsed_error(valid_error); assert_equals(l_result.get_string('traceId'), c_trace_id, 'Trace incorreto.'); pass; END test_35_error_trace_matches;

  PROCEDURE test_36_error_trace_mismatch IS l_error core_error_pkg.t_public_error; l_body CLOB; l_raised BOOLEAN := FALSE;
  BEGIN start_test('trace divergente gera e_error_trace_mismatch'); l_error := valid_error(FALSE, 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF'); initialize_context;
    BEGIN l_body := core_response_pkg.build_error(l_error); EXCEPTION WHEN core_response_pkg.e_error_trace_mismatch THEN l_raised := TRUE; END;
    free_temporary_clob(l_body); assert_true(l_raised, 'Trace divergente deveria falhar.'); pass; END test_36_error_trace_mismatch;

  PROCEDURE test_37_invalid_code IS l_error core_error_pkg.t_public_error; l_body CLOB; l_raised BOOLEAN := FALSE;
  BEGIN start_test('code invalido'); l_error := valid_error; initialize_context; l_error.code := 'INVALID'; BEGIN l_body := core_response_pkg.build_error(l_error); EXCEPTION WHEN core_response_pkg.e_invalid_public_error THEN l_raised := TRUE; END;
    free_temporary_clob(l_body); assert_true(l_raised, 'Code invalido deveria falhar.'); pass; END test_37_invalid_code;
  PROCEDURE test_38_invalid_category IS l_error core_error_pkg.t_public_error; l_body CLOB; l_raised BOOLEAN := FALSE;
  BEGIN start_test('category invalida'); l_error := valid_error; initialize_context; l_error.category := 'INVALID'; BEGIN l_body := core_response_pkg.build_error(l_error); EXCEPTION WHEN core_response_pkg.e_invalid_public_error THEN l_raised := TRUE; END;
    free_temporary_clob(l_body); assert_true(l_raised, 'Category invalida deveria falhar.'); pass; END test_38_invalid_category;
  PROCEDURE test_39_null_message IS l_error core_error_pkg.t_public_error; l_body CLOB; l_raised BOOLEAN := FALSE;
  BEGIN start_test('message NULL'); l_error := valid_error; initialize_context; l_error.external_message := NULL; BEGIN l_body := core_response_pkg.build_error(l_error); EXCEPTION WHEN core_response_pkg.e_invalid_public_error THEN l_raised := TRUE; END;
    free_temporary_clob(l_body); assert_true(l_raised, 'Message NULL deveria falhar.'); pass; END test_39_null_message;
  PROCEDURE test_40_empty_message IS l_error core_error_pkg.t_public_error; l_body CLOB; l_raised BOOLEAN := FALSE;
  BEGIN start_test('message vazia'); l_error := valid_error; initialize_context; l_error.external_message := '   '; BEGIN l_body := core_response_pkg.build_error(l_error); EXCEPTION WHEN core_response_pkg.e_invalid_public_error THEN l_raised := TRUE; END;
    free_temporary_clob(l_body); assert_true(l_raised, 'Message vazia deveria falhar.'); pass; END test_40_empty_message;
  PROCEDURE test_41_null_trace IS l_error core_error_pkg.t_public_error; l_body CLOB; l_raised BOOLEAN := FALSE;
  BEGIN start_test('trace NULL'); l_error := valid_error; initialize_context; l_error.trace_id := NULL; BEGIN l_body := core_response_pkg.build_error(l_error); EXCEPTION WHEN core_response_pkg.e_invalid_public_error THEN l_raised := TRUE; END;
    free_temporary_clob(l_body); assert_true(l_raised, 'Trace NULL deveria falhar.'); pass; END test_41_null_trace;
  PROCEDURE test_42_null_retryable IS l_error core_error_pkg.t_public_error; l_body CLOB; l_raised BOOLEAN := FALSE;
  BEGIN start_test('retryable NULL'); l_error := valid_error; initialize_context; l_error.retryable := NULL; BEGIN l_body := core_response_pkg.build_error(l_error); EXCEPTION WHEN core_response_pkg.e_invalid_public_error THEN l_raised := TRUE; END;
    free_temporary_clob(l_body); assert_true(l_raised, 'Retryable NULL deveria falhar.'); pass; END test_42_null_retryable;
  PROCEDURE test_43_incomplete_record IS l_error core_error_pkg.t_public_error; l_body CLOB; l_raised BOOLEAN := FALSE;
  BEGIN start_test('record incompleto'); initialize_context; l_error.code := 'BEX-CORE-001'; BEGIN l_body := core_response_pkg.build_error(l_error); EXCEPTION WHEN core_response_pkg.e_invalid_public_error THEN l_raised := TRUE; END;
    free_temporary_clob(l_body); assert_true(l_raised, 'Record incompleto deveria falhar.'); pass; END test_43_incomplete_record;
  PROCEDURE test_44_record_unchanged IS l_error core_error_pkg.t_public_error; l_result JSON_OBJECT_T;
  BEGIN start_test('record nao alterado'); l_error := valid_error(TRUE); initialize_context; l_result := parsed_error(l_error);
    assert_equals(l_error.code, 'BEX-CORE-001', 'Code mudou.'); assert_equals(l_error.category, core_error_pkg.c_category_technical, 'Category mudou.');
    assert_equals(l_error.external_message, 'Falha segura.', 'Message mudou.'); assert_true(l_error.retryable, 'Retryable mudou.'); assert_equals(l_error.trace_id, c_trace_id, 'Trace mudou.'); pass; END test_44_record_unchanged;

  PROCEDURE test_45_only_root_trace IS l_result JSON_OBJECT_T;
  BEGIN start_test('somente trace raiz'); initialize_context; l_result := parsed_error(valid_error);
    assert_true(l_result.has('traceId'), 'traceId raiz deve existir.'); assert_false(l_result.get_object('error').has('traceId'), 'error nao deve repetir traceId.'); pass; END test_45_only_root_trace;
  PROCEDURE test_46_no_meta IS l_result JSON_OBJECT_T;
  BEGIN start_test('nao existe meta'); initialize_context; l_result := parsed_error(valid_error); assert_false(l_result.has('meta'), 'meta nao deve existir.'); pass; END test_46_no_meta;
  PROCEDURE test_47_no_http_status IS l_result JSON_OBJECT_T;
  BEGIN start_test('nao existe httpStatus'); initialize_context; l_result := parsed_error(valid_error); assert_false(l_result.has('httpStatus'), 'httpStatus raiz nao deve existir.'); assert_false(l_result.get_object('error').has('httpStatus'), 'httpStatus no error nao deve existir.'); pass; END test_47_no_http_status;
  PROCEDURE test_48_no_severity IS l_result JSON_OBJECT_T;
  BEGIN start_test('nao existe severity'); initialize_context; l_result := parsed_error(valid_error); assert_false(l_result.get_object('error').has('severity'), 'severity nao deve existir.'); pass; END test_48_no_severity;
  PROCEDURE test_49_no_technical_detail IS l_result JSON_OBJECT_T;
  BEGIN start_test('nao existe technicalDetail'); initialize_context; l_result := parsed_error(valid_error); assert_false(l_result.get_object('error').has('technicalDetail'), 'technicalDetail nao deve existir.'); pass; END test_49_no_technical_detail;
  PROCEDURE test_50_no_should_log IS l_result JSON_OBJECT_T;
  BEGIN start_test('nao existe shouldLog'); initialize_context; l_result := parsed_error(valid_error); assert_false(l_result.get_object('error').has('shouldLog'), 'shouldLog nao deve existir.'); pass; END test_50_no_should_log;
  PROCEDURE test_51_no_suggested_status IS l_result JSON_OBJECT_T;
  BEGIN start_test('nao existe suggestedHttpStatus'); initialize_context; l_result := parsed_error(valid_error); assert_false(l_result.get_object('error').has('suggestedHttpStatus'), 'suggestedHttpStatus nao deve existir.'); pass; END test_51_no_suggested_status;

  PROCEDURE test_52_object_cloned IS l_payload JSON_OBJECT_T; l_body CLOB; l_result JSON_OBJECT_T;
  BEGIN start_test('objeto clonado'); l_payload := success_object; initialize_context; l_body := core_response_pkg.build_success(l_payload); l_payload.put('name', 'Alterado'); l_result := JSON_OBJECT_T.parse(l_body);
    assert_equals(l_result.get_object('data').get_string('name'), 'Brecho', 'Envelope compartilhou o objeto original.'); free_temporary_clob(l_body); pass;
  EXCEPTION WHEN OTHERS THEN free_temporary_clob(l_body); RAISE; END test_52_object_cloned;
  PROCEDURE test_53_array_cloned IS l_payload JSON_ARRAY_T; l_body CLOB; l_result JSON_OBJECT_T;
  BEGIN start_test('array clonado'); l_payload := JSON_ARRAY_T(); initialize_context; l_payload.append('original'); l_body := core_response_pkg.build_success(l_payload); l_payload.put(0, 'alterado'); l_result := JSON_OBJECT_T.parse(l_body);
    assert_equals(l_result.get_array('data').get_string(0), 'original', 'Envelope compartilhou o array original.'); free_temporary_clob(l_body); pass;
  EXCEPTION WHEN OTHERS THEN free_temporary_clob(l_body); RAISE; END test_53_array_cloned;
  PROCEDURE test_54_scalar_works IS l_source JSON_ARRAY_T; l_payload JSON_ELEMENT_T; l_body CLOB; l_result JSON_OBJECT_T;
  BEGIN start_test('escalar funciona'); l_source := JSON_ARRAY_T(); l_source.append('valor'); l_payload := l_source.get(0); initialize_context; l_body := core_response_pkg.build_success(l_payload); l_result := JSON_OBJECT_T.parse(l_body);
    assert_equals(l_result.get_string('data'), 'valor', 'Escalar incorreto.'); free_temporary_clob(l_body); pass;
  EXCEPTION WHEN OTHERS THEN free_temporary_clob(l_body); RAISE; END test_54_scalar_works;
  PROCEDURE test_55_final_clob_valid IS l_body CLOB; l_element JSON_ELEMENT_T;
  BEGIN start_test('serializacao final produz CLOB valido'); initialize_context; l_body := core_response_pkg.build_error(valid_error); l_element := JSON_ELEMENT_T.parse(l_body);
    assert_true(l_element.is_object, 'CLOB final deve conter objeto JSON.'); assert_true(DBMS_LOB.GETLENGTH(l_body) > 0, 'CLOB final deve ter conteudo.'); free_temporary_clob(l_body); pass;
  EXCEPTION WHEN OTHERS THEN free_temporary_clob(l_body); RAISE; END test_55_final_clob_valid;
BEGIN
  test_01_no_initial_context;
  test_02_build_success_requires_context;
  test_03_empty_success_requires_context;
  test_04_build_error_requires_context;
  test_05_success_object;
  test_06_success_array;
  test_07_success_scalar;
  test_08_success_explicit_json_null;
  test_09_success_rejects_plsql_null;
  test_10_success_true;
  test_11_success_trace_present;
  test_12_success_data_present;
  test_13_success_error_absent;
  test_14_success_trace_matches;
  test_15_success_serializes;
  test_16_payload_preserved;
  test_17_payload_not_changed;
  test_18_payload_reusable;
  test_19_original_object_intact;
  test_20_original_array_intact;
  test_21_empty_success_true;
  test_22_empty_trace_present;
  test_23_empty_without_data;
  test_24_empty_without_error;
  test_25_empty_valid_envelope;
  test_26_error_success_false;
  test_27_error_trace_present;
  test_28_error_present;
  test_29_error_data_absent;
  test_30_error_code_preserved;
  test_31_error_category_preserved;
  test_32_error_message_preserved;
  test_33_error_retryable_true;
  test_34_error_retryable_false;
  test_35_error_trace_matches;
  test_36_error_trace_mismatch;
  test_37_invalid_code;
  test_38_invalid_category;
  test_39_null_message;
  test_40_empty_message;
  test_41_null_trace;
  test_42_null_retryable;
  test_43_incomplete_record;
  test_44_record_unchanged;
  test_45_only_root_trace;
  test_46_no_meta;
  test_47_no_http_status;
  test_48_no_severity;
  test_49_no_technical_detail;
  test_50_no_should_log;
  test_51_no_suggested_status;
  test_52_object_cloned;
  test_53_array_cloned;
  test_54_scalar_works;
  test_55_final_clob_valid;

  clear_state;
  DBMS_OUTPUT.PUT_LINE('SUCCESS - CORE_RESPONSE_PKG (55 testes)');
EXCEPTION
  WHEN OTHERS THEN
    clear_state;
    DBMS_OUTPUT.PUT_LINE('FAIL - ' || g_current_test);
    RAISE;
END;
/
