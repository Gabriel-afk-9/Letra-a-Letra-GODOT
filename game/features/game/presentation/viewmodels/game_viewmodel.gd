extends BaseViewModel
class_name GameViewModel


const REASON_WORDS := "WORDS"
const REASON_OPPONENT_LEFT := "OPPONENT_LEFT"
const REASON_INACTIVITY := "INACTIVITY"

const CELL_STATE_HIDDEN := "HIDDEN"
const CELL_STATE_REVEALED_ME := "REVEALED_ME"
const CELL_STATE_REVEALED_OPPONENT := "REVEALED_OPPONENT"
const CELL_STATE_CLAIMED_ME := "CLAIMED_ME"
const CELL_STATE_CLAIMED_OPPONENT := "CLAIMED_OPPONENT"
const CELL_STATE_CLAIMED_BOTH := "CLAIMED_BOTH"
const CELL_STATE_SPY_ME := "SPY_ME"
const CELL_STATE_BLINDED := "BLINDED"
const CELL_STATE_TRAP_ME := "TRAP_ME"
const CELL_STATE_TRAP_OPPONENT := "TRAP_OPPONENT"
const CELL_STATE_BLOCK_ME := "BLOCK_ME"
const CELL_STATE_BLOCK_OPPONENT := "BLOCK_OPPONENT"

const FREEZE_TURNS_DEFAULT := 6
const IMMUNITY_TURNS_DEFAULT := 10
const BLIND_TURNS_DEFAULT := 6
const ACTION_LOCK_TIMEOUT_SECONDS := 0.7
const TURN_TIMER_TICK_SECONDS := 0.5


signal board_changed(board: GameBoard)
signal words_changed(words: Array)
signal my_inventory_changed(inventory: Array)
signal opponent_inventory_changed(inventory: Array)
signal power_granted(power: GamePower)
signal turn_state_changed(is_my_turn: bool)
signal turn_timer_updated(seconds_remaining: float)
signal action_lock_changed(is_locked: bool)
signal effect_state_changed
signal word_found_feedback(cells: Array, is_me: bool)
signal trap_event_feedback(event_name: String, x: int, y: int)
signal trap_animation_requested(x: int, y: int)
signal notification_requested(message: String)
signal selected_power_changed(power_id: String)
signal armed_power_changed(power_id: String, power_type: String, scope: String)
signal game_ended(is_winner: bool, title: String, subtitle: String)

var _usecase: GameUseCase
var _navigation: NavigationService

var _board: GameBoard = null
var _words: Array = []
var _my_inventory: Array = []
var _opponent_inventory: Array = []
var _is_my_turn: bool = false
var _turn_ends_at: String = ""
var _last_turn_player_id: String = ""
var _is_action_locked: bool = false
var _action_lock_generation: int = 0
var _turn_timer_generation: int = 0

var _is_frozen: bool = false
var _freeze_turns_left: int = 0
var _is_immune: bool = false
var _immunity_turns_left: int = 0
var _is_blinded: bool = false
var _blind_turns_left: int = 0
var _is_detecting_traps: bool = false
var _is_spied: bool = false

var _armed_power_id: String = ""
var _armed_power_type: String = ""
var _is_game_over: bool = false

var _opponent_id: String = ""
var _block_click_history: Dictionary = {}
var _pending_block_actor: String = ""
var _pending_block_pos := Vector2i(-1, -1)

var _cells_claimed_by_me: Array[Vector2i] = []
var _cells_claimed_by_opponent: Array[Vector2i] = []
var _spied_cell := Vector2i(-1, -1)
var _has_spied := false


func _init(usecase: GameUseCase, navigation: NavigationService) -> void:
	_usecase = usecase
	_navigation = navigation

	_usecase.board_updated.connect(_on_board_updated)
	_usecase.words_updated.connect(_on_words_updated)
	_usecase.my_inventory_updated.connect(_on_my_inventory_updated)
	_usecase.opponent_inventory_updated.connect(_on_opponent_inventory_updated)
	_usecase.power_granted.connect(_on_power_granted)
	_usecase.turn_changed.connect(_on_turn_changed)
	_usecase.my_cell_revealed.connect(_on_my_cell_revealed)
	_usecase.word_found.connect(_on_word_found)
	_usecase.trap_event.connect(_on_trap_event)
	_usecase.my_effect_event.connect(_on_my_effect_event)
	_usecase.spy_position_changed.connect(_on_spy_position_changed)
	_usecase.game_over.connect(_on_game_over)
	_usecase.connection_lost.connect(_on_connection_lost)
	_usecase.action_rejected.connect(_on_action_rejected)



