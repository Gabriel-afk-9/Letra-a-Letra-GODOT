extends RefCounted
class_name InventoryMapper


static func items_from_body(body: Dictionary) -> Array:
	var data_variant = body.get("data", {})
	if not data_variant is Dictionary:
		return []
	var data: Dictionary = data_variant
	var items_variant = data.get("items", [])
	if not items_variant is Array:
		return []
	var items: Array = []
	for item_variant in items_variant:
		if not item_variant is Dictionary:
			continue
		var item := InventoryItem.from_dictionary(item_variant)
		if item != null and not item.item_id.is_empty():
			items.append(item)
	return items
