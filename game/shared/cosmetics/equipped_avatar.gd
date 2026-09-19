extends RefCounted
class_name EquippedAvatar

const CATEGORY_AVATAR := "AVATAR"
const KIND_EQUIPPABLE := "EQUIPPABLE"


static func avatar_asset_path(cosmetics: Array) -> String:
	for item_variant in cosmetics:
		if item_variant is InventoryItem:
			var candidate_path := _path_from_inventory_item(item_variant as InventoryItem)
			if not candidate_path.is_empty():
				return candidate_path
			continue
		if not item_variant is Dictionary:
			continue
		var candidate := _path_from_dictionary(item_variant as Dictionary)
		if not candidate.is_empty():
			return candidate
	return ""


static func to_inventory_item(asset_path: String) -> InventoryItem:
	var clean := asset_path.strip_edges()
	return InventoryItem.new(clean, "", KIND_EQUIPPABLE, CATEGORY_AVATAR, "", 1, true, "", "", clean)


static func fallback_texture() -> Texture2D:
	var path := EquippableAssetPaths.default_res_path(CATEGORY_AVATAR)
	if path.is_empty():
		return null
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


static func texture_for(service: EquippableAssetService, asset_path: String) -> Texture2D:
	var clean := asset_path.strip_edges()
	if clean.is_empty():
		return fallback_texture()
	if service != null:
		var cached := service.texture_for(to_inventory_item(clean))
		if cached != null:
			return cached
	var local := EquippableAssetPaths.load_local_texture(clean)
	if local != null:
		return local
	return fallback_texture()


static func ensure_downloaded(service: EquippableAssetService, asset_path: String) -> void:
	if service == null:
		return
	var clean := asset_path.strip_edges()
	if clean.is_empty():
		return
	var item := to_inventory_item(clean)
	if service.needs_download(item) and not service.is_downloading(item):
		service.download(item)


static func _path_from_inventory_item(item: InventoryItem) -> String:
	if item == null:
		return ""
	if item.category.strip_edges().to_upper() != CATEGORY_AVATAR:
		return ""
	if not item.equipped:
		return ""
	return _valid_path(item.asset_path)


static func _path_from_dictionary(item: Dictionary) -> String:
	var category := str(item.get("category", item.get("type", ""))).strip_edges().to_upper()
	if category != CATEGORY_AVATAR:
		return ""
	if item.has("equipped") and not bool(item.get("equipped")):
		return ""
	return _valid_path(str(item.get("assetPath", item.get("asset_path", ""))))


static func _valid_path(raw: String) -> String:
	var clean := raw.strip_edges()
	if clean.is_empty():
		return ""
	if not bool(EquippableAssetPaths.parse(clean).get("valid", false)):
		return ""
	return clean
