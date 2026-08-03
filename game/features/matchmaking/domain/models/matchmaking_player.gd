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

	var id := ""
	if raw_id != null:
		id = str(raw_id)

	var nickname := ""
	if raw_nickname != null:
		nickname = str(raw_nickname)

	return MatchmakingPlayer.new(
		id,
		nickname
	)
