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
	var board := GameBoardMapper.to_domain([[{"letter":"A","revealed":true,"revealedBy":"me"}]])
	_vm._on_board_updated(board)

func test_word_found_is_claimed_before_feedback() -> void:
	watch_signals(_vm)
	var cells: Array = [Vector2i(0, 0), Vector2i(0, 1)]
	_vm._on_word_found(cells, "me", true)
	assert_signal_emitted(_vm, "word_found_feedback")
	assert_eq(_vm.get_cell_visual_state(0, 0), GameViewModel.CELL_STATE_CLAIMED_ME)
	assert_eq(_vm.get_cell_visual_state(0, 1), GameViewModel.CELL_STATE_CLAIMED_ME)
	# board reemit should have happened
	assert_signal_emitted(_vm, "board_changed")

func test_word_found_opponent_claimed() -> void:
	var cells: Array = [Vector2i(1, 1)]
	_vm._on_word_found(cells, "opp", false)
	assert_eq(_vm.get_cell_visual_state(1, 1), GameViewModel.CELL_STATE_CLAIMED_OPPONENT)
