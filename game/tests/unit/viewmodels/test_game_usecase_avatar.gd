extends GutTest

var _fake_repo: FakeGameRepository
var _fake_provider: FakeCurrentUserProvider
var _usecase: GameUseCase


func before_each() -> void:
	_fake_repo = FakeGameRepository.new()
	_fake_provider = FakeCurrentUserProvider.new()
	_fake_provider.set_user("me", "Eu")
	_usecase = GameUseCase.new(_fake_repo, _fake_provider)
	_usecase._opponent_id = "opp"


func _state(player_id: String, avatar: String) -> GamePlayerState:
	return GamePlayerState.new(player_id, [], [], avatar)


func test_avatar_emitted_once_per_path_change() -> void:
	watch_signals(_usecase)
	_usecase._on_players_updated([_state("me", "AVATAR/ceo.webp"), _state("opp", "AVATAR/evil.png")])
	assert_signal_emitted_with_parameters(_usecase, "my_avatar_updated", ["AVATAR/ceo.webp"])
	assert_signal_emitted_with_parameters(_usecase, "opponent_avatar_updated", ["AVATAR/evil.png"])
	watch_signals(_usecase)
	_usecase._on_players_updated([_state("me", "AVATAR/ceo.webp"), _state("opp", "AVATAR/evil.png")])
	assert_signal_not_emitted(_usecase, "my_avatar_updated")
	assert_signal_not_emitted(_usecase, "opponent_avatar_updated")


func test_avatar_associated_by_id_not_position() -> void:
	watch_signals(_usecase)
	_usecase._on_players_updated([_state("opp", "AVATAR/opp.webp"), _state("me", "AVATAR/me.webp")])
	assert_signal_emitted_with_parameters(_usecase, "my_avatar_updated", ["AVATAR/me.webp"])
	assert_signal_emitted_with_parameters(_usecase, "opponent_avatar_updated", ["AVATAR/opp.webp"])


func test_empty_avatar_never_emits() -> void:
	watch_signals(_usecase)
	_usecase._on_players_updated([_state("me", ""), _state("opp", "")])
	assert_signal_not_emitted(_usecase, "my_avatar_updated")
	assert_signal_not_emitted(_usecase, "opponent_avatar_updated")


func test_start_emits_initial_avatars() -> void:
	watch_signals(_usecase)
	_usecase.start("g1", "opp", "AVATAR/me.webp", "AVATAR/opp.webp")
	assert_signal_emitted_with_parameters(_usecase, "my_avatar_updated", ["AVATAR/me.webp"])
	assert_signal_emitted_with_parameters(_usecase, "opponent_avatar_updated", ["AVATAR/opp.webp"])
