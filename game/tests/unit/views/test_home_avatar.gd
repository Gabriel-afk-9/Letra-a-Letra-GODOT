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
	var err := image.save_png(user_p)
	assert_eq(err, OK, "save_png deve ter sucesso")
	assert_true(FileAccess.file_exists(user_p), "arquivo deve existir após save_png")
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


func _card_avatar() -> TextureRect:
	var card: PlayerCard = _page.home_player_card as PlayerCard
	if card == null:
		return null
	return card.avatar as TextureRect

func test_home_shows_equipped_avatar_instead_of_mock() -> void:
	_stage_asset()
	await get_tree().process_frame  # Ensure file system visibility
	var store := ServiceRegistry.initial_data_store()
	store.set_inventory([InventoryItem.from_dictionary(_avatar_dict("av-1", true))])
	_page.enter({})
	await get_tree().process_frame

	var tex_rect: TextureRect = _card_avatar()
	assert_not_null(tex_rect, "PlayerCard avatar existe")
	var texture: Texture2D = tex_rect.texture as Texture2D
	assert_not_null(texture, "avatar exibido")
	assert_ne(texture, HomeScreen.AVATAR_COSMETICS["logo"], "usa o asset real, não o mock")
	assert_eq(texture.get_size(), Vector2(4, 4), "dimensões do asset local")
	assert_true(tex_rect.material is ShaderMaterial, "máscara de cantos aplicada")


func test_home_without_equipped_shows_mock() -> void:
	var store := ServiceRegistry.initial_data_store()
	store.set_inventory([InventoryItem.from_dictionary(_avatar_dict("av-1", false))])
	_page.enter({})
	await get_tree().process_frame

	var tex_rect: TextureRect = _card_avatar()
	assert_not_null(tex_rect, "avatar rect deve existir")
	assert_eq(tex_rect.texture, HomeScreen.AVATAR_COSMETICS["logo"], "sem equipado exibe o mock")


func test_home_avatar_texture_fills_frame() -> void:
	var tex_rect: TextureRect = _card_avatar()
	assert_not_null(tex_rect, "avatar rect deve existir")
	assert_eq(tex_rect.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_COVERED, "avatar preenche o quadrado sem deformar")
