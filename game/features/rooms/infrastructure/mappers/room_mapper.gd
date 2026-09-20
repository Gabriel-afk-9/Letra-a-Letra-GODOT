extends RefCounted
class_name RoomMapper


static func from_dictionary(data: Dictionary) -> Room:
	if data.is_empty():
		return null
	var participants_variant = data.get("participants", [])
	var participants: Array = []
	if participants_variant is Array:
		for item_variant in participants_variant:
			if item_variant is Dictionary:
				participants.append(item_variant)
	var positions_variant = data.get("positions", {})
	var positions: Dictionary = positions_variant if positions_variant is Dictionary else {}
	var matches_variant = data.get("matches", [])
	var matches: Array = matches_variant if matches_variant is Array else []
	return Room.new(
		str(data.get("gameId", "")),
		str(data.get("gameName", "")),
		str(data.get("type", "")),
		str(data.get("status", "")),
		participants,
		positions,
		matches
	)


static func list_from_array(items: Array) -> Array:
	var result: Array = []
	for item_variant in items:
		if not item_variant is Dictionary:
			continue
		var room := from_dictionary(item_variant)
		if room != null:
			result.append(room)
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
		"rooms": list_from_array(content),
		"page": int(data.get("page", 0)),
		"total_pages": int(data.get("totalPages", 1)),
		"total_elements": int(data.get("totalElements", 0)),
	}


static func code_from_body(body: Dictionary) -> Dictionary:
	var data_variant = body.get("data", {})
	if not data_variant is Dictionary:
		return {}
	var game_id := str((data_variant as Dictionary).get("gameId", ""))
	if game_id.is_empty():
		return {}
	return {"game_id": game_id}