func start(game_id: String, opponent_id: String) -> void:
	_is_game_over = false
	_opponent_id = opponent_id
	_block_click_history.clear()
	_pending_block_actor = ""
	_pending_block_pos = Vector2i(-1, -1)
	_set_loading(true)
	_usecase.start(game_id, opponent_id)
	_set_loading(false)


func on_cell_clicked(x: int, y: int) -> void:
	if _is_game_over:
		return

	if _is_action_locked:
		return

	if not _is_my_turn:
		return

	if _is_frozen:
		return

	var is_block_click := false
	if _board != null:
		var _cell := _board.get_cell(x, y)
		if _cell != null and _cell.effect_type.to_upper().contains("BLOCK"):
			is_block_click = true
			_pending_block_pos = Vector2i(x, y)
			_pending_block_actor = _usecase.get_my_id() if _usecase.has_method("get_my_id") else ""

	if not _armed_power_id.is_empty() and GamePowerCatalog.get_scope(_armed_power_type) == GamePowerCatalog.SCOPE_CELL:
		_usecase.use_power_on_cell(_armed_power_id, _armed_power_type, x, y)
		_armed_power_id = ""
		_armed_power_type = ""
		selected_power_changed.emit("")
		armed_power_changed.emit("", "", "")
	else:
		_usecase.reveal_cell(x, y)

	_lock_action()
	if not is_block_click:
		_pending_block_pos = Vector2i(-1, -1)
		_pending_block_actor = ""


func select_power(power_id: String, power_type: String) -> void:
	if not _is_my_turn:
		return

	if _is_frozen and not GamePowerCatalog.can_use_while_frozen(power_type):
		return

	if _is_action_locked and not GamePowerCatalog.can_use_while_frozen(power_type):
		return

	if GamePowerCatalog.get_scope(power_type) == GamePowerCatalog.SCOPE_GLOBAL:
		_usecase.use_global_power(power_id, power_type)
		_lock_action()
		return

	_armed_power_id = power_id
	_armed_power_type = power_type
	selected_power_changed.emit(power_id)
	armed_power_changed.emit(power_id, power_type, GamePowerCatalog.get_scope(power_type))


func on_power_clicked(power_id: String) -> void:
	var power: GamePower = null
	for p in _my_inventory:
		if p is GamePower and p.id == power_id:
			power = p
			break

	if power == null:
		return

	if _is_frozen and not GamePowerCatalog.can_use_while_frozen(power.type):
		return

	if _is_action_locked and not GamePowerCatalog.can_use_while_frozen(power.type):
		return

	var scope := GamePowerCatalog.get_scope(power.type)

	if _armed_power_id == power_id:
		clear_selected_power()
		return

	_armed_power_id = power_id
	_armed_power_type = power.type
	selected_power_changed.emit(power_id)
	armed_power_changed.emit(power_id, power.type, scope)


func confirm_armed_global_power() -> void:
	if _armed_power_id.is_empty():
		return

	if GamePowerCatalog.get_scope(_armed_power_type) != GamePowerCatalog.SCOPE_GLOBAL:
		return

	if not _is_my_turn:
		return

	if _is_frozen and not GamePowerCatalog.can_use_while_frozen(_armed_power_type):
		clear_selected_power()
		return

	if _is_action_locked and not GamePowerCatalog.can_use_while_frozen(_armed_power_type):
		return

	_usecase.use_global_power(_armed_power_id, _armed_power_type)
	_lock_action()
	clear_selected_power()


func clear_selected_power() -> void:
	_armed_power_id = ""
	_armed_power_type = ""
	selected_power_changed.emit("")
	armed_power_changed.emit("", "", "")


func discard_power(power_id: String) -> void:
	_usecase.discard_power(power_id)


func is_inventory_full() -> bool:
	return _count_my_powers() >= GamePlayerState.INVENTORY_SIZE


