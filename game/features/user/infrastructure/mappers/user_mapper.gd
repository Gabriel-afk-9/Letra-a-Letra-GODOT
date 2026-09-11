extends RefCounted
class_name UserMapper

static func from_response_body(body: Dictionary) -> User:
	var data: Dictionary = body.get("data", {}) as Dictionary
	var user_variant = data.get("user", {})

	if not user_variant is Dictionary:
		return null

	var user_data: Dictionary = user_variant

	if user_data.is_empty():
		return null

	var stats_variant = user_data.get("stats", {})
	var stats: Dictionary = stats_variant if stats_variant is Dictionary else {}

	var wallet_variant = user_data.get("wallet", {})
	var wallet: Dictionary = wallet_variant if wallet_variant is Dictionary else {}

	return User.new(
		str(user_data.get("userId", user_data.get("id", ""))),
		str(user_data.get("email", "")),
		str(user_data.get("nickname", "")),
		int(stats.get("level", 0)),
		int(stats.get("experience", 0)),
		int(wallet.get("coins", 0)),
		int(wallet.get("gems", 0)),
		int(stats.get("totalWins", 0)),
		int(stats.get("winStreak", 0)),
		int(stats.get("totalMatches", 0))
	)
