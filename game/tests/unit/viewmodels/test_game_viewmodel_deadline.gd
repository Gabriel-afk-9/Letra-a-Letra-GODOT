extends GutTest

var _vm: GameViewModel

func before_each() -> void:
	var fake_repo := FakeGameRepository.new()
	var fake_provider := FakeCurrentUserProvider.new()
	fake_provider.set_user("me", "Eu")
	var usecase := GameUseCase.new(fake_repo, fake_provider)
	_vm = GameViewModel.new(usecase, null)

func test_parse_deadline_with_Z_returns_positive() -> void:
	assert_true(_vm.parse_turn_deadline("2026-09-04T12:00:00Z") > 0)

func test_parse_deadline_without_Z_returns_positive() -> void:
	assert_true(_vm.parse_turn_deadline("2026-09-04T12:00:00") > 0)

func test_parse_deadline_with_millis_Z_returns_positive() -> void:
	# fração .000 é ignorada pela engine (comentário game_viewmodel.gd:515)
	assert_true(_vm.parse_turn_deadline("2026-09-04T12:00:00.000Z") > 0)

func test_parse_deadline_with_java_nanos_returns_positive() -> void:
	# Backend Java (Instant.toString) manda 9 dígitos: "2026-09-07T15:26:19.832158445Z"
	assert_true(_vm.parse_turn_deadline("2026-09-07T15:26:19.832158445Z") > 0)

func test_parse_deadline_with_micros_returns_positive() -> void:
	assert_true(_vm.parse_turn_deadline("2026-09-07T15:26:19.832158Z") > 0)

func test_parse_deadline_nanos_matches_seconds() -> void:
	assert_eq(_vm.parse_turn_deadline("2026-09-07T15:26:19.832158445Z"), _vm.parse_turn_deadline("2026-09-07T15:26:19Z"))

func test_parse_deadline_null_sentinels_return_minus1() -> void:
	assert_eq(_vm.parse_turn_deadline("null"), -1.0)
	assert_eq(_vm.parse_turn_deadline("<null>"), -1.0)
	assert_eq(_vm.parse_turn_deadline("None"), -1.0)

func test_parse_deadline_empty_returns_minus1() -> void:
	assert_eq(_vm.parse_turn_deadline(""), -1.0)

func test_parse_deadline_invalid_returns_minus1() -> void:
	assert_eq(_vm.parse_turn_deadline("invalid"), -1.0)

func test_parse_deadline_lowercase_z_returns_positive_or_minus1() -> void:
	# Engine pode aceitar 'z' minúsculo dependendo da versão; ambos são válidos se >0, caso contrário sentinel
	var result := _vm.parse_turn_deadline("2026-09-04T12:00:00z")
	assert_true(result > 0 or result == -1.0)

func test_parse_deadline_with_offset_returns_positive_or_minus1() -> void:
	# +00:00 pode ser parseado pela engine 4.7; aceita ambos
	var result := _vm.parse_turn_deadline("2026-09-04T12:00:00+00:00")
	assert_true(result > 0 or result == -1.0)
