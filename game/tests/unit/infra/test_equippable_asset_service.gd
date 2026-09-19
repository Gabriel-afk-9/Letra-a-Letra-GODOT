extends GutTest

const STAGED_ASSET := "AVATAR/svc_teste.png"

var _service: EquippableAssetService
var _staged_user_files: Array = []


func before_each() -> void:
	_service = EquippableAssetService.new()
	add_child(_service)
	await get_tree().process_frame


func after_each() -> void:
	for path in _staged_user_files:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	_staged_user_files.clear()
	_service.queue_free()


func _item(data: Dictionary) -> InventoryItem:
	return InventoryItem.from_dictionary(data)


func _avatar(asset_path: String) -> InventoryItem:
	return _item({
		"itemId": "av-1",
		"name": "Avatar",
		"kind": "EQUIPPABLE",
		"category": "AVATAR",
		"context": "PROFILE",
		"quantity": 1,
		"equipped": false,
		"assetPath": asset_path,
	})


func _consumable() -> InventoryItem:
	return _item({
		"itemId": "co-1",
		"name": "Gelo",
		"kind": "CONSUMABLE",
		"category": "EMOTE",
		"context": "MATCH",
		"quantity": 3,
		"equipped": false,
		"assetPath": "",
	})


func _stage_user_asset(asset_path: String) -> void:
	var user_p := EquippableAssetPaths.user_path(asset_path)
	DirAccess.make_dir_recursive_absolute(EquippableAssetPaths.user_dir(asset_path))
	var image := Image.create_empty(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.RED)
	image.save_png_to_file(user_p)
	_staged_user_files.append(user_p)


func test_consumable_never_needs_asset() -> void:
	var item := _consumable()
	assert_true(_service.is_equippable(_avatar("AVATAR/ceo.webp")), "equipável detectado")
	assert_false(_service.is_equippable(item), "consumível não é equipável")
	assert_false(_service.needs_download(item), "consumível nunca precisa de download")
	assert_null(_service.texture_for(item), "consumível não tem textura de asset")
	assert_null(_service.texture_for(null), "nulo retorna nulo")


func test_missing_asset_reports_download_needed() -> void:
	var item := _avatar("AVATAR/ceo_inexistente.webp")
	assert_false(_service.has_local("AVATAR/ceo_inexistente.webp"), "arquivo não existe")
	assert_true(_service.needs_download(item), "asset ausente precisa de download")
	assert_false(_service.is_downloading(item), "nada em download")


func test_staged_user_asset_loads_without_download() -> void:
	_stage_user_asset(STAGED_ASSET)
	var item := _avatar(STAGED_ASSET)

	assert_true(_service.has_local(STAGED_ASSET), "arquivo staged é encontrado")
	assert_false(_service.needs_download(item), "nenhum download quando o arquivo existe")
	var texture := _service.texture_for(item)
	assert_not_null(texture, "textura carregada do user://")
	assert_eq(texture.get_size(), Vector2(4, 4), "dimensões do arquivo staged")


func test_invalid_asset_path_fails_without_network() -> void:
	var item := _avatar("CAMINHO_INVALIDO")
	assert_false(_service.needs_download(item), "caminho inválido não tenta download")
	var failures: Array = []
	_service.download_failed.connect(func(item_id: String, message: String) -> void: failures.append([item_id, message]))

	_service.download(item)

	assert_eq(failures.size(), 1, "falha emitida sem rede")
	assert_eq(failures[0][0], "av-1", "item correto")
	assert_eq(failures[0][1], EquippableAssetService.ERROR_INVALID, "motivo de validação")
