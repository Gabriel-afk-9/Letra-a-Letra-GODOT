extends RefCounted
class_name MatchmakingPlayer


var id: String
var nickname: String


func _init(
	p_id: String,
	p_nickname: String
) -> void:
	id = p_id
	nickname = p_nickname


func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"nickname": nickname
	}

static func from_dictionary(
	data: Dictionary
) -> MatchmakingPlayer:

	var raw_id = data.get("id")
	var raw_nickname = data.get("nickname")

	var player_id := ""
	if raw_id != null:
		player_id = str(raw_id)

	var player_nickname := ""
	if raw_nickname != null:
		player_nickname = str(raw_nickname)

	return MatchmakingPlayer.new(
		player_id,
		player_nickname
	)
