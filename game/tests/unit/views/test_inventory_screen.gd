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


func _sub_tabs_row() -> HBoxContainer:
	return _page.get_node("Content/MainVBox/Panel/PanelMargin/PanelVBox/SubTabsRow") as HBoxContainer


func _download_button(card: Button) -> Button:
	return card.get_node_or_null("DownloadBtn") as Button


func _equip_button(card: Button) -> Button:
	return card.get_node_or_null("EquipBtn") as Button


func _card_ring(card: Button) -> StyleBoxFlat:
	var frame := card.get_node("CardFrame") as PanelContainer
	return frame.get_theme_stylebox("panel") as StyleBoxFlat


func _stage_user_asset(asset_path: String) -> void:
	var user_p := EquippableAssetPaths.user_path(asset_path)
	var dir := EquippableAssetPaths.user_dir(asset_path)
	DirAccess.make_dir_recursive_absolute(dir)
	var image := Image.create_empty(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.RED)
	var err := image.save_png(user_p)
	assert_eq(err, OK, "save_png deve ter sucesso")
	_staged_user_files.append(user_p)


func test_inventory_page_id_and_layout() -> void:
	assert_eq(_page.page_id(), &"inventory", "page_id deve ser inventory")
	assert_not_null(_page.get_node("Content/MainVBox/TabScroll/TabsRow"), "linha de abas deve existir")
	assert_not_null(_page.get_node("Content/MainVBox/Panel/PanelMargin/PanelVBox/StatusLabel"), "rótulo de status deve existir")
	assert_eq(_grid().columns, 3, "grade deve ter 3 colunas")
	assert_eq(String((_page.get_node("Content/MainVBox/Panel/PanelMargin/PanelVBox/PagerRow/PagePill/PageMargin/PageLabel") as Label).text), "Pág 1", "deve iniciar na página 1")


func test_inventory_sections_with_cosmetic_selector() -> void:
	var items := [
		_item(_avatar_dict("av-1", "AVATAR/ceo.webp", true)),
		_item(_banner_dict("bn-1")),
		_item(_consumable_dict("co-1")),
	]
	await _bind_items(items)

	assert_eq(_page._section, "COSMETICS", "seção cosméticos por padrão")
	assert_eq(_page._category, "AVATAR", "categoria avatar por padrão")
	assert_eq(_tabs_row().get_child_count(), 2, "duas seções no topo")
	assert_not_null(_tabs_row().get_node("COSMETICSTab"), "seção cosméticos")
	assert_not_null(_tabs_row().get_node("OTHERSTab"), "seção outros")
	assert_true(_sub_tabs_row().visible, "subseletor visível em cosméticos")
	assert_eq(_sub_tabs_row().get_child_count(), 6, "seis categorias de cosméticos")
	assert_eq(_grid().get_child_count(), 1, "aba AVATAR exibe 1 item")
	_page._on_category_pressed("BANNER")
	await get_tree().process_frame
	assert_eq(_grid().get_child_count(), 1, "categoria BANNER exibe 1 item")
	_page._on_category_pressed("FRAME")
	await get_tree().process_frame
	assert_eq(_grid().get_child_count(), 0, "categoria vazia sem cards")
	assert_eq((_page.get_node("Content/MainVBox/Panel/PanelMargin/PanelVBox/StatusLabel") as Label).text, "Nada nesta seção.", "status de categoria vazia")
	_page._on_section_pressed("OTHERS")
	await get_tree().process_frame
	assert_false(_sub_tabs_row().visible, "subseletor oculto em outros")
	assert_eq(_grid().get_child_count(), 1, "seção outros exibe o consumível")


func test_inventory_empty_sections_stay_visible() -> void:
	await _bind_items([])

	assert_eq(_tabs_row().get_child_count(), 2, "seções visíveis mesmo sem itens")
	assert_eq(_sub_tabs_row().get_child_count(), 6, "categorias visíveis mesmo sem itens")
	assert_eq(_grid().get_child_count(), 0, "grade vazia")
	assert_eq((_page.get_node("Content/MainVBox/Panel/PanelMargin/PanelVBox/StatusLabel") as Label).text, "Nenhum item por aqui ainda.", "status de inventário vazio")
	await _bind_items([_item(_avatar_dict("av-1", "AVATAR/ceo.webp"))])
	_page._on_category_pressed("FRAME")
	await get_tree().process_frame
	assert_eq(_grid().get_child_count(), 0, "categoria vazia sem cards")
	assert_eq((_page.get_node("Content/MainVBox/Panel/PanelMargin/PanelVBox/StatusLabel") as Label).text, "Nada nesta seção.", "status de categoria vazia")


