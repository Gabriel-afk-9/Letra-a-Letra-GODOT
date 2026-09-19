extends Node
class_name EquippableAssetService

# Resolve, carrega e baixa os assets dos itens equipáveis.
# Somente itens EQUIPPABLE possuem assetPath; demais itens nunca
# passam por verificação de arquivo nem exibem botão de download.
# Arquivos baixados vão para user:// (gravável em qualquer build) e
# a leitura prioriza user:// antes de cair para o res:// empacotado.
signal asset_ready(item_id: String)
signal download_failed(item_id: String, error_message: String)

const ERROR_INVALID := "Asset inválido."
const ERROR_CONNECTION := "Falha de conexão. Tente novamente."
const ERROR_NOT_FOUND := "Asset não encontrado na CDN."
const ERROR_BAD_FILE := "Arquivo recebido inválido."
const ERROR_SAVE := "Não foi possível salvar o asset."

var _downloading: Dictionary = {}
var _cache: Dictionary = {}


func is_equippable(item: InventoryItem) -> bool:
	return EquippableAssetPaths.is_equippable(item)


func has_local(asset_path: String) -> bool:
	var parsed := EquippableAssetPaths.parse(asset_path)
	if not bool(parsed["valid"]):
		return false
	var user_p := EquippableAssetPaths.user_path(asset_path)
	if not user_p.is_empty() and FileAccess.file_exists(user_p):
		return true
	var res_p := EquippableAssetPaths.res_path(asset_path)
	if res_p.is_empty():
		return false
	if ResourceLoader.exists(res_p):
		return true
	return FileAccess.file_exists(res_p)


func needs_download(item: InventoryItem) -> bool:
	if item == null:
		return false
	if not is_equippable(item):
		return false
	var parsed := EquippableAssetPaths.parse(item.asset_path)
	if not bool(parsed["valid"]):
		return false
	return not has_local(item.asset_path)


func is_downloading(item: InventoryItem) -> bool:
	if item == null:
		return false
	return _downloading.has(item.asset_path.strip_edges())


func texture_for(item: InventoryItem) -> Texture2D:
	if item == null:
		return null
	if is_equippable(item):
		var parsed := EquippableAssetPaths.parse(item.asset_path)
		if bool(parsed["valid"]):
			if has_local(item.asset_path):
				return _load_local(item.asset_path)
			return _load_default(str(parsed["category"]))
		return _load_default(item.category)
	return null


func download(item: InventoryItem) -> void:
	if item == null or not is_equippable(item):
		return
	var clean := item.asset_path.strip_edges()
	var parsed := EquippableAssetPaths.parse(clean)
	if not bool(parsed["valid"]):
		download_failed.emit(item.item_id, ERROR_INVALID)
		return
	if _downloading.has(clean):
		return
	if has_local(clean):
		asset_ready.emit(item.item_id)
		return
	_downloading[clean] = true
	var http := HTTPRequest.new()
	add_child(http)
	var start_error := http.request(EquippableAssetPaths.cdn_url(clean))
	if start_error != OK:
		http.queue_free()
		_downloading.erase(clean)
		download_failed.emit(item.item_id, ERROR_CONNECTION)
		return
	var result: Array = await http.request_completed
	var code := 0
	var body := PackedByteArray()
	if result.size() >= 4:
		code = int(result[1])
		body = result[3] as PackedByteArray
	if is_instance_valid(http):
		http.queue_free()
	if code < 200 or code >= 300:
		_downloading.erase(clean)
		if code == 404:
			download_failed.emit(item.item_id, ERROR_NOT_FOUND)
		else:
			download_failed.emit(item.item_id, ERROR_CONNECTION)
		return
	if body.is_empty():
		_downloading.erase(clean)
		download_failed.emit(item.item_id, ERROR_BAD_FILE)
		return
	var image := _image_from_buffer(clean.get_extension().to_lower(), body)
	if image == null or image.is_empty():
		_downloading.erase(clean)
		download_failed.emit(item.item_id, ERROR_BAD_FILE)
		return
	if not _save_local(clean, body):
		_downloading.erase(clean)
		download_failed.emit(item.item_id, ERROR_SAVE)
		return
	_cache["local:" + clean] = ImageTexture.create_from_image(image)
	_downloading.erase(clean)
	asset_ready.emit(item.item_id)


func _load_default(category: String) -> Texture2D:
	var path := EquippableAssetPaths.default_res_path(category)
	if path.is_empty():
		return null
	if _cache.has(path):
		return _cache[path] as Texture2D
	var texture := load(path) as Texture2D
	_cache[path] = texture
	return texture


func _load_local(asset_path: String) -> Texture2D:
	var key := "local:" + asset_path.strip_edges()
	if _cache.has(key):
		return _cache[key] as Texture2D
	var texture: Texture2D = null
	var user_p := EquippableAssetPaths.user_path(asset_path)
	if not user_p.is_empty() and FileAccess.file_exists(user_p):
		var user_image := Image.load_from_file(user_p)
		if user_image != null and not user_image.is_empty():
			texture = ImageTexture.create_from_image(user_image)
	if texture == null:
		var res_p := EquippableAssetPaths.res_path(asset_path)
		if not res_p.is_empty():
			if ResourceLoader.exists(res_p):
				texture = load(res_p) as Texture2D
			elif FileAccess.file_exists(res_p):
				var res_image := Image.load_from_file(res_p)
				if res_image != null and not res_image.is_empty():
					texture = ImageTexture.create_from_image(res_image)
	_cache[key] = texture
	return texture


func _image_from_buffer(ext: String, body: PackedByteArray) -> Image:
	var image := Image.create_empty(1, 1, false, Image.FORMAT_RGBA8)
	var err := ERR_INVALID_DATA
	match ext:
		"png":
			err = image.load_png_from_buffer(body)
		"jpg", "jpeg":
			err = image.load_jpg_from_buffer(body)
		"webp":
			err = image.load_webp_from_buffer(body)
	if err != OK:
		return null
	return image


func _save_local(asset_path: String, body: PackedByteArray) -> bool:
	var dir := EquippableAssetPaths.user_dir(asset_path)
	var path := EquippableAssetPaths.user_path(asset_path)
	if dir.is_empty() or path.is_empty():
		return false
	var mk_error := DirAccess.make_dir_recursive_absolute(dir)
	if mk_error != OK and not DirAccess.dir_exists_absolute(dir):
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_buffer(body)
	file.close()
	return true
