extends GameRepository
class_name FakeGameRepository

var start_game_id: String = ""
var last_reveal: Vector2i = Vector2i(-1, -1)
var last_power_on_cell: Dictionary = {}
var last_global_power: Dictionary = {}
var last_self_power: Dictionary = {}
var last_discard_id: String = ""
var leave_called: bool = false

# stubs sincrônicos herdados
func start(game_id: String) -> void:
	start_game_id = game_id

func reveal_cell(x: int, y: int) -> void:
	last_reveal = Vector2i(x, y)

func use_cell_power(power_id: String, power_type: String, x: int, y: int) -> void:
	use_power_on_cell(power_id, power_type, x, y)

func use_power_on_cell(power_id: String, power_type: String, x: int, y: int) -> void:
	last_power_on_cell = {"id": power_id, "type": power_type, "x": x, "y": y}

func use_global_power(power_id: String, power_type: String, target_id: String) -> void:
	last_global_power = {"id": power_id, "type": power_type, "target": target_id}

func use_self_power(power_id: String, power_type: String) -> void:
	last_global_power = {"id": power_id, "type": power_type, "target": ""}
	last_self_power = {"id": power_id, "type": power_type}

func discard_power(power_id: String) -> void:
	last_discard_id = power_id

func leave_game() -> void:
	leave_called = true

func force_ghost_leave() -> void:
	leave_called = true

# helpers para emitir sinais do contrato
func emit_board(board: GameBoard) -> void:
	board_updated.emit(board)

func emit_words(words: Array) -> void:
	words_updated.emit(words)

func emit_players(players: Array) -> void:
	players_updated.emit(players)

func emit_turn(current_turn_player_id: String, turn_ends_at: String) -> void:
	turn_updated.emit(current_turn_player_id, turn_ends_at)

func emit_internal_event(event: GameInternalEvent) -> void:
	internal_event_received.emit(event)

func emit_game_over(winner_id: String) -> void:
	game_over.emit(winner_id)

func emit_opponent_disconnected() -> void:
	opponent_disconnected.emit()

func emit_removed_for_inactivity() -> void:
	removed_for_inactivity.emit()

func emit_connection_lost(message: String) -> void:
	connection_lost.emit(message)

func emit_error(code: String, x: int = -1, y: int = -1) -> void:
	error.emit(code, x, y)
