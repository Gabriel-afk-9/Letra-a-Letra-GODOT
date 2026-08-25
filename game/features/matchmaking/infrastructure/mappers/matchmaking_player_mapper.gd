extends RefCounted

class_name MatchmakingPlayerMapper


static func to_domain(
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
