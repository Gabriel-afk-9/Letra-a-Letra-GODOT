extends RefCounted
class_name RoomCreatedEvent

var game_id: String
var game_name: String


func _init(p_game_id: String = "", p_game_name: String = "") -> void:
	game_id = p_game_id
	game_name = p_game_name
