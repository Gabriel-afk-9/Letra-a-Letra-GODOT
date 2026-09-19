extends RefCounted
class_name GameUseCase


signal board_updated(board: GameBoard)
signal words_updated(words: Array)
signal my_inventory_updated(inventory: Array)
signal opponent_inventory_updated(inventory: Array)
signal my_avatar_updated(avatar_asset_path: String)
signal opponent_avatar_updated(avatar_asset_path: String)
signal power_granted(power: GamePower)
signal turn_changed(current_turn_player_id: String, turn_ends_at: String, is_my_turn: bool)
signal turn_passed
signal my_cell_revealed
signal word_found(cells: Array, found_by_player_id: String, is_me: bool)
signal trap_event(event_name: String, x: int, y: int)
signal my_effect_event(event_name: String)
signal my_effects_snapshot(is_frozen: bool, is_blinded: bool, is_immune: bool, freeze_duration: int, blind_duration: int, immune_duration: int)
signal spy_position_changed(pos: Vector2i, active: bool)
signal game_over(is_winner: bool, reason: String)
signal connection_lost(message: String)
signal action_rejected(error_code: String, cell_x: int, cell_y: int)

var _repository: GameRepository
var _current_user_provider: CurrentUserProvider
var _opponent_id: String = ""
var _my_avatar_path: String = ""
var _opponent_avatar_path: String = ""

var _previous_my_inventory_ids: Dictionary = {}
var _my_inventory_synced: bool = false
var _my_had_effects: bool = false
var _my_effects_synced: bool = false
var _my_spy_pos := Vector2i(-1, -1)
var _my_spy_active: bool = false
var _my_snapshot_synced: bool = false
var _my_last_snapshot_frozen: bool = false
var _my_last_snapshot_blinded: bool = false
var _my_last_snapshot_immune: bool = false


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



func start(game_id: String, opponent_id: String, my_avatar: String = "", opponent_avatar: String = "") -> void:
	_opponent_id = opponent_id
	_my_avatar_path = my_avatar
	_opponent_avatar_path = opponent_avatar
	_repository.start(game_id)
	if not my_avatar.is_empty():
		my_avatar_updated.emit(my_avatar)
	if not opponent_avatar.is_empty():
		opponent_avatar_updated.emit(opponent_avatar)


func reveal_cell(x: int, y: int) -> void:
	_repository.reveal_cell(x, y)


func use_cell_power(power_id: String, power_type: String, x: int, y: int) -> void:
	_repository.use_power_on_cell(power_id, power_type, x, y)


func use_power_on_cell(power_id: String, power_type: String, x: int, y: int) -> void:
	_repository.use_power_on_cell(power_id, power_type, x, y)


func use_global_power(power_id: String, power_type: String) -> void:
	if GamePowerCatalog.is_offensive(power_type):
		_repository.use_global_power(power_id, power_type, _opponent_id)
	else:
		_repository.use_self_power(power_id, power_type)


func discard_power(power_id: String) -> void:
	_repository.discard_power(power_id)


func leave_game() -> void:
	_repository.leave_game()


func get_my_id() -> String:
	var user := _current_user_provider.current_user()
	return user.id if user != null else ""

func classify_player(player_id: String) -> String:
	var user := _current_user_provider.current_user()

	if user != null and player_id == user.id:
		return "me"

	if player_id == _opponent_id:
		return "opponent"

	return ""



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
			_emit_power_granted(player.inventory)
			_sync_my_effects(player.effects)
			if not player.avatar_asset_path.is_empty() and player.avatar_asset_path != _my_avatar_path:
				_my_avatar_path = player.avatar_asset_path
				my_avatar_updated.emit(player.avatar_asset_path)
		elif player.player_id == _opponent_id:
			opponent_inventory_updated.emit(player.inventory)
			if not player.avatar_asset_path.is_empty() and player.avatar_asset_path != _opponent_avatar_path:
				_opponent_avatar_path = player.avatar_asset_path
				opponent_avatar_updated.emit(player.avatar_asset_path)


func _emit_power_granted(inventory: Array) -> void:
	var current_ids := {}
	var new_powers: Array = []

	for power in inventory:
		if not power is GamePower:
			continue

		current_ids[power.id] = true

		if _my_inventory_synced and not _previous_my_inventory_ids.has(power.id):
			new_powers.append(power)

	_previous_my_inventory_ids = current_ids
	_my_inventory_synced = true

	for power in new_powers:
		power_granted.emit(power)


