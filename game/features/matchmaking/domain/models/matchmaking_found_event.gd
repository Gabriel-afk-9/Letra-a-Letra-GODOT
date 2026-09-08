extends RefCounted
class_name MatchmakingFoundEvent

var game_id: String
var me: MatchmakingPlayer
var opponent: MatchmakingPlayer
var current_turn_player_id: String


func _init(
	p_game_id: String,
	p_me: MatchmakingPlayer,
	p_opponent: MatchmakingPlayer,
	p_current_turn_player_id: String = ""
) -> void:
	game_id = p_game_id
	me = p_me
	opponent = p_opponent
	current_turn_player_id = p_current_turn_player_id


func to_dictionary() -> Dictionary:
	return {
		"game_id": game_id,
		"me": me.to_dictionary(),
		"opponent": opponent.to_dictionary(),
		"current_turn_player_id": current_turn_player_id
	}


static func from_dictionary(data: Dictionary) -> MatchmakingFoundEvent:
	return MatchmakingFoundEventMapper.to_domain(data)
