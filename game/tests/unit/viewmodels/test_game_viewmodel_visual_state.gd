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
	_vm = GameViewModel.new(_usecase, null)
	_usecase._opponent_id = "opp"

func test_board_null_returns_hidden() -> void:
	assert_eq(_vm.get_cell_visual_state(0, 0), GameViewModel.CELL_STATE_HIDDEN)
	assert_eq(_vm.get_cell_letter(0, 0), "")

func test_revealed_by_me_returns_revealed_me() -> void:
	var board := GameBoardMapper.to_domain([[{"revealed": true, "letter": "A", "revealedBy": "me"}]])
	_vm._on_board_updated(board)
	assert_eq(_vm.get_cell_visual_state(0, 0), GameViewModel.CELL_STATE_REVEALED_ME)
	assert_eq(_vm.get_cell_letter(0, 0), "A")

func test_revealed_by_opponent_returns_revealed_opponent() -> void:
	var board := GameBoardMapper.to_domain([[{"revealed": true, "letter": "B", "revealedBy": "opp"}]])
	_vm._on_board_updated(board)
	assert_eq(_vm.get_cell_visual_state(0, 0), GameViewModel.CELL_STATE_REVEALED_OPPONENT)

func test_claimed_me_precede_revealed_opponent() -> void:
	var board := GameBoardMapper.to_domain([[{"revealed": true, "letter": "B", "revealedBy": "opp"}]])
	_vm._on_board_updated(board)
	_vm._on_word_found([Vector2i(0, 0)], "me", true)
	assert_eq(_vm.get_cell_visual_state(0, 0), GameViewModel.CELL_STATE_CLAIMED_ME)

func test_claimed_opponent_isolated() -> void:
	var board := GameBoardMapper.to_domain([[{"revealed": true, "letter": "C", "revealedBy": "me"}]])
	_vm._on_board_updated(board)
	_vm._on_word_found([Vector2i(0, 0)], "opp", false)
	assert_eq(_vm.get_cell_visual_state(0, 0), GameViewModel.CELL_STATE_CLAIMED_OPPONENT)
	# outra célula continua hidden
	assert_eq(_vm.get_cell_visual_state(1, 1), GameViewModel.CELL_STATE_HIDDEN)

func test_revealed_unknown_player_returns_hidden() -> void:
	var board := GameBoardMapper.to_domain([[{"revealed": true, "letter": "X", "revealedBy": "unknown"}]])
	_vm._on_board_updated(board)
	assert_eq(_vm.get_cell_visual_state(0, 0), GameViewModel.CELL_STATE_HIDDEN)

func test_not_revealed_returns_hidden() -> void:
	var board := GameBoardMapper.to_domain([[{"revealed": false, "letter": "Z", "revealedBy": "me"}]])
	_vm._on_board_updated(board)
	assert_eq(_vm.get_cell_visual_state(0, 0), GameViewModel.CELL_STATE_HIDDEN)
	assert_eq(_vm.get_cell_letter(0, 0), "")

func test_get_cell_letter_uppercase() -> void:
	var board := GameBoardMapper.to_domain([[{"revealed": true, "letter": "a", "revealedBy": "me"}]])
	_vm._on_board_updated(board)
	assert_eq(_vm.get_cell_letter(0, 0), "A")
