extends GutTest


func _cosmetics() -> Array:
	return [
		{"itemId": "1", "name": "Banner", "category": "BANNER", "equipped": true, "assetPath": "BANNER/green.webp"},
		{"itemId": "2", "name": "Ceo", "category": "AVATAR", "equipped": true, "assetPath": "AVATAR/ceo.webp"},
		{"itemId": "3", "name": "Outro", "category": "AVATAR", "equipped": false, "assetPath": "AVATAR/outro.webp"},
	]


func test_avatar_asset_path_picks_equipped_avatar() -> void:
	assert_eq(EquippedAvatar.avatar_asset_path(_cosmetics()), "AVATAR/ceo.webp")


func test_avatar_asset_path_ignores_other_categories() -> void:
	var only_banner := [{"name": "B", "category": "BANNER", "equipped": true, "assetPath": "BANNER/green.webp"}]
	assert_eq(EquippedAvatar.avatar_asset_path(only_banner), "")


func test_avatar_asset_path_handles_empty_and_invalid() -> void:
	assert_eq(EquippedAvatar.avatar_asset_path([]), "")
	assert_eq(EquippedAvatar.avatar_asset_path([{"category": "AVATAR", "equipped": true}]), "")
	assert_eq(EquippedAvatar.avatar_asset_path([{"category": "AVATAR", "equipped": true, "assetPath": "RUIM"}]), "")


func test_avatar_asset_path_supports_inventory_item() -> void:
	var item := InventoryItem.from_dictionary({
		"itemId": "a-1", "name": "A", "kind": "EQUIPPABLE",
		"category": "AVATAR", "equipped": true, "assetPath": "AVATAR/ceo.webp",
	})
	assert_eq(EquippedAvatar.avatar_asset_path([item]), "AVATAR/ceo.webp")


func test_avatar_asset_path_supports_legacy_type_key() -> void:
	var legacy := [{"name": "Y", "type": "AVATAR", "equipped": true, "assetPath": "AVATAR/evil.png"}]
	assert_eq(EquippedAvatar.avatar_asset_path(legacy), "AVATAR/evil.png")


func test_fallback_texture_exists() -> void:
	assert_not_null(EquippedAvatar.fallback_texture())


func test_texture_for_missing_returns_fallback() -> void:
	var fallback := EquippedAvatar.fallback_texture()
	assert_not_null(fallback)
	assert_eq(EquippedAvatar.texture_for(null, "AVATAR/inexistente.webp").get_path(), fallback.get_path())
	assert_eq(EquippedAvatar.texture_for(null, "").get_path(), fallback.get_path())


func test_cdn_url_reused_not_duplicated() -> void:
	var expected := GlobalEnvironment.CDN_BASE_URL + "/AVATAR/ceo.webp"
	assert_eq(EquippableAssetPaths.cdn_url("AVATAR/ceo.webp"), expected)