func test_inventory_tab_buttons_layout() -> void:
	await _bind_items([_item(_avatar_dict("av-1", "AVATAR/ceo.webp"))])

	var section_btn := _tabs_row().get_node("COSMETICSTab") as Button
	assert_true(section_btn.clip_contents, "botão de seção recorta o conteúdo")
	assert_eq(section_btn.find_children("*", "HBoxContainer", true, false).size(), 1, "seção usa linha horizontal ícone+texto")
	var section_labels := section_btn.find_children("*", "Label", true, false)
	assert_eq((section_labels[0] as Label).text, "COSMÉTICOS", "título completo da seção")
	var icons := section_btn.find_children("*", "TextureRect", true, false)
	assert_eq((icons[0] as TextureRect).custom_minimum_size, Vector2(26, 26), "ícone com tamanho fixo")
	var cat_btn := _sub_tabs_row().get_node("AVATARTab") as Button
	assert_true(cat_btn.clip_contents, "subaba recorta o conteúdo")
	var cat_labels := cat_btn.find_children("*", "Label", true, false)
	assert_eq((cat_labels[0] as Label).text, "AVATAR", "título completo da categoria")
	assert_eq((cat_labels[0] as Label).text_overrun_behavior, TextServer.OVERRUN_TRIM_ELLIPSIS, "elipse em vez de corte seco")


func test_inventory_cards_keep_constant_size() -> void:
	await _bind_items([_item(_avatar_dict("av-1", "AVATAR/ceo.webp"))])

	assert_eq(_grid().get_child_count(), 1, "um único item")
	var card := _grid().get_child(0) as Button
	assert_eq(card.custom_minimum_size, Vector2(96, 122), "tamanho mínimo constante")
	assert_eq(card.size_flags_vertical, Control.SIZE_FILL, "card não estica na vertical")


func test_inventory_card_image_fills_with_rounded_frame() -> void:
	await _bind_items([_item(_avatar_dict("av-1", "AVATAR/ceo.webp"))])

	var card := _grid().get_child(0) as Button
	var arts := card.find_children("*", "TextureRect", true, false)
	assert_eq(arts.size(), 1, "uma imagem por card")
	var art := arts[0] as TextureRect
	assert_eq(art.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_COVERED, "imagem preenche todo o card")
	assert_eq(Vector4(art.offset_left, art.offset_top, art.offset_right, art.offset_bottom), Vector4.ZERO, "imagem sem recuo")
	assert_true(art.material is ShaderMaterial, "máscara de cantos aplicada")
	var names_found := false
	for label in card.find_children("*", "Label", true, false):
		if (label as Label).text == "Avatar av-1":
			names_found = true
	assert_true(names_found, "nome sobre a imagem")
	var frame := card.get_node_or_null("CardFrame") as PanelContainer
	assert_not_null(frame, "moldura de contorno existe")
	assert_eq(card.get_child(card.get_child_count() - 1), frame, "moldura por cima da imagem")
	var ring := frame.get_theme_stylebox("panel") as StyleBoxFlat
	assert_false(ring.draw_center, "anel sem centro para a imagem aparecer")
	assert_eq(ring.corner_radius_top_left, 16, "cantos arredondados")
	assert_eq(ring.corner_radius_bottom_right, 16, "cantos arredondados")
	assert_eq(ring.border_color, Color(0.118, 0.165, 0.267), "contorno escuro")


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
	_page._on_section_pressed("OTHERS")
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


func test_inventory_tap_shows_equip_button() -> void:
	await _bind_items([_item(_avatar_dict("av-1", "AVATAR/ceo.webp"))])

	var card := _grid().get_child(0) as Button
	assert_null(_equip_button(card), "sem botão antes do toque")
	_page._on_item_pressed("av-1")
	await get_tree().process_frame
	card = _grid().get_child(0) as Button
	var eq := _equip_button(card)
	assert_not_null(eq, "toque revela o botão equipar")
	assert_eq(eq.text, "EQUIPAR", "rótulo do botão")


func test_inventory_equipped_item_has_green_ring() -> void:
	await _bind_items([_item(_avatar_dict("av-1", "AVATAR/ceo.webp", true))])
	_page._on_item_pressed("av-1")
	await get_tree().process_frame

	var card := _grid().get_child(0) as Button
	assert_null(_equip_button(card), "item equipado não oferece equipar")
	assert_eq(_card_ring(card).border_color, Color(0.2, 0.72, 0.42), "borda verde no item equipado")


func test_inventory_equip_flow_posts_and_updates() -> void:
	await _bind_items([
		_item(_avatar_dict("av-1", "AVATAR/ceo.webp")),
		_item(_avatar_dict("av-2", "AVATAR/ceo.webp")),
	])
	_repo.inventory_result = {
		"items": [
			_item(_avatar_dict("av-1", "AVATAR/ceo.webp")),
			_item(_avatar_dict("av-2", "AVATAR/ceo.webp", true)),
		],
		"status_code": 200,
	}
	_page._on_item_pressed("av-2")
	await get_tree().process_frame
	_page._on_equip_pressed("av-2")
	await get_tree().process_frame
	await get_tree().process_frame

	assert_eq(_repo.last_equip_id, "av-2", "POST para o item tocado")
	assert_eq(_repo.last_equip_context, "PROFILE", "contexto enviado no corpo")
	var target := _grid().get_child(1) as Button
	assert_eq(_card_ring(target).border_color, Color(0.2, 0.72, 0.42), "borda verde após equipar")
	assert_null(_equip_button(target), "botão some após equipar")


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