func discard_armed_power() -> void:
	if _armed_power_id.is_empty():
		return

	_usecase.discard_power(_armed_power_id)
	clear_selected_power()


func _count_my_powers() -> int:
	var total := 0

	for p in _my_inventory:
		if p is GamePower:
			total += 1

	return total


func leave_game() -> void:
	_usecase.leave_game()


func go_to_home() -> void:
	_navigation.go_to(AppRoutes.SHELL)


func board() -> GameBoard:
	return _board

func words() -> Array:
	return _words

func my_inventory() -> Array:
	return _my_inventory

func opponent_inventory() -> Array:
	return _opponent_inventory

func is_my_turn() -> bool:
	return _is_my_turn

func is_action_locked() -> bool:
	return _is_action_locked

func is_frozen() -> bool:
	return _is_frozen

func is_immune() -> bool:
	return _is_immune

func is_blinded() -> bool:
	return _is_blinded

func is_game_over() -> bool:
	return _is_game_over

func is_detecting_traps() -> bool:
	return _is_detecting_traps

func is_spied() -> bool:
	return _is_spied

func selected_power_id() -> String:
	return _armed_power_id



func get_cell_visual_state(x: int, y: int) -> String:
	var cell_position := Vector2i(x, y)

	if _cells_claimed_by_me.has(cell_position) and _cells_claimed_by_opponent.has(cell_position):
		return CELL_STATE_CLAIMED_BOTH

	if _cells_claimed_by_me.has(cell_position):
		return CELL_STATE_CLAIMED_ME

	if _cells_claimed_by_opponent.has(cell_position):
		return CELL_STATE_CLAIMED_OPPONENT

	if _board == null:
		if _has_spied and cell_position == _spied_cell:
			return CELL_STATE_SPY_ME

		return CELL_STATE_HIDDEN

	var cell := _board.get_cell(x, y)

	if cell == null or not cell.revealed:
		var effect_type := cell.effect_type.to_upper() if cell != null else ""
		var effect_owner := _usecase.classify_player(cell.effect_owner_id) if cell != null else ""

		if effect_type.contains("BLOCK"):
			if effect_owner == "me":
				return CELL_STATE_BLOCK_ME

			return CELL_STATE_BLOCK_OPPONENT

		if effect_type.contains("TRAP"):
			if effect_owner == "me":
				return CELL_STATE_TRAP_ME

			if effect_owner == "opponent" and _is_detecting_traps:
				return CELL_STATE_TRAP_OPPONENT

		if _has_spied and cell_position == _spied_cell:
			return CELL_STATE_SPY_ME

		return CELL_STATE_HIDDEN

	if _is_blinded:
		return CELL_STATE_BLINDED

	match _usecase.classify_player(cell.revealed_by_player_id):
		"me":
			return CELL_STATE_REVEALED_ME
		"opponent":
			return CELL_STATE_REVEALED_OPPONENT
		_:
			return CELL_STATE_HIDDEN


func get_cell_letter(x: int, y: int) -> String:
	if _board == null:
		return ""

	var cell := _board.get_cell(x, y)

	if cell == null:
		return ""

	if get_cell_visual_state(x, y) == CELL_STATE_SPY_ME:
		return cell.letter.to_upper() if not cell.letter.is_empty() else ""

	if not cell.revealed:
		return ""

	if _is_blinded:
		return ""

	return cell.letter.to_upper()


func get_cell_block_filled(x: int, y: int) -> int:
	if _board == null:
		return 0

	var cell := _board.get_cell(x, y)

	if cell == null or not cell.effect_type.to_upper().contains("BLOCK"):
		return 0

	if cell.remaining_clicks <= 0:
		return 0

	return clampi(3 - cell.remaining_clicks, 0, 3)


