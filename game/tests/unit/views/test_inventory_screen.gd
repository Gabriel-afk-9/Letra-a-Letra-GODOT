extends GutTest

var _page: InventoryScreen

func before_each() -> void:
	var scene: PackedScene = load("res://features/inventory/presentation/views/inventory_screen.tscn")
	_page = scene.instantiate()
	add_child(_page)
	await get_tree().process_frame

func after_each() -> void:
	_page.queue_free()

func test_inventory_page_id_and_layout() -> void:
	assert_eq(_page.page_id(), &"inventory", "page_id deve ser inventory")
	assert_not_null(_page.get_node("Content/MainVBox/TabsRow/AvatarTab"), "aba avatar deve existir")
	assert_not_null(_page.get_node("Content/MainVBox/TabsRow/FrameTab"), "aba moldura deve existir")
	assert_not_null(_page.get_node("Content/MainVBox/TabsRow/EmoteTab"), "aba emote deve existir")
	assert_not_null(_page.get_node("Content/MainVBox/TabsRow/ConsumableTab"), "aba consumíveis deve existir")
	var grid: GridContainer = _page.get_node("Content/MainVBox/Panel/PanelMargin/PanelVBox/ItemGrid")
	assert_eq(grid.columns, 3, "grade deve ter 3 colunas")
	assert_eq(grid.get_child_count(), 12, "primeira página deve exibir 12 itens")
	assert_eq(String((_page.get_node("Content/MainVBox/Panel/PanelMargin/PanelVBox/PagerRow/PagePill/PageMargin/PageLabel") as Label).text), "Pág 1", "deve iniciar na página 1")

func test_inventory_switches_category_and_pages() -> void:
	_page._on_tab_pressed(3)
	await get_tree().process_frame
	var grid: GridContainer = _page.get_node("Content/MainVBox/Panel/PanelMargin/PanelVBox/ItemGrid")
	assert_eq(grid.get_child_count(), 8, "consumíveis devem exibir 8 itens mockados")
	_page._on_tab_pressed(0)
	_page._on_next_pressed()
	await get_tree().process_frame
	assert_eq(_page._page, 1, "deve avançar para a página 2")
	assert_eq(grid.get_child_count(), 7, "segunda página deve exibir o restante")
	_page._on_prev_pressed()
	assert_eq(_page._page, 0, "deve voltar para a página 1")

func test_inventory_select_equips_and_ignores_locked() -> void:
	_page._on_item_pressed("avatar_6")
	assert_eq(String(_page._equipped[0]), "avatar_6", "seleção deve equipar o item")
	_page._on_item_pressed("avatar_18")
	assert_eq(String(_page._equipped[0]), "avatar_6", "item bloqueado deve ser ignorado")
	_page._on_tab_pressed(3)
	_page._on_item_pressed("cons_4")
	assert_eq(String(_page._selected[3]), "cons_4", "consumível deve apenas selecionar")

func test_inventory_script_has_no_hash_comments() -> void:
	var text := FileAccess.get_file_as_string("res://features/inventory/presentation/views/inventory_screen.gd")
	for line in text.split("\n"):
		assert_false((line as String).strip_edges().begins_with("#"), "script não deve conter comentários #")
