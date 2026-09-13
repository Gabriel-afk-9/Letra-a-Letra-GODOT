extends RefCounted
class_name UserMapper

static func from_response_body(body: Dictionary) -> User:
	var data: Dictionary = body.get("data", {}) as Dictionary
	var user_variant = data.get("user", {})

	if not user_variant is Dictionary:
		return null

	return from_dictionary(user_variant)


static func users_page_from_body(body: Dictionary) -> Dictionary:
	var data_variant = body.get("data", {})
	if not data_variant is Dictionary:
		return {}
	var data: Dictionary = data_variant
	if data.is_empty():
		return {}
	var content_variant = data.get("content", [])
	var content: Array = content_variant if content_variant is Array else []
	var users: Array = []
	for item_variant in content:
		if not item_variant is Dictionary:
			continue
		var user := from_dictionary(item_variant)
		if user != null and not user.id.is_empty():
			users.append(user)
	return {
		"users": users,
		"page": int(data.get("page", 0)),
		"total_pages": int(data.get("totalPages", 1)),
		"total_elements": int(data.get("totalElements", 0)),
	}


static func from_dictionary(user_data: Dictionary) -> User:
	if user_data.is_empty():
		return null

	var stats_variant = user_data.get("stats", {})
	var stats: Dictionary = stats_variant if stats_variant is Dictionary else {}

	var wallet_variant = user_data.get("wallet", {})
	var wallet: Dictionary = wallet_variant if wallet_variant is Dictionary else {}

	var equipped_variant = user_data.get("equipped", [])
	var equipped: Array = equipped_variant if equipped_variant is Array else []

	var has_banner := _has_equipped_banner(equipped)
	var equipped_avatar := _get_equipped_cosmetic_name(equipped, "AVATAR")
	var equipped_frame := _get_equipped_cosmetic_name(equipped, "FRAME")
	var equipped_banner := _get_equipped_cosmetic_name(equipped, "BANNER")

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
		int(stats.get("totalMatches", 0)),
		int(stats.get("rankingPoints", 0)),
		has_banner,
		equipped_avatar,
		equipped_frame,
		equipped_banner
	)


static func _has_equipped_banner(equipped: Array) -> bool:
	for item_variant in equipped:
		if not item_variant is Dictionary:
			continue
		var item: Dictionary = item_variant
		if str(item.get("type", "")) == "BANNER" and bool(item.get("equipped", false)):
			return true
	return false


static func _get_equipped_cosmetic_name(equipped: Array, cosmetic_type: String) -> String:
	for item_variant in equipped:
		if not item_variant is Dictionary:
			continue
		var item: Dictionary = item_variant
		if str(item.get("type", "")) == cosmetic_type and bool(item.get("equipped", false)):
			return str(item.get("name", ""))
	return ""
