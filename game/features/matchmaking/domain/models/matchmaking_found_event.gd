extends RefCounted
class_name MatchmakingFoundEvent


var game_token: String
var me: MatchmakingPlayer
var opponent: MatchmakingPlayer


func _init(
	p_game_token: String,
	p_me: MatchmakingPlayer,
	p_opponent: MatchmakingPlayer
) -> void:

	game_token = p_game_token
	me = p_me
	opponent = p_opponent


func to_dictionary() -> Dictionary:
	return {
		"game_token": game_token,
		"me": me.to_dictionary(),
		"opponent": opponent.to_dictionary()
	}

static func from_dictionary(
	data: Dictionary
) -> MatchmakingFoundEvent:

	return MatchmakingFoundEvent.new(
		str(data.get("game_token", "")),
		MatchmakingPlayer.from_dictionary(
			data.get("me", {})
		),
		MatchmakingPlayer.from_dictionary(
			data.get("opponent", {})
		)
	)
