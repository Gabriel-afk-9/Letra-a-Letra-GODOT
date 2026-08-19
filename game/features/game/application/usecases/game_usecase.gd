extends RefCounted
class_name GameUseCase


signal board_updated(board: GameBoard)
signal words_updated(words: Array)
signal my_inventory_updated(inventory: Array)
signal opponent_inventory_updated(inventory: Array)
signal turn_changed(current_turn_player_id: String, turn_ends_at: String, is_my_turn: bool)
signal my_cell_revealed
signal word_found(cells: Array, found_by_player_id: String, is_me: bool)
signal trap_event(event_name: String, x: int, y: int)
signal my_effect_event(event_name: String)
signal game_over(is_winner: bool, reason: String)
signal connection_lost(message: String)
signal action_rejected(error_code: String, cell_x: int, cell_y: int)

var _repository: GameRepository
var _current_user_provider: CurrentUserProvider
var _opponent_id: String = ""


func _init(repository: GameRepository, current_user_provider: CurrentUserProvider) -> void:
	_repository = repository
	_current_user_provider = current_user_provider

	_repository.turn_updated.connect(_on_turn_updated)
	_repository.board_updated.connect(_on_board_updated)
	_repository.words_updated.connect(_on_words_updated)
	_repository.players_updated.connect(_on_players_updated)
	_repository.internal_event_received.connect(_on_internal_event_received)
	_repository.game_over.connect(_on_game_over)
	_repository.opponent_disconnected.connect(_on_opponent_disconnected)
	_repository.removed_for_inactivity.connect(_on_removed_for_inactivity)
	_repository.connection_lost.connect(_on_connection_lost)
	_repository.error.connect(_on_error)


# Public API — repasse direto, sem gate

func start(game_id: String, opponent_id: String) -> void:
	_opponent_id = opponent_id
	_repository.start(game_id)


func reveal_cell(x: int, y: int) -> void:
	_repository.reveal_cell(x, y)


func use_cell_power(power_id: String, power_type: String, x: int, y: int) -> void:
	_repository.use_cell_power(power_id, power_type, x, y)


func use_global_power(power_id: String, power_type: String) -> void:
	var target_id := _opponent_id

	if not GamePowerCatalog.is_offensive(power_type):
		var user := _current_user_provider.current_user()
		target_id = user.id if user != null else ""

	_repository.use_global_power(power_id, power_type, target_id)


func discard_power(power_id: String) -> void:
	_repository.discard_power(power_id)


func leave_game() -> void:
	_repository.leave_game()


func classify_player(player_id: String) -> String:
	var user := _current_user_provider.current_user()

	if user != null and player_id == user.id:
		return "me"

	if player_id == _opponent_id:
		return "opponent"

	return ""


# Internal — sinais do repository

func _on_board_updated(board: GameBoard) -> void:
	board_updated.emit(board)


func _on_words_updated(words: Array) -> void:
	words_updated.emit(words)


func _on_players_updated(players: Array) -> void:
	var user := _current_user_provider.current_user()

	if user == null:
		return

	for player_variant in players:
		if not player_variant is GamePlayerState:
			continue

		var player: GamePlayerState = player_variant

		if player.player_id == user.id:
			my_inventory_updated.emit(player.inventory)
		elif player.player_id == _opponent_id:
			opponent_inventory_updated.emit(player.inventory)


func _on_turn_updated(current_turn_player_id: String, turn_ends_at: String) -> void:
	var user := _current_user_provider.current_user()
	var is_my_turn := user != null and current_turn_player_id == user.id

	turn_changed.emit(current_turn_player_id, turn_ends_at, is_my_turn)


func _on_connection_lost(message: String) -> void:
	connection_lost.emit(message)


func _on_error(error_code: String, cell_x: int, cell_y: int) -> void:
	action_rejected.emit(error_code, cell_x, cell_y)



func _on_game_over(winner_player_id: String) -> void:
	var user := _current_user_provider.current_user()
	var is_winner := user != null and winner_player_id == user.id

	game_over.emit(is_winner, "WORDS")


func _on_opponent_disconnected() -> void:
	game_over.emit(true, "OPPONENT_LEFT")


func _on_removed_for_inactivity() -> void:
	game_over.emit(false, "INACTIVITY")


func _on_internal_event_received(event: GameInternalEvent) -> void:
	match event.event_name:
		"TRAP_TRIGGERED", "TRAP_REMOVED", "TRAP_DETECTED":
			trap_event.emit(event.event_name, event.get_cell_x(), event.get_cell_y())
		"WORD_FOUNDED", "WORD_FOUND":
			var user := _current_user_provider.current_user()
			var founded_by := event.get_founded_by_player_id()
			var is_me := user != null and founded_by == user.id

			word_found.emit(event.get_founded_cells(), founded_by, is_me)
		"CELL_REVEALED":
			_handle_cell_revealed(event)
		"PLAYER_BLINDED", "PLAYER_USE_LANTERN", "PLAYER_FROZEN", "PLAYER_UNFREEZE", "PLAYER_USE_IMMUNITY", "IMMUNITY_APPLIED", "IMMUNITY_REMOVED", "TRAPS_DETECTED", "DETECT_TRAPS_REMOVED", "SPY_APPLIED", "SPY_REMOVED":
			_handle_effect_event(event)
		_:
			AppLogger.debug("GameUseCase: unhandled internal event: %s" % event.event_name)


func _handle_cell_revealed(event: GameInternalEvent) -> void:
	var user := _current_user_provider.current_user()

	if user == null:
		return

	if event.get_revealed_by_player_id() == user.id:
		my_cell_revealed.emit()


func _handle_effect_event(event: GameInternalEvent) -> void:
	var user := _current_user_provider.current_user()

	if user == null:
		return

	if event.contains_player_id(user.id):
		my_effect_event.emit(event.event_name)
