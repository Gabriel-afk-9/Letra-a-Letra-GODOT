extends RefCounted
class_name CosmeticArt

const LOCAL_BASE := "res://assets/cosmetics"
const FALLBACK_AVATAR := preload("res://assets/cosmetics/avatar/logo.png")

const AVATAR_BY_NAME := {
	"logo": preload("res://assets/cosmetics/avatar/logo.png"),
	"stupid": preload("res://assets/cosmetics/avatar/stupid.png"),
	"pie": preload("res://assets/cosmetics/avatar/pie.png"),
	"evil": preload("res://assets/cosmetics/avatar/evil.png"),
	"arvenis": preload("res://assets/cosmetics/avatar/arvenis.png"),
}

const IMAGE_EXTENSIONS := ["png", "webp", "jpg", "jpeg"]


static func avatar_for(asset_path: String) -> Texture2D:
	return _texture_for_type(asset_path, "avatar")


static func banner_for(asset_path: String) -> Texture2D:
	return _texture_for_type(asset_path, "banner")


static func frame_for(asset_path: String) -> Texture2D:
	return _texture_for_type(asset_path, "frame")


static func equipped_art(equipped: Array, cosmetic_type: String) -> Texture2D:
	var want := cosmetic_type.to_upper()
	for item_variant in equipped:
		if not item_variant is Dictionary:
			continue
		var item: Dictionary = item_variant
		if str(item.get("type", "")).to_upper() != want:
			continue
		if not bool(item.get("equipped", true)):
			continue
		var texture := _texture_for_type(str(item.get("assetPath", "")), want.to_lower())
		if texture != null:
			return texture
	return null


static func avatar_by_name(cosmetic_name: String) -> Texture2D:
	var key := cosmetic_name.strip_edges().to_lower()
	if AVATAR_BY_NAME.has(key):
		return AVATAR_BY_NAME[key]
	return FALLBACK_AVATAR


static func _texture_for_type(asset_path: String, fallback_dir: String) -> Texture2D:
	var clean := asset_path.strip_edges()
	if clean.is_empty():
		return null
	var dir := fallback_dir
	var file := clean
	if clean.contains("/"):
		var parts := clean.split("/")
		dir = parts[0].strip_edges().to_lower()
		file = parts[parts.size() - 1]
		if dir.is_empty():
			dir = fallback_dir
		if file.is_empty():
			return null
	var stem := file.get_basename().to_lower()
	if stem.is_empty():
		stem = file.to_lower()
	var candidates: Array = []
	var original_ext := file.get_extension().to_lower()
	if not original_ext.is_empty():
		candidates.append(original_ext)
	for ext in IMAGE_EXTENSIONS:
		if not candidates.has(ext):
			candidates.append(ext)
	for ext_variant in candidates:
		var path := "%s/%s/%s.%s" % [LOCAL_BASE, dir, stem, ext_variant]
		if ResourceLoader.exists(path):
			return load(path) as Texture2D
	return null
