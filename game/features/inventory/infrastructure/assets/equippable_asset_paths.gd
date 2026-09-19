extends RefCounted
class_name EquippableAssetPaths

# Conversão entre o assetPath enviado pelo servidor (ex.: "AVATAR/ceo.webp"),
# a URL remota na CDN e o caminho de armazenamento local do jogo.
# O assetPath do servidor é a fonte oficial do asset remoto e deve ser
# usado diretamente na montagem da URL. Apenas o caminho local deriva
# dele, seguindo a estrutura assets/items/equippable/<categoria>/<arquivo>.
const KIND_EQUIPPABLE := "EQUIPPABLE"

const SUPPORTED_CATEGORIES: Array = ["AVATAR", "BANNER", "FRAME", "EMOTE", "BOARD", "CELL"]

const IMAGE_EXTENSIONS: Array = ["png", "jpg", "jpeg", "webp"]

const LOCAL_BASE_RES := "res://assets/items/equippable"
const LOCAL_BASE_USER := "user://assets/items/equippable"

const DEFAULT_FILE_BY_CATEGORY := {
	"AVATAR": "avatar/default.png",
	"BANNER": "banner/default.jpg",
}

const DEFAULT_CANDIDATES: Array = ["default.png", "default.jpg", "default.jpeg", "default.webp"]


static func is_equippable(item: InventoryItem) -> bool:
	if item == null:
		return false
	return item.kind.strip_edges().to_upper() == KIND_EQUIPPABLE


static func tab_of(item: InventoryItem) -> String:
	if item == null:
		return ""
	if not is_equippable(item):
		return "CONSUMABLE"
	var category := item.category.strip_edges().to_upper()
	if category.is_empty():
		return "OUTROS"
	return category


# Valida o formato esperado "<CATEGORIA>/<ARQUIVO>.webp" e rejeita
# qualquer valor que possa escapar do diretório de destino.
static func parse(asset_path: String) -> Dictionary:
	var invalid := {"valid": false, "category": "", "dir": "", "file_name": ""}
	var clean := asset_path.strip_edges()
	if clean.is_empty():
		return invalid
	if clean.contains("\\"):
		return invalid
	if clean.begins_with("/"):
		return invalid
	if clean.contains(".."):
		return invalid
	var parts := clean.split("/")
	if parts.size() != 2:
		return invalid
	var category := parts[0].strip_edges().to_upper()
	var file_name := parts[1].strip_edges()
	if category.is_empty() or file_name.is_empty():
		return invalid
	if not SUPPORTED_CATEGORIES.has(category):
		return invalid
	if file_name.begins_with("."):
		return invalid
	var ext := file_name.get_extension().to_lower()
	if not IMAGE_EXTENSIONS.has(ext):
		return invalid
	if file_name.get_basename().strip_edges().is_empty():
		return invalid
	return {"valid": true, "category": category, "dir": category.to_lower(), "file_name": file_name}


static func cdn_url(asset_path: String) -> String:
	var base := GlobalEnvironment.CDN_BASE_URL
	while base.ends_with("/"):
		base = base.substr(0, base.length() - 1)
	var clean := asset_path.strip_edges()
	while clean.begins_with("/"):
		clean = clean.substr(1)
	return base + "/" + clean


static func res_path(asset_path: String) -> String:
	var parsed := parse(asset_path)
	if not bool(parsed["valid"]):
		return ""
	return "%s/%s/%s" % [LOCAL_BASE_RES, str(parsed["dir"]), str(parsed["file_name"])]


static func user_path(asset_path: String) -> String:
	var parsed := parse(asset_path)
	if not bool(parsed["valid"]):
		return ""
	return "%s/%s/%s" % [LOCAL_BASE_USER, str(parsed["dir"]), str(parsed["file_name"])]


static func user_dir(asset_path: String) -> String:
	var parsed := parse(asset_path)
	if not bool(parsed["valid"]):
		return ""
	return "%s/%s" % [LOCAL_BASE_USER, str(parsed["dir"])]


# Fallback da categoria. AVATAR e BANNER possuem defaults conhecidos;
# demais categorias usam default.* caso exista, ou vazio quando não há.
static func default_res_path(category: String) -> String:
	var upper := category.strip_edges().to_upper()
	if DEFAULT_FILE_BY_CATEGORY.has(upper):
		return "%s/%s" % [LOCAL_BASE_RES, str(DEFAULT_FILE_BY_CATEGORY[upper])]
	if upper.is_empty():
		return ""
	var dir := upper.to_lower()
	for candidate in DEFAULT_CANDIDATES:
		var path := "%s/%s/%s" % [LOCAL_BASE_RES, dir, str(candidate)]
		if ResourceLoader.exists(path):
			return path
	return ""
