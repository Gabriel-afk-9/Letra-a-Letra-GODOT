extends GutTest

const STAGED_ASSET := "AVATAR/home_teste.png"

var _page: HomeScreen
var _staged: Array = []


func before_each() -> void:
	var store := ServiceRegistry.initial_data_store()
	store.clear()
	store.set_user(User.new("u-1", "e@x.com", "Zezinho"))
	var scene: PackedScene = load("res://features/home/presentation/views/home_screen.tscn")
	_page = scene.instantiate()
	add_child(_page)
	await get_tree().process_frame


func after_each() -> void:
	for path in _staged:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	_staged.clear()
	ServiceRegistry.initial_data_store().clear()
	_page.queue_free()


func _stage_asset() -> void:
	var user_p := EquippableAssetPaths.user_path(STAGED_ASSET)
	DirAccess.make_dir_recursive_absolute(EquippableAssetPaths.user_dir(STAGED_ASSET))
	var image := Image.create_empty(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.BLUE)
	image.save_png_to_file(user_p)
	_staged.append(user_p)


func _avatar_dict(item_id: String, equipped: bool) -> Dictionary:
	return {
		"itemId": item_id,
		"name": "Avatar %s" % item_id,
		"kind": "EQUIPPABLE",
		"category": "AVATAR",
		"context": "PROFILE",
		"quantity": 1,
		"equipped": equipped,
		"acquiredAt": "2026-01-01T00:00:00Z",
		"expiresAt": "",
		"assetPath": STAGED_ASSET,
	}


func test_home_shows_equipped_avatar_instead_of_mock() -> void:
	_stage_asset()
	var store := ServiceRegistry.initial_data_store()
	store.set_inventory([InventoryItem.from_dictionary(_avatar_dict("av-1", true))])
	_page.enter({})
	await get_tree().process_frame

	var texture := _page.avatar_texture.texture
	assert_not_null(texture, "avatar exibido")
	assert_ne(texture, HomeScreen.AVATAR_COSMETICS["logo"], "usa o asset real, não o mock")
	assert_eq(texture.get_size(), Vector2(4, 4), "dimensões do asset local")
	assert_true(_page.avatar_texture.material is ShaderMaterial, "máscara de cantos aplicada")


func test_home_without_equipped_shows_mock() -> void:
	var store := ServiceRegistry.initial_data_store()
	store.set_inventory([InventoryItem.from_dictionary(_avatar_dict("av-1", false))])
	_page.enter({})
	await get_tree().process_frame

	assert_eq(_page.avatar_texture.texture, HomeScreen.AVATAR_COSMETICS["logo"], "sem equipado exibe o mock")


func test_home_avatar_texture_fills_frame() -> void:
	assert_eq(_page.avatar_texture.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_COVERED, "avatar preenche o quadrado sem deformar")
