extends GutTest


func test_avatar_for_known_asset_path() -> void:
	var texture := CosmeticArt.avatar_for("AVATAR/logo.png")

	assert_not_null(texture)


func test_avatar_for_unknown_asset_returns_null() -> void:
	assert_null(CosmeticArt.avatar_for("AVATAR/nao_existe.png"))
	assert_null(CosmeticArt.avatar_for(""))
	assert_null(CosmeticArt.avatar_for("   "))


func test_frame_for_known_asset_path() -> void:
	var texture := CosmeticArt.frame_for("FRAME/test.png")

	assert_not_null(texture)


func test_banner_without_local_asset_returns_null() -> void:
	assert_null(CosmeticArt.banner_for("BANNER/qualquer.png"))


func test_texture_lookup_ignores_case_and_extension() -> void:
	assert_not_null(CosmeticArt.avatar_for("avatar/LOGO.PNG"))
	assert_not_null(CosmeticArt.avatar_for("AVATAR/stupid.webp"))


func test_equipped_art_picks_equipped_item_of_type() -> void:
	var equipped := [
		{"name": "X", "type": "BANNER", "equipped": true, "assetPath": "BANNER/x.png"},
		{"name": "Y", "type": "AVATAR", "equipped": true, "assetPath": "AVATAR/evil.png"},
		{"name": "Z", "type": "AVATAR", "equipped": false, "assetPath": "AVATAR/logo.png"},
	]

	var avatar := CosmeticArt.equipped_art(equipped, "AVATAR")

	assert_not_null(avatar)
	assert_null(CosmeticArt.equipped_art(equipped, "BANNER"))
	assert_null(CosmeticArt.equipped_art([], "AVATAR"))
	assert_null(CosmeticArt.equipped_art([{"name": "W"}], "AVATAR"))


func test_avatar_by_name_matches_home_catalog_with_fallback() -> void:
	assert_not_null(CosmeticArt.avatar_by_name("stupid"))
	assert_not_null(CosmeticArt.avatar_by_name("  LOGO  "))
	assert_eq(CosmeticArt.avatar_by_name("desconhecido"), CosmeticArt.FALLBACK_AVATAR)
	assert_eq(CosmeticArt.avatar_by_name(""), CosmeticArt.FALLBACK_AVATAR)
