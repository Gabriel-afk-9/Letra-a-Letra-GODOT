extends RefCounted
class_name MatchmakingPlayer


var id: String
var nickname: String
var avatar_asset_path: String
var wins: int = 0
var streak: int = 0
var matches: int = 0
var has_stats: bool = false


func _init(
	p_id: String,
	p_nickname: String,
	p_avatar_asset_path: String = "",
	p_wins: int = 0,
	p_streak: int = 0,
	p_matches: int = 0,
	p_has_stats: bool = false
) -> void:
	id = p_id
	nickname = p_nickname
	avatar_asset_path = p_avatar_asset_path
	wins = p_wins
	streak = p_streak
	matches = p_matches
	has_stats = p_has_stats


func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"nickname": nickname,
		"avatar_asset_path": avatar_asset_path,
		"wins": wins,
		"streak": streak,
		"matches": matches,
		"has_stats": has_stats
	}

static func from_dictionary(
	data: Dictionary
) -> MatchmakingPlayer:
	return MatchmakingPlayerMapper.to_domain(data)
