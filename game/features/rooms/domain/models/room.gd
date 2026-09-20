extends RefCounted
class_name Room

const STATUS_WAITING := "WAITING"
const STATUS_RUNNING := "RUNNING"
const STATUS_CLOSED := "CLOSED"
const STATUS_CANCELED := "CANCELED"

var game_id: String
var game_name: String
var type: String
var status: String
var participants: Array
var positions: Dictionary
var matches: Array


func _init(
	p_game_id: String = "",
	p_game_name: String = "",
	p_type: String = "",
	p_status: String = "",
	p_participants: Array = [],
	p_positions: Dictionary = {},
	p_matches: Array = []
) -> void:
	game_id = p_game_id
	game_name = p_game_name
	type = p_type
	status = p_status
	participants = p_participants
	positions = p_positions
	matches = p_matches


func display_name() -> String:
	if not game_name.strip_edges().is_empty():
		return game_name
	return "Sala %s" % short_id()


func short_id() -> String:
	if game_id.length() > 8:
		return game_id.left(8)
	return game_id


func players_count() -> int:
	return participants.size()


func host_name() -> String:
	for participant_variant in participants:
		if not participant_variant is Dictionary:
			continue
		var nickname := str((participant_variant as Dictionary).get("nickname", ""))
		if not nickname.strip_edges().is_empty():
			return nickname
	return "—"


func is_joinable() -> bool:
	return status == STATUS_WAITING


func status_label() -> String:
	match status:
		STATUS_WAITING:
			return "Aguardando jogadores"
		STATUS_RUNNING:
			return "Em andamento"
		STATUS_CLOSED:
			return "Fechada"
		STATUS_CANCELED:
			return "Cancelada"
	return status
