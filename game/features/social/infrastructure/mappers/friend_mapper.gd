extends RefCounted
class_name FriendMapper


static func from_dictionary(data: Dictionary) -> Friendship:
	if data.is_empty():
		return null
	var profile_variant = data.get("profile", {})
	var profile: Dictionary = profile_variant if profile_variant is Dictionary else {}
	var equipped_variant = profile.get("equipped", [])
	var equipped: Array = []
	if equipped_variant is Array:
		for item_variant in equipped_variant:
			if item_variant is Dictionary:
				equipped.append(item_variant)
	return Friendship.new(
		str(data.get("userId1", "")),
		str(data.get("userId2", "")),
		str(data.get("status", Friendship.STATUS_PENDING)),
		str(data.get("requestDate", "")),
		str(data.get("friendId", "")),
		str(data.get("direction", "")),
		str(profile.get("nickname", "")),
		equipped
	)


static func list_from_array(items: Array) -> Array:
	var result: Array = []
	for item_variant in items:
		if not item_variant is Dictionary:
			continue
		var friendship := from_dictionary(item_variant)
		if friendship != null:
			result.append(friendship)
	return result


static func page_from_body(body: Dictionary) -> Dictionary:
	var data_variant = body.get("data", {})
	if not data_variant is Dictionary:
		return {}
	var data: Dictionary = data_variant
	if data.is_empty():
		return {}
	var content_variant = data.get("content", [])
	var content: Array = content_variant if content_variant is Array else []
	return {
		"friends": list_from_array(content),
		"page": int(data.get("page", 0)),
		"total_pages": int(data.get("totalPages", 1)),
		"total_elements": int(data.get("totalElements", 0)),
	}


static func pending_from_body(body: Dictionary) -> Array:
	var data_variant = body.get("data", {})
	if not data_variant is Dictionary:
		return []
	var data: Dictionary = data_variant
	var requests_variant = data.get("requests", [])
	if not requests_variant is Array:
		return []
	return list_from_array(requests_variant)