func get_block_click_colors(x: int, y: int) -> Array:
	var pos := Vector2i(x, y)
	var ids: Array = _block_click_history.get(pos, [])
	if ids.is_empty():
		var filled := get_cell_block_filled(x, y)
		if filled > 0:
			var owner_id := ""
			if _board != null:
				var _cell := _board.get_cell(x, y)
				if _cell != null:
					owner_id = _cell.effect_owner_id
			var owner_color := Color(0.5, 0.5, 0.5, 1)
			if not owner_id.is_empty():
				var owner := _usecase.classify_player(owner_id)
				if owner == "me":
					owner_color = Color(0.101960786, 0.57254905, 0.9019608, 1)
				elif owner == "opponent":
					owner_color = Color(0.9529412, 0.52156866, 0.09411765, 1)
			var fallback: Array = []
			for i in filled:
				fallback.append(owner_color)
			return fallback
	var colors: Array = []
	for pid in ids:
		var owner := _usecase.classify_player(pid)
		if owner == "me":
			colors.append(Color(0.101960786, 0.57254905, 0.9019608, 1))
		elif owner == "opponent":
			colors.append(Color(0.9529412, 0.52156866, 0.09411765, 1))
		else:
			colors.append(Color(0.5, 0.5, 0.5, 1))
	return colors


func get_spied_cell() -> Vector2i:
	return _spied_cell


func has_spied_cell() -> bool:
	return _has_spied


func classify_word_owner(word: GameWord) -> String:
	if not word.found:
		return ""

	return _usecase.classify_player(word.found_by_player_id)



func _lock_action() -> void:
	if _is_action_locked:
		return

	_is_action_locked = true
	action_lock_changed.emit(true)
	_schedule_action_unlock()


func _schedule_action_unlock() -> void:
	_action_lock_generation += 1
	var generation := _action_lock_generation

	await (Engine.get_main_loop() as SceneTree).create_timer(ACTION_LOCK_TIMEOUT_SECONDS).timeout

	if generation != _action_lock_generation or not _is_action_locked:
		return

	_unlock_action()


func _unlock_action() -> void:
	if not _is_action_locked:
		return

	_action_lock_generation += 1
	_is_action_locked = false
	action_lock_changed.emit(false)



func _on_board_updated(board: GameBoard) -> void:
	var old_board: GameBoard = _board
	_board = board
	board_changed.emit(board)
	_reconcile_block_history(board, old_board)


func _on_words_updated(words: Array) -> void:
	_words = words
	words_changed.emit(words)


func _on_my_inventory_updated(inventory: Array) -> void:
	_my_inventory = inventory
	my_inventory_changed.emit(inventory)


func _on_opponent_inventory_updated(inventory: Array) -> void:
	_opponent_inventory = inventory
	opponent_inventory_changed.emit(inventory)


func _on_power_granted(power: GamePower) -> void:
	power_granted.emit(power)



func _on_my_cell_revealed() -> void:
	pass


func _on_word_found(cells: Array, found_by_player_id: String, is_me: bool) -> void:
	var claimed_cells := _cells_claimed_by_me if is_me else _cells_claimed_by_opponent

	for cell_variant in cells:
		if not cell_variant is Vector2i:
			continue

		var cell_position: Vector2i = cell_variant

		if not claimed_cells.has(cell_position):
			claimed_cells.append(cell_position)

	word_found_feedback.emit(cells, is_me)

	if _board != null:
		board_changed.emit(_board)


func _on_trap_event(event_name: String, x: int, y: int) -> void:
	trap_event_feedback.emit(event_name, x, y)
	_sync_block_history_from_event(event_name, x, y)


func _reconcile_block_history(board: GameBoard, old_board: GameBoard) -> void:
	if board == null:
		return
	for x in 10:
		for y in 10:
			var pos := Vector2i(x, y)
			var cell := board.get_cell(x, y)
			var is_block := cell != null and cell.effect_type.to_upper().contains("BLOCK")
			if not is_block:
				if _block_click_history.has(pos):
					_block_click_history.erase(pos)
				if _pending_block_pos == pos:
					_pending_block_pos = Vector2i(-1, -1)
					_pending_block_actor = ""
				continue
			var new_filled := clampi(3 - cell.remaining_clicks, 0, 3) if cell.remaining_clicks >= 0 else 0
			var hist: Array = _block_click_history.get(pos, [])
			if hist.size() < new_filled:
				var need: int = new_filled - hist.size()
				for i in need:
					if _pending_block_pos == pos and not _pending_block_actor.is_empty():
						hist.append(_pending_block_actor)
						_pending_block_pos = Vector2i(-1, -1)
						_pending_block_actor = ""
					else:
						if not _opponent_id.is_empty():
							hist.append(_opponent_id)
						else:
							hist.append("")
				_block_click_history[pos] = hist
			elif hist.size() > new_filled:
				hist.resize(new_filled)
				_block_click_history[pos] = hist


