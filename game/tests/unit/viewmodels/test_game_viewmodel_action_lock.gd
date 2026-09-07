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

func test_lock_on_cell_click_and_second_noop() -> void:
	watch_signals(_vm)
	_vm.on_cell_clicked(0, 0)
	assert_true(_vm.is_action_locked())
	assert_signal_emitted(_vm, "action_lock_changed")
	# segundo clique imediato é noop — ainda locked, geração não reinicia lock
	var gen_before: int = _vm._action_lock_generation
	_vm.on_cell_clicked(1, 1)
	assert_true(_vm.is_action_locked())
	assert_eq(_vm._action_lock_generation, gen_before)

func test_unlock_on_action_rejected() -> void:
	_vm.on_cell_clicked(0, 0)
	assert_true(_vm.is_action_locked())
	watch_signals(_vm)
	_vm._on_action_rejected("stepped_on_trap", 1, 1)
	assert_false(_vm.is_action_locked())
	assert_signal_emitted(_vm, "action_lock_changed")
	assert_signal_emitted(_vm, "trap_animation_requested")

func test_unlock_on_turn_pass() -> void:
	_vm.on_cell_clicked(0, 0)
	assert_true(_vm.is_action_locked())
	_vm._on_turn_changed("opp", "", false)
	assert_false(_vm.is_action_locked())

func test_generation_increments_on_lock_and_unlock() -> void:
	var gen0: int = _vm._action_lock_generation
	_vm.on_cell_clicked(0, 0)
	assert_true(_vm._action_lock_generation > gen0)
	var gen1: int = _vm._action_lock_generation
	_vm._on_action_rejected("player_are_immune", -1, -1)
	assert_true(_vm._action_lock_generation > gen1)

func test_select_power_global_locks_immediately() -> void:
	# inventário precisa conter o poder para on_power_clicked; select_power não checa inventário
	watch_signals(_vm)
	_vm.select_power("id-freeze", "FREEZE")
	assert_true(_vm.is_action_locked())
	assert_eq(_fake_repo.last_global_power.get("type"), "FREEZE")

func test_select_power_cell_only_arms_without_lock() -> void:
	_vm.select_power("id-block", "BLOCK")
	assert_false(_vm.is_action_locked())
	assert_eq(_vm.selected_power_id(), "id-block")
	# clique na célula dispara o poder e então trava
	_vm.on_cell_clicked(1, 1)
	assert_true(_vm.is_action_locked())
	assert_eq(_fake_repo.last_power_on_cell.get("type"), "BLOCK")

func test_frozen_blocks_blind_but_allows_unfreeze() -> void:
	# prepara inventário
	var p_blind := GamePower.new("id-blind", "BLIND", "EPIC")
	var p_unfreeze := GamePower.new("id-unfreeze", "UNFREEZE", "RARE")
	_vm._on_my_inventory_updated([p_blind, p_unfreeze])
	# congela
	_vm._on_my_effect_event("PLAYER_FROZEN")
	assert_true(_vm.is_frozen())
	_vm.on_power_clicked("id-blind")
	assert_eq(_vm.selected_power_id(), "")
	_vm.on_power_clicked("id-unfreeze")
	assert_eq(_vm.selected_power_id(), "id-unfreeze")

func test_frozen_allows_immunity() -> void:
	var p_imm := GamePower.new("id-imm", "IMMUNITY", "LEGENDARY")
	_vm._on_my_inventory_updated([p_imm])
	_vm._on_my_effect_event("PLAYER_FROZEN")
	_vm.on_power_clicked("id-imm")
	assert_eq(_vm.selected_power_id(), "id-imm")
