extends RefCounted
class_name MatchmakingPlayer


var id: String
var nickname: String
var avatar_asset_path: String


func _init(
	p_id: String,
	p_nickname: String,
	p_avatar_asset_path: String = ""
) -> void:
	id = p_id
	nickname = p_nickname
	avatar_asset_path = p_avatar_asset_path


func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"nickname": nickname,
		"avatar_asset_path": avatar_asset_path
	}

static func from_dictionary(
	data: Dictionary
) -> MatchmakingPlayer:
	return MatchmakingPlayerMapper.to_domain(data)
