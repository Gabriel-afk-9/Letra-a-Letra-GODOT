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

func _board_hidden() -> GameBoard:
	return GameBoardMapper.to_domain([[{"revealed": false, "letter": "A", "revealedBy": ""}]])

func _board_revealed_me() -> GameBoard:
	return GameBoardMapper.to_domain([[{"revealed": true, "letter": "A", "revealedBy": "me"}]])

func _board_revealed_opp() -> GameBoard:
	return GameBoardMapper.to_domain([[{"revealed": true, "letter": "B", "revealedBy": "opp"}]])

func test_hidden_stays_hidden_when_blinded() -> void:
	_vm._on_board_updated(_board_hidden())
	_vm._on_my_effect_event("PLAYER_BLINDED")
	assert_true(_vm.is_blinded())
	assert_eq(_vm.get_cell_visual_state(0, 0), GameViewModel.CELL_STATE_HIDDEN)
	assert_eq(_vm.get_cell_letter(0, 0), "")

func test_revealed_me_becomes_blinded() -> void:
	_vm._on_board_updated(_board_revealed_me())
	assert_eq(_vm.get_cell_visual_state(0, 0), GameViewModel.CELL_STATE_REVEALED_ME)
	_vm._on_my_effect_event("PLAYER_BLINDED")
	assert_eq(_vm.get_cell_visual_state(0, 0), GameViewModel.CELL_STATE_BLINDED)
	assert_eq(_vm.get_cell_letter(0, 0), "")

func test_revealed_opponent_becomes_blinded() -> void:
	_vm._on_board_updated(_board_revealed_opp())
	_vm._on_my_effect_event("PLAYER_BLINDED")
	assert_eq(_vm.get_cell_visual_state(0, 0), GameViewModel.CELL_STATE_BLINDED)

func test_claimed_stays_claimed_when_blinded() -> void:
	_vm._on_board_updated(_board_revealed_me())
	_vm._on_word_found([Vector2i(0, 0)], "me", true)
	assert_eq(_vm.get_cell_visual_state(0, 0), GameViewModel.CELL_STATE_CLAIMED_ME)
	_vm._on_my_effect_event("PLAYER_BLINDED")
	assert_eq(_vm.get_cell_visual_state(0, 0), GameViewModel.CELL_STATE_CLAIMED_ME)

func test_block_stays_block_when_blinded() -> void:
	var board := GameBoardMapper.to_domain([[{"revealed": false, "letter": null, "effect": {"effect": "BLOCK", "ownerId": "me", "remainingClicks": 3}}]])
	_vm._on_board_updated(board)
	assert_eq(_vm.get_cell_visual_state(0, 0), GameViewModel.CELL_STATE_BLOCK_ME)
	_vm._on_my_effect_event("PLAYER_BLINDED")
	assert_eq(_vm.get_cell_visual_state(0, 0), GameViewModel.CELL_STATE_BLOCK_ME)

func test_spy_wins_over_blind() -> void:
	_vm._on_board_updated(_board_hidden())
	_vm._on_my_effect_event("PLAYER_BLINDED")
	# spy ativa em (0,0) ainda hidden mas spied
	_vm._on_my_effect_event("SPY_APPLIED")
	# simula spy position via usecase fallback
	_vm._has_spied = true
	_vm._spied_cell = Vector2i(0, 0)
	assert_eq(_vm.get_cell_visual_state(0, 0), GameViewModel.CELL_STATE_SPY_ME)
	assert_eq(_vm.get_cell_letter(0, 0), "A")

func test_lantern_clears_blind_restores_revealed() -> void:
	_vm._on_board_updated(_board_revealed_me())
	_vm._on_my_effect_event("PLAYER_BLINDED")
	assert_eq(_vm.get_cell_visual_state(0, 0), GameViewModel.CELL_STATE_BLINDED)
	_vm._on_my_effect_event("PLAYER_USE_LANTERN")
	assert_false(_vm.is_blinded())
	assert_eq(_vm.get_cell_visual_state(0, 0), GameViewModel.CELL_STATE_REVEALED_ME)
	assert_eq(_vm.get_cell_letter(0, 0), "A")

func test_immunity_clears_blind() -> void:
	_vm._on_board_updated(_board_revealed_me())
	_vm._on_my_effect_event("PLAYER_BLINDED")
	_vm._on_my_effect_event("PLAYER_USE_IMMUNITY")
	assert_false(_vm.is_blinded())
	assert_true(_vm.is_immune())
	assert_eq(_vm.get_cell_visual_state(0, 0), GameViewModel.CELL_STATE_REVEALED_ME)

func test_blind_decrements_on_any_turn() -> void:
	_vm._on_my_effect_event("PLAYER_BLINDED")
	assert_eq(_vm._blind_turns_left, 6)
	_vm._on_turn_changed("opp", "", false)
	assert_eq(_vm._blind_turns_left, 5)