func _sync_block_history_from_event(event_name: String, x: int, y: int) -> void:
	if event_name != "CELL_BLOCKED" and event_name != "CELL_STILL_BLOCKED" and event_name != "CELL_UNBLOCKED":
		return
	var pos := Vector2i(x, y)
	if event_name == "CELL_UNBLOCKED":
		if _block_click_history.has(pos):
			_block_click_history.erase(pos)
		if _pending_block_pos == pos:
			_pending_block_pos = Vector2i(-1, -1)
			_pending_block_actor = ""
		return
	if _pending_block_pos == pos and not _pending_block_actor.is_empty():
		return
	if not _block_click_history.has(pos) and _board != null:
		var cell := _board.get_cell(x, y)
		if cell != null and cell.effect_type.to_upper().contains("BLOCK"):
			var filled := clampi(3 - cell.remaining_clicks, 0, 3)
			var hist: Array = _block_click_history.get(pos, [])
			if hist.size() < filled:
				_block_click_history[pos] = hist


func _on_connection_lost(message: String) -> void:
	_set_error(message)


func _on_turn_changed(current_turn_player_id: String, turn_ends_at: String, is_my_turn: bool) -> void:
	if _is_game_over:
		return

	if current_turn_player_id != _last_turn_player_id:
		_apply_turn_effect_decrement()

	_last_turn_player_id = current_turn_player_id
	_is_my_turn = is_my_turn
	_turn_ends_at = turn_ends_at

	if not turn_ends_at.is_empty():
		var warm_deadline := _parse_turn_deadline(turn_ends_at)

		if warm_deadline > 0.0:
			turn_timer_updated.emit(maxf(0.0, warm_deadline - Time.get_unix_time_from_system()))

	turn_state_changed.emit(is_my_turn)

	if not is_my_turn:
		_unlock_action()

	_start_turn_timer_loop()


func _on_my_effect_event(event_name: String) -> void:
	match event_name:
		"PLAYER_FROZEN":
			_is_frozen = true
			_freeze_turns_left = FREEZE_TURNS_DEFAULT
		"PLAYER_UNFREEZE":
			_is_frozen = false
			_freeze_turns_left = 0
		"PLAYER_USE_IMMUNITY", "IMMUNITY_APPLIED":
			_is_frozen = false
			_freeze_turns_left = 0
			_is_blinded = false
			_blind_turns_left = 0
			_is_immune = true
			_immunity_turns_left = IMMUNITY_TURNS_DEFAULT
		"IMMUNITY_REMOVED":
			_is_immune = false
			_immunity_turns_left = 0
		"TRAPS_DETECTED":
			_is_detecting_traps = true
		"DETECT_TRAPS_REMOVED":
			_is_detecting_traps = false
		"SPY_APPLIED", "PLAYER_SPIED":
			_is_spied = true
		"SPY_REMOVED":
			_is_spied = false
		"PLAYER_BLINDED":
			_is_blinded = true
			_blind_turns_left = BLIND_TURNS_DEFAULT
		"PLAYER_USE_LANTERN":
			_is_blinded = false
			_blind_turns_left = 0
		_:
			AppLogger.debug("GameViewModel: efeito não mapeado: %s" % event_name)
			return

	effect_state_changed.emit()


func _on_spy_position_changed(pos: Vector2i, active: bool) -> void:
	if active:
		_spied_cell = pos
		_has_spied = true
	else:
		_spied_cell = Vector2i(-1, -1)
		_has_spied = false

	effect_state_changed.emit()

	if _board != null:
		board_changed.emit(_board)


func _apply_turn_effect_decrement() -> void:
	var changed := false

	if _is_frozen:
		_freeze_turns_left -= 1

		if _freeze_turns_left <= 0:
			_freeze_turns_left = 0
			_is_frozen = false

		changed = true

	if _is_immune:
		_immunity_turns_left -= 1

		if _immunity_turns_left <= 0:
			_immunity_turns_left = 0
			_is_immune = false

		changed = true

	if _is_blinded:
		_blind_turns_left -= 1

		if _blind_turns_left <= 0:
			_blind_turns_left = 0
			_is_blinded = false

		changed = true

	if changed:
		effect_state_changed.emit()