func _sync_my_effects(effects: Array) -> void:
	var has_effects := not effects.is_empty()
	var spy_pos := Vector2i(-1, -1)
	var has_spy := false

	for entry in effects:
		if not entry is Dictionary:
			continue

		var raw_position = (entry as Dictionary).get("position")

		if not raw_position is Dictionary:
			continue

		var pos_dict: Dictionary = raw_position
		var raw_x = pos_dict.get("x")
		var raw_y = pos_dict.get("y")

		if (raw_x is int or raw_x is float) and (raw_y is int or raw_y is float):
			spy_pos = Vector2i(int(raw_x), int(raw_y))
			has_spy = true
			break

	var has_freeze_snapshot: bool = _has_effect_keyword(effects, "FROZ")
	var has_blind_snapshot: bool = _has_effect_keyword(effects, "BLIND")
	var has_immune_snapshot: bool = _has_effect_keyword(effects, "IMMUN")
	var freeze_dur: int = _find_duration_for_keyword(effects, "FROZ")
	var blind_dur: int = _find_duration_for_keyword(effects, "BLIND")
	var immune_dur: int = _find_duration_for_keyword(effects, "IMMUN")
	if not _my_snapshot_synced:
		_my_last_snapshot_frozen = has_freeze_snapshot
		_my_last_snapshot_blinded = has_blind_snapshot
		_my_last_snapshot_immune = has_immune_snapshot
		_my_snapshot_synced = true
		my_effects_snapshot.emit(has_freeze_snapshot, has_blind_snapshot, has_immune_snapshot, freeze_dur, blind_dur, immune_dur)
	else:
		if has_freeze_snapshot != _my_last_snapshot_frozen or has_blind_snapshot != _my_last_snapshot_blinded or has_immune_snapshot != _my_last_snapshot_immune or freeze_dur != -1 or blind_dur != -1 or immune_dur != -1:
			_my_last_snapshot_frozen = has_freeze_snapshot
			_my_last_snapshot_blinded = has_blind_snapshot
			_my_last_snapshot_immune = has_immune_snapshot
			my_effects_snapshot.emit(has_freeze_snapshot, has_blind_snapshot, has_immune_snapshot, freeze_dur, blind_dur, immune_dur)
		elif has_effects:
			pass

	if not _my_effects_synced:
		_my_had_effects = has_effects
		_my_spy_pos = spy_pos
		_my_spy_active = has_spy
		_my_effects_synced = true

		if has_spy:
			spy_position_changed.emit(spy_pos, true)

		return

	if has_spy and (not _my_spy_active or _my_spy_pos != spy_pos):
		spy_position_changed.emit(spy_pos, true)
	elif not has_spy and _my_spy_active:
		spy_position_changed.emit(_my_spy_pos, false)

	_my_spy_pos = spy_pos
	_my_spy_active = has_spy

	if _my_had_effects and not has_effects:
		pass
	_my_had_effects = has_effects


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
		"TRAP_TRIGGERED", "TRAP_REMOVED", "TRAP_DETECTED", "CELL_TRAPPED", "CELL_BLOCKED", "CELL_STILL_BLOCKED", "CELL_UNBLOCKED":
			trap_event.emit(event.event_name, event.get_cell_x(), event.get_cell_y())
		"WORD_FOUNDED", "WORD_FOUND":
			var user := _current_user_provider.current_user()
			var founded_by := event.get_founded_by_player_id()
			var is_me := user != null and founded_by == user.id

			word_found.emit(event.get_founded_cells(), founded_by, is_me)
		"CELL_REVEALED":
			_handle_cell_revealed(event)
		"TURN_PASSED":
			turn_passed.emit()
		"PLAYER_BLINDED", "PLAYER_USE_LANTERN", "PLAYER_FROZEN", "PLAYER_UNFREEZE", "PLAYER_USE_IMMUNITY", "IMMUNITY_APPLIED", "IMMUNITY_REMOVED", "TRAPS_DETECTED", "DETECT_TRAPS_REMOVED", "SPY_APPLIED", "SPY_REMOVED", "PLAYER_SPIED":
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

		if event.event_name == "SPY_APPLIED":
			var pos := event.get_effect_position()

			if pos.x >= 0 and pos.y >= 0:
				spy_position_changed.emit(pos, true)
		elif event.event_name == "SPY_REMOVED":
			spy_position_changed.emit(Vector2i(-1, -1), false)


func _has_effect_keyword(effects: Array, keyword: String) -> bool:
	var key_upper: String = keyword.to_upper()
	for entry in effects:
		if entry is String:
			if (entry as String).to_upper().contains(key_upper):
				return true
		elif entry is Dictionary:
			if _deep_contains_keyword(entry as Dictionary, key_upper):
				return true
		else:
			var s: String = str(entry).to_upper()
			if s.contains(key_upper):
				return true
	return false


func _deep_contains_keyword(node: Variant, keyword_upper: String) -> bool:
	if node is Dictionary:
		for v in (node as Dictionary).values():
			if _deep_contains_keyword(v, keyword_upper):
				return true
		for k in (node as Dictionary).keys():
			if str(k).to_upper().contains(keyword_upper):
				return true
		return false
	if node is Array:
		for v in (node as Array):
			if _deep_contains_keyword(v, keyword_upper):
				return true
		return false
	if node is String:
		return (node as String).to_upper().contains(keyword_upper)
	var s2: String = str(node).to_upper()
	return s2.contains(keyword_upper)


func _find_duration_for_keyword(effects: Array, keyword: String) -> int:
	var key_upper: String = keyword.to_upper()
	for entry in effects:
		var entry_has: bool = false
		if entry is String:
			if (entry as String).to_upper().contains(key_upper):
				entry_has = true
		elif entry is Dictionary:
			if _deep_contains_keyword(entry as Dictionary, key_upper):
				entry_has = true
		else:
			if str(entry).to_upper().contains(key_upper):
				entry_has = true
		if not entry_has:
			continue
		if entry is Dictionary:
			var d: Dictionary = entry as Dictionary
			for k in d.keys():
				var ks: String = str(k).to_upper()
				if ks.contains("DURAT") or ks.contains("TURN") or ks.contains("REMAIN") or ks == "DURATION":
					var v = d.get(k)
					if v is int or v is float:
						return int(v)
			var deep: int = _deep_find_duration(entry as Dictionary)
			if deep != -1:
				return deep
	return -1


func _deep_find_duration(node: Variant) -> int:
	if node is Dictionary:
		for k in (node as Dictionary).keys():
			var ks: String = str(k).to_upper()
			if ks.contains("DURAT") or ks.contains("REMAIN") or ks == "DURATION" or ks == "TURNS" or ks == "TURNS_LEFT":
				var v = (node as Dictionary).get(k)
				if v is int or v is float:
					return int(v)
		for v in (node as Dictionary).values():
			var r: int = _deep_find_duration(v)
			if r != -1:
				return r
	elif node is Array:
		for v in (node as Array):
			var r2: int = _deep_find_duration(v)
			if r2 != -1:
				return r2
	return -1
