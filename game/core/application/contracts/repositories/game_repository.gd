extends RefCounted

class_name GameRepository


signal turn_updated(current_turn_player_id: String, turn_ends_at: String)
signal board_updated(board: GameBoard)
signal words_updated(words: Array)
signal players_updated(players: Array)
signal internal_event_received(event: GameInternalEvent)
signal game_over(winner_player_id: String)
signal opponent_disconnected
signal removed_for_inactivity
signal connection_lost(message: String)
signal error(error_code: String, cell_x: int, cell_y: int)


func start(game_id: String) -> void:
	push_error("GameRepository.start() must be implemented.")


func reveal_cell(x: int, y: int) -> void:
	push_error("GameRepository.reveal_cell() must be implemented.")


func use_cell_power(power_id: String, power_type: String, x: int, y: int) -> void:
	push_error("GameRepository.use_cell_power() must be implemented.")


func use_global_power(power_id: String, power_type: String, target_id: String) -> void:
	push_error("GameRepository.use_global_power() must be implemented.")


func discard_power(power_id: String) -> void:
	push_error("GameRepository.discard_power() must be implemented.")


func leave_game() -> void:
	push_error("GameRepository.leave_game() must be implemented.")
