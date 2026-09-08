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

func test_board_visual_state_hides_revealed_cells() -> void:
	var board := GameBoardMapper.to_domain([[{"revealed": true, "letter": "A", "revealedBy": "me"}]])
	_vm._on_board_updated(board)
	assert_eq(_vm.get_cell_visual_state(0, 0), GameViewModel.CELL_STATE_REVEALED_ME)
	assert_ne(_vm.get_cell_visual_state(0, 0), GameViewModel.CELL_STATE_HIDDEN)
	# célula não revelada continua hidden
	assert_eq(_vm.get_cell_visual_state(1, 1), GameViewModel.CELL_STATE_HIDDEN)

func test_action_lock_dims_board() -> void:
	assert_false(_vm.is_action_locked())
	_vm.on_cell_clicked(0, 0)
	assert_true(_vm.is_action_locked())
	# view decidiria board_grid.mouse_filter = IGNORE quando locked
	# lógica de game_screen.gd:643 board_disabled = _global_power_armed or _action_locked
	var board_disabled: bool = _vm.is_action_locked()
	assert_true(board_disabled)

func test_action_lock_unlocked_after_turn_pass() -> void:
	_vm.on_cell_clicked(0, 0)
	_vm._on_turn_changed("opp", "", false)
	assert_false(_vm.is_action_locked())

func test_frozen_blocks_blind_but_allows_unfreeze() -> void:
	var p_blind := GamePower.new("id-blind", "BLIND", "EPIC")
	var p_unfreeze := GamePower.new("id-unfreeze", "UNFREEZE", "RARE")
	_vm._on_my_inventory_updated([p_blind, p_unfreeze])
	_vm._on_my_effect_event("PLAYER_FROZEN")
	assert_true(_vm.is_frozen())
	_vm.on_power_clicked("id-blind")
	assert_eq(_vm.selected_power_id(), "")
	_vm.on_power_clicked("id-unfreeze")
	assert_eq(_vm.selected_power_id(), "id-unfreeze")
