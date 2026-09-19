extends GutTest

var _page: InventoryScreen
var _repo: FakeInventoryRepository
var _vm: InventoryViewModel
var _staged_user_files: Array = []


func before_each() -> void:
	var scene: PackedScene = load("res://features/inventory/presentation/views/inventory_screen.tscn")
	_page = scene.instantiate()
	add_child(_page)
	await get_tree().process_frame


func after_each() -> void:
	for path in _staged_user_files:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
	_staged_user_files.clear()
	_page.queue_free()


func _item(data: Dictionary) -> InventoryItem:
	return InventoryItem.from_dictionary(data)


func _avatar_dict(item_id: String, asset_path: String, equipped: bool = false) -> Dictionary:
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
		"assetPath": asset_path,
	}


func _banner_dict(item_id: String) -> Dictionary:
	return {
		"itemId": item_id,
		"name": "Banner %s" % item_id,
		"kind": "EQUIPPABLE",
		"category": "BANNER",
		"context": "PROFILE",
		"quantity": 1,
		"equipped": false,
		"acquiredAt": "2026-01-01T00:00:00Z",
		"expiresAt": "",
		"assetPath": "BANNER/green.webp",
	}


func _consumable_dict(item_id: String) -> Dictionary:
	return {
		"itemId": item_id,
		"name": "Gelo",
		"kind": "CONSUMABLE",
		"category": "EMOTE",
		"context": "MATCH",
		"quantity": 3,
		"equipped": false,
		"acquiredAt": "2026-01-02T00:00:00Z",
		"expiresAt": "",
		"assetPath": "",
	}


func _bind_items(items: Array) -> void:
	_repo = FakeInventoryRepository.new()
	_repo.inventory_result = {"items": items, "status_code": 200}
	var usecase := InventoryUseCase.new(_repo)
	var assets := EquippableAssetService.new()
	_vm = InventoryViewModel.new(usecase, assets, null)
	_page.bind_view_model(_vm)
	await _page._view_model.load_initial()
	await get_tree().process_frame


func _grid() -> GridContainer:
	return _page.get_node("Content/MainVBox/Panel/PanelMargin/PanelVBox/ItemGrid") as GridContainer


func _tabs_row() -> HBoxContainer:
	return _page.get_node("Content/MainVBox/TabScroll/TabsRow") as HBoxContainer


func _download_button(card: Button) -> Button:
	return card.get_node_or_null("DownloadBtn") as Button


func _stage_user_asset(asset_path: String) -> void:
	var user_p := EquippableAssetPaths.user_path(asset_path)
	var dir := EquippableAssetPaths.user_dir(asset_path)
	DirAccess.make_dir_recursive_absolute(dir)
	var image := Image.create_empty(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.RED)
	image.save_png_to_file(user_p)
	_staged_user_files.append(user_p)


func test_inventory_page_id_and_layout() -> void:
	assert_eq(_page.page_id(), &"inventory", "page_id deve ser inventory")
	assert_not_null(_page.get_node("Content/MainVBox/TabScroll/TabsRow"), "linha de abas deve existir")
	assert_not_null(_page.get_node("Content/MainVBox/Panel/PanelMargin/PanelVBox/StatusLabel"), "rótulo de status deve existir")
	assert_eq(_grid().columns, 3, "grade deve ter 3 colunas")
	assert_eq(String((_page.get_node("Content/MainVBox/Panel/PanelMargin/PanelVBox/PagerRow/PagePill/PageMargin/PageLabel") as Label).text), "Pág 1", "deve iniciar na página 1")


func test_inventory_loads_real_items_and_builds_tabs() -> void:
	var items := [
		_item(_avatar_dict("av-1", "AVATAR/ceo.webp", true)),
		_item(_banner_dict("bn-1")),
		_item(_consumable_dict("co-1")),
	]
	await _bind_items(items)

	assert_eq(_page._tabs, ["AVATAR", "BANNER", "FRAME", "EMOTE", "BOARD", "CELL", "CONSUMABLE"], "todas as seções sempre visíveis")
	assert_eq(_page._tab, "AVATAR", "primeira aba selecionada por padrão")
	assert_eq(_tabs_row().get_child_count(), 7, "sete botões de aba")
	assert_eq(_grid().get_child_count(), 1, "aba AVATAR exibe 1 item")
	_page._on_tab_pressed("CONSUMABLE")
	await get_tree().process_frame
	assert_eq(_grid().get_child_count(), 1, "aba CONSUMÍVEIS exibe 1 item")
	_page._on_tab_pressed("BANNER")
	await get_tree().process_frame
	assert_eq(_grid().get_child_count(), 1, "aba BANNER exibe 1 item")


