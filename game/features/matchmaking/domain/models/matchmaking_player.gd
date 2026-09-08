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
	return MatchmakingPlayerMapper.to_domain(data)
