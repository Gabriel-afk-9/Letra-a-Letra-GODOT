class_name Room

var room_id: String
var players_count: int
var max_players: int
var status: String

func _init(p_id: String, p_count: int, p_max: int, p_status: String) -> void:
	room_id = p_id
	players_count = p_count
	max_players = p_max
	status = p_status

func is_full() -> bool:
	return players_count >= max_players