func test_inventory_empty_sections_stay_visible() -> void:
	await _bind_items([])

	assert_eq(_tabs_row().get_child_count(), 7, "seções visíveis mesmo sem itens")
	assert_eq(_grid().get_child_count(), 0, "grade vazia")
	assert_eq((_page.get_node("Content/MainVBox/Panel/PanelMargin/PanelVBox/StatusLabel") as Label).text, "Nenhum item por aqui ainda.", "status de inventário vazio")
	await _bind_items([_item(_avatar_dict("av-1", "AVATAR/ceo.webp"))])
	_page._on_tab_pressed("FRAME")
	await get_tree().process_frame
	assert_eq(_grid().get_child_count(), 0, "seção vazia sem cards")
	assert_eq((_page.get_node("Content/MainVBox/Panel/PanelMargin/PanelVBox/StatusLabel") as Label).text, "Nada nesta aba.", "status de seção vazia")


func test_inventory_cards_keep_constant_size() -> void:
	await _bind_items([_item(_avatar_dict("av-1", "AVATAR/ceo.webp"))])

	assert_eq(_grid().get_child_count(), 1, "um único item")
	var card := _grid().get_child(0) as Button
	assert_eq(card.custom_minimum_size, Vector2(96, 122), "tamanho mínimo constante")
	assert_eq(card.size_flags_vertical, Control.SIZE_FILL, "card não estica na vertical")


func test_inventory_missing_asset_shows_download_button() -> void:
	await _bind_items([_item(_avatar_dict("av-1", "AVATAR/ceo.webp"))])

	var card := _grid().get_child(0) as Button
	assert_not_null(_download_button(card), "asset ausente deve exibir botão de download")
	assert_eq(_download_button(card).text, "↓", "botão de download com seta")


func test_inventory_existing_local_asset_hides_download_button() -> void:
	_stage_user_asset("AVATAR/tela_teste.png")
	await _bind_items([_item(_avatar_dict("av-1", "AVATAR/tela_teste.png"))])

	var card := _grid().get_child(0) as Button
	assert_null(_download_button(card), "asset local não deve exibir botão de download")
	assert_false(_page._view_model.needs_download(_page._view_model.items()[0]), "sem novo download quando o arquivo existe")


func test_inventory_consumable_has_no_download_button() -> void:
	await _bind_items([_item(_consumable_dict("co-1"))])
	_page._on_tab_pressed("CONSUMABLE")
	await get_tree().process_frame

	var card := _grid().get_child(0) as Button
	assert_null(_download_button(card), "consumível nunca exibe botão de download")
	var badge_found := false
	for label in card.find_children("*", "Label", true, false):
		if (label as Label).text == "x3":
			badge_found = true
	assert_true(badge_found, "consumível exibe a quantidade x3")


func test_inventory_paginates_client_side() -> void:
	var items: Array = []
	for i in range(13):
		items.append(_item(_avatar_dict("av-%d" % i, "AVATAR/item%d.webp" % i)))
	await _bind_items(items)

	assert_eq(_grid().get_child_count(), 12, "primeira página exibe 12 itens")
	_page._on_next_pressed()
	await get_tree().process_frame
	assert_eq(_page._page, 1, "deve avançar para a página 2")
	assert_eq(_grid().get_child_count(), 1, "segunda página exibe o restante")
	_page._on_prev_pressed()
	assert_eq(_page._page, 0, "deve voltar para a página 1")


func test_inventory_select_marks_item() -> void:
	await _bind_items([_item(_avatar_dict("av-6", "AVATAR/ceo.webp"))])
	_page._on_item_pressed("av-6")
	assert_eq(String(_page._selected["AVATAR"]), "av-6", "seleção deve marcar o item")


func test_inventory_error_shows_status() -> void:
	_repo = FakeInventoryRepository.new()
	_repo.inventory_result = {"error": "Falha de conexão. Tente novamente.", "status_code": 0}
	var usecase := InventoryUseCase.new(_repo)
	_vm = InventoryViewModel.new(usecase, EquippableAssetService.new(), null)
	_page.bind_view_model(_vm)
	await _page._view_model.load_initial()
	await get_tree().process_frame

	assert_true(_page._view_model.load_failed(), "falha com lista vazia")
	assert_eq((_page.get_node("Content/MainVBox/Panel/PanelMargin/PanelVBox/StatusLabel") as Label).text, "Falha de conexão. Tente novamente.", "status exibe o erro")


func test_inventory_script_has_no_hash_comments() -> void:
	var text := FileAccess.get_file_as_string("res://features/inventory/presentation/views/inventory_screen.gd")
	for line in text.split("\n"):
		assert_false((line as String).strip_edges().begins_with("#"), "script não deve conter comentários #")
