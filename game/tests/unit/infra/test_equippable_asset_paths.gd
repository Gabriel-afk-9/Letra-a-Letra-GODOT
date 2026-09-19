extends GutTest


func test_parse_valid_paths() -> void:
	var avatar := EquippableAssetPaths.parse("AVATAR/ceo.webp")
	assert_true(bool(avatar["valid"]), "AVATAR válido")
	assert_eq(str(avatar["category"]), "AVATAR", "categoria preservada em maiúsculas")
	assert_eq(str(avatar["dir"]), "avatar", "diretório local em minúsculas")
	assert_eq(str(avatar["file_name"]), "ceo.webp", "nome do arquivo preservado")

	var banner := EquippableAssetPaths.parse("BANNER/green.webp")
	assert_true(bool(banner["valid"]), "BANNER válido")
	assert_eq(str(banner["dir"]), "banner", "diretório do banner")


func test_parse_rejects_malformed_or_unsafe_paths() -> void:
	var invalid := [
		"",
		"   ",
		"AVATAR",
		"AVATAR/",
		"/AVATAR/x.webp",
		"AVATAR/../x.webp",
		"../AVATAR/x.webp",
		"AVATAR\\x.webp",
		"AVATAR/x.exe",
		"AVATAR/x",
		"AVATAR/.webp",
		"A/B/C.webp",
		"UNKNOWN/x.webp",
		"AVATAR/x.png/bônus.webp",
	]
	for raw in invalid:
		assert_false(bool(EquippableAssetPaths.parse(raw)["valid"]), "inválido: '%s'" % raw)


func test_cdn_url_uses_server_path_verbatim() -> void:
	var expected := GlobalEnvironment.CDN_BASE_URL + "/AVATAR/ceo.webp"
	assert_eq(EquippableAssetPaths.cdn_url("AVATAR/ceo.webp"), expected, "CDN_BASE_URL + assetPath")
	assert_eq(EquippableAssetPaths.cdn_url("/AVATAR/ceo.webp"), expected, "sem barra duplicada")
	assert_false(EquippableAssetPaths.cdn_url("AVATAR/ceo.webp").contains("AVATAR_ceo"), "sem convenção com underscore")


func test_local_paths_follow_items_structure() -> void:
	assert_eq(
		EquippableAssetPaths.res_path("AVATAR/ceo.webp"),
		"res://assets/items/equippable/avatar/ceo.webp",
		"caminho res:// do avatar"
	)
	assert_eq(
		EquippableAssetPaths.user_path("AVATAR/ceo.webp"),
		"user://assets/items/equippable/avatar/ceo.webp",
		"caminho user:// do avatar"
	)
	assert_eq(
		EquippableAssetPaths.user_path("BANNER/green.webp"),
		"user://assets/items/equippable/banner/green.webp",
		"caminho user:// do banner"
	)
	assert_eq(EquippableAssetPaths.res_path("ruim"), "", "inválido retorna vazio")
	assert_eq(
		EquippableAssetPaths.user_dir("AVATAR/ceo.webp"),
		"user://assets/items/equippable/avatar",
		"diretório de destino"
	)


func test_default_paths_per_category() -> void:
	assert_eq(
		EquippableAssetPaths.default_res_path("AVATAR"),
		"res://assets/items/equippable/avatar/default.png",
		"default do avatar"
	)
	assert_eq(
		EquippableAssetPaths.default_res_path("BANNER"),
		"res://assets/items/equippable/banner/default.jpg",
		"default do banner"
	)
	assert_eq(EquippableAssetPaths.default_res_path("BOARD"), "", "sem default fictício para BOARD")


func test_is_equippable_and_tab_of() -> void:
	var equippable := InventoryItem.from_dictionary({"itemId": "e", "kind": "EQUIPPABLE", "category": "FRAME"})
	var consumable := InventoryItem.from_dictionary({"itemId": "c", "kind": "CONSUMABLE", "category": "EMOTE"})
	assert_true(EquippableAssetPaths.is_equippable(equippable), "EQUIPPABLE detectado")
	assert_false(EquippableAssetPaths.is_equippable(consumable), "CONSUMABLE não é equipável")
	assert_false(EquippableAssetPaths.is_equippable(null), "nulo não é equipável")
	assert_eq(EquippableAssetPaths.tab_of(equippable), "FRAME", "aba da categoria")
	assert_eq(EquippableAssetPaths.tab_of(consumable), "CONSUMABLE", "não equipável vai para consumíveis")


func test_load_local_texture_missing_returns_null() -> void:
	assert_null(EquippableAssetPaths.load_local_texture("AVATAR/inexistente.webp"), "sem arquivo retorna nulo")
	assert_null(EquippableAssetPaths.load_local_texture("caminho-invalido"), "caminho inválido retorna nulo")