func _on_game_over(is_winner: bool, reason: String) -> void:
	if _is_game_over:
		return
	_is_game_over = true
	_turn_timer_generation += 1
	if is_winner and reason == REASON_WORDS and not _has_any_word_found():
		reason = REASON_OPPONENT_LEFT

	_is_action_locked = true
	action_lock_changed.emit(true)
	turn_state_changed.emit(false)
	await (Engine.get_main_loop() as SceneTree).create_timer(2.0).timeout
	_show_game_over(is_winner, reason)


func _has_any_word_found() -> bool:
	for word_variant in _words:
		if word_variant is GameWord and (word_variant as GameWord).found:
			return true

	return false


func _show_game_over(is_winner: bool, reason: String) -> void:
	var title := ""
	var subtitle := ""

	match [is_winner, reason]:
		[true, REASON_WORDS]:
			title = "🏆 VOCÊ VENCEU!"
			subtitle = "Parabéns! Você encontrou mais palavras."
		[false, REASON_WORDS]:
			title = "💀 VOCÊ PERDEU!"
			subtitle = "O oponente foi melhor dessa vez. Tente novamente!"
		[true, REASON_OPPONENT_LEFT]:
			title = "OPONENTE FUGIU"
			subtitle = "Você venceu! O oponente foi desconectado."
		[false, REASON_INACTIVITY]:
			title = "💤 DESCONECTADO"
			subtitle = "Você foi removido por inatividade."
		_:
			title = "🏁 FIM DE JOGO"
			subtitle = "O jogo terminou."

	game_ended.emit(is_winner, title, subtitle)


func _on_action_rejected(error_code: String, cell_x: int, cell_y: int) -> void:
	_unlock_action()

	var code := error_code.strip_edges().to_lower()

	if code == "stepped_on_trap" or code.contains("trap"):
		trap_animation_requested.emit(cell_x, cell_y)
	elif code == "player_are_immune" or code.contains("imune") or code.contains("immune"):
		notification_requested.emit("Ataque bloqueado! O oponente está imune 🛡️")
	elif code == "player_not_in_game" or code.contains("not currently in a game"):
		_show_game_over(true, REASON_OPPONENT_LEFT)
	elif code == "the selected cell has already been revealed" or code.contains("already been revealed") or code.contains("already_revealed"):
		pass
	elif code.contains("frozen") or code.contains("frozen_cannot_act"):
		notification_requested.emit("Congelado! Use DESCONGELAR ❄️")
	elif code.contains("not_your_turn") or code.contains("not your turn"):
		notification_requested.emit("Aguarde sua vez ⏳")
	elif code.contains("invalid_player_action") or code.contains("requested player action is invalid"):
		notification_requested.emit("Ação inválida.")
	else:
		notification_requested.emit("Ação inválida.")
		AppLogger.debug("GameViewModel: código de erro desconhecido: %s" % error_code)



func _start_turn_timer_loop() -> void:
	if _is_game_over:
		return

	if _turn_ends_at.is_empty():
		return

	var deadline := _parse_turn_deadline(_turn_ends_at)

	if deadline < 0:
		return

	_turn_timer_generation += 1
	_run_turn_timer_loop(_turn_timer_generation, deadline)


func parse_turn_deadline(datetime_string: String) -> float:
	return _parse_turn_deadline(datetime_string)


func _parse_turn_deadline(datetime_string: String) -> float:
	if datetime_string == "null" or datetime_string == "<null>" or datetime_string == "None":
		return -1.0

	var normalized := datetime_string.trim_suffix("Z")
	var dot := normalized.find(".")

	if dot != -1:
		normalized = normalized.substr(0, dot)

	var unix_time := Time.get_unix_time_from_datetime_string(normalized)

	if unix_time <= 0:
		return -1.0

	return float(unix_time)


func _run_turn_timer_loop(generation: int, deadline: float) -> void:
	while generation == _turn_timer_generation and not _is_game_over:
		var remaining := deadline - Time.get_unix_time_from_system()

		if remaining <= 0.0:
			turn_timer_updated.emit(0.0)
			return

		turn_timer_updated.emit(remaining)
		await (Engine.get_main_loop() as SceneTree).create_timer(TURN_TIMER_TICK_SECONDS).timeout
