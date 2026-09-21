extends RefCounted
class_name SignalAssert

# Helpers para validar sinais com parâmetros — evita assert_true(true) placeholder.
# Uso: SignalAssert.assert_turn_emitted(repo, "me", "2026-...Z") ou checa count delta.

static func assert_signal_emitted_with_params(test: GutTest, obj: Object, signal_name: String, expected_params: Array) -> void:
	test.assert_signal_emitted_with_parameters(obj, signal_name, expected_params)

static func get_emit_count(test: GutTest, obj: Object, signal_name: String) -> int:
	return test.get_signal_emit_count(obj, signal_name)

static func assert_no_new_emit(test: GutTest, obj: Object, signal_name: String, before_count: int) -> void:
	test.assert_eq(test.get_signal_emit_count(obj, signal_name), before_count, "não deve reemitir " + signal_name)
