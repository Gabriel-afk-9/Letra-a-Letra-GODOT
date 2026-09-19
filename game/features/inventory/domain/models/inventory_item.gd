extends RefCounted
class_name InventoryItem

# Item do inventário do jogador (GET /user/items, schema UserItemResponse em docs/api.json).
var item_id: String
var name: String
var kind: String
var category: String
var context: String
var quantity: int
var equipped: bool
var acquired_at: String
var expires_at: String
var asset_path: String


func _init(
	p_item_id: String = "",
	p_name: String = "",
	p_kind: String = "",
	p_category: String = "",
	p_context: String = "",
	p_quantity: int = 0,
	p_equipped: bool = false,
	p_acquired_at: String = "",
	p_expires_at: String = "",
	p_asset_path: String = ""
) -> void:
	item_id = p_item_id
	name = p_name
	kind = p_kind
	category = p_category
	context = p_context
	quantity = p_quantity
	equipped = p_equipped
	acquired_at = p_acquired_at
	expires_at = p_expires_at
	asset_path = p_asset_path


static func from_dictionary(data: Dictionary) -> InventoryItem:
	if data.is_empty():
		return null
	return InventoryItem.new(
		str(data.get("itemId", "")),
		str(data.get("name", "")),
		str(data.get("kind", "")),
		str(data.get("category", "")),
		str(data.get("context", "")),
		int(data.get("quantity", 0)),
		bool(data.get("equipped", false)),
		str(data.get("acquiredAt", "")),
		str(data.get("expiresAt", "")),
		str(data.get("assetPath", ""))
	)
