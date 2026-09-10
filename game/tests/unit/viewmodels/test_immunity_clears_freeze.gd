extends GutTest

var _fake_repo: FakeGameRepository
var _fake_provider: FakeCurrentUserProvider
var _usecase: GameUseCase
var _vm: GameViewModel

func before_each() -> void:
	_fake_repo = FakeGameRepository.new()
	_fake_provider = FakeCurrentUserProvider.new()
	_fake_provider.set_user("me", "Eu")
	_usecase = GameUseCase.new(_fake_repo, _fake_provider)
	_usecase._opponent_id = "opp"
	_vm = GameViewModel.new(_usecase, null)
	_vm._on_turn_changed("me", "", true)

func test_freeze_duration_is_6() -> void:
	assert_eq(GameViewModel.FREEZE_TURNS_DEFAULT, 6)

func test_immunity_duration_is_10() -> void:
	assert_eq(GameViewModel.IMMUNITY_TURNS_DEFAULT, 10)

func test_immunity_clears_freeze() -> void:
	_vm._on_my_effect_event("PLAYER_FROZEN")
	assert_true(_vm.is_frozen())
	assert_eq(_vm._freeze_turns_left, 6)
	_vm._on_my_effect_event("PLAYER_USE_IMMUNITY")
	assert_false(_vm.is_frozen())
	assert_eq(_vm._freeze_turns_left, 0)
	assert_true(_vm.is_immune())
	assert_eq(_vm._immunity_turns_left, 10)

func test_immunity_clears_blind() -> void:
	_vm._on_my_effect_event("PLAYER_BLINDED")
	assert_true(_vm.is_blinded())
	_vm._on_my_effect_event("PLAYER_USE_IMMUNITY")
	assert_false(_vm.is_blinded())
	assert_eq(_vm._blind_turns_left, 0)
	assert_true(_vm.is_immune())

func test_immunity_applied_also_clears_freeze_and_blind() -> void:
	_vm._on_my_effect_event("PLAYER_FROZEN")
	_vm._on_my_effect_event("PLAYER_BLINDED")
	_vm._on_my_effect_event("IMMUNITY_APPLIED")
	assert_false(_vm.is_frozen())
	assert_false(_vm.is_blinded())
	assert_true(_vm.is_immune())

func test_turn_decrement_on_any_turn_change() -> void:
	_vm._on_my_effect_event("PLAYER_FROZEN")
	assert_eq(_vm._freeze_turns_left, 6)
	# muda turno para oponente — antes só decrementava no próprio turno, agora decrementa em qualquer troca
	_vm._on_turn_changed("opp", "", false)
	assert_eq(_vm._freeze_turns_left, 5)
	assert_true(_vm.is_frozen())
	# volta para mim decrementa de novo
	_vm._on_turn_changed("me", "", true)
	assert_eq(_vm._freeze_turns_left, 4)

func test_immunity_decrements_on_opponent_turn() -> void:
	_vm._on_my_effect_event("PLAYER_USE_IMMUNITY")
	assert_eq(_vm._immunity_turns_left, 10)
	_vm._on_turn_changed("opp", "", false)
	assert_eq(_vm._immunity_turns_left, 9)
	_vm._on_turn_changed("me", "", true)
	assert_eq(_vm._immunity_turns_left, 8)

func test_same_turn_id_does_not_decrement() -> void:
	_vm._on_my_effect_event("PLAYER_FROZEN")
	_vm._on_turn_changed("me", "", true)
	var before := _vm._freeze_turns_left
	_vm._on_turn_changed("me", "", true)
	assert_eq(_vm._freeze_turns_left, before)
