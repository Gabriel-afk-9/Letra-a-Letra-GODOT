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

	var cosmetics_variant = data.get("cosmeticsEquipped", [])
	var cosmetics: Array = cosmetics_variant if cosmetics_variant is Array else []
	var avatar_path := EquippedAvatar.avatar_asset_path(cosmetics)

	if avatar_path.is_empty():
		avatar_path = str(data.get("avatar_asset_path", "")).strip_edges()

	var has_stats := data.has("total_wins") or data.has("wins") or data.has("totalWins") or data.has("win_streak") or data.has("streak") or data.has("winStreak") or data.has("total_matches") or data.has("matches") or data.has("totalMatches")
	var wins := int(data.get("total_wins", data.get("wins", data.get("totalWins", 0))))
	var streak := int(data.get("win_streak", data.get("streak", data.get("winStreak", 0))))
	var matches := int(data.get("total_matches", data.get("matches", data.get("totalMatches", 0))))

	return MatchmakingPlayer.new(
		player_id,
		player_nickname,
		avatar_path,
		wins,
		streak,
		matches,
		has_stats
	)
