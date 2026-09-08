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

func test_action_lock_timeout_is_1_2() -> void:
	assert_eq(GameViewModel.ACTION_LOCK_TIMEOUT_SECONDS, 1.2)

func test_lock_releases_after_1_2_not_3() -> void:
	_vm.on_cell_clicked(0, 0)
	assert_true(_vm.is_action_locked())
	await wait_seconds(1.3)
	assert_false(_vm.is_action_locked(), "should unlock after 1.2s")
