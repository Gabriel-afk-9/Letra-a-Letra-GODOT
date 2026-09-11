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

func test_contested_returns_both_regardless_of_order() -> void:
	var pos := Vector2i(2, 3)
	_vm._on_word_found([pos], "me", true)
	assert_eq(_vm.get_cell_visual_state(2, 3), GameViewModel.CELL_STATE_CLAIMED_ME)
	_vm._on_word_found([pos], "opp", false)
	assert_eq(_vm.get_cell_visual_state(2, 3), GameViewModel.CELL_STATE_CLAIMED_BOTH)

func test_contested_reverse_order_also_both() -> void:
	var pos := Vector2i(5, 5)
	_vm._on_word_found([pos], "opp", false)
	assert_eq(_vm.get_cell_visual_state(5, 5), GameViewModel.CELL_STATE_CLAIMED_OPPONENT)
	_vm._on_word_found([pos], "me", true)
	assert_eq(_vm.get_cell_visual_state(5, 5), GameViewModel.CELL_STATE_CLAIMED_BOTH)

func test_contested_letter_shared_jesus_feliz() -> void:
	var e_pos := Vector2i(4, 5)
	_vm._on_word_found([Vector2i(3,5), e_pos, Vector2i(5,5), Vector2i(6,5), Vector2i(7,5)], "me", true)
	_vm._on_word_found([Vector2i(3,2), e_pos, Vector2i(5,2)], "opp", false)
	assert_eq(_vm.get_cell_visual_state(4, 5), GameViewModel.CELL_STATE_CLAIMED_BOTH)
	assert_eq(_vm.get_cell_visual_state(3, 5), GameViewModel.CELL_STATE_CLAIMED_ME)
	assert_eq(_vm.get_cell_visual_state(3, 2), GameViewModel.CELL_STATE_CLAIMED_OPPONENT)
