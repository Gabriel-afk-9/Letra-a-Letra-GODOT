extends RefCounted

class_name MatchmakingFoundEventMapper


static func to_domain(data: Dictionary) -> MatchmakingFoundEvent:
	return MatchmakingFoundEvent.new(
		str(data.get("game_id", "")),
		MatchmakingPlayerMapper.to_domain(data.get("me", {})),
		MatchmakingPlayerMapper.to_domain(data.get("opponent", {})),
		str(data.get("current_turn_player_id", ""))
	)
