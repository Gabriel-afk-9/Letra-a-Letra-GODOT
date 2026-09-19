extends GutTest

var _page: InventoryScreen

func before_each() -> void:
	var scene: PackedScene = load("res://features/inventory/presentation/views/inventory_screen.tscn")
	_page = scene.instantiate()
	add_child(_page)
	await get_tree().process_frame

func after_each() -> void:
	_page.queue_free()

func test_avatar_catalog_has_19_including_avatar_4() -> void:
	var avatars: Array = _page._catalog[0] as Array
	assert_eq(avatars.size(), 19, "AVATAR deve ter 19 itens incluindo avatar_4")
	var has_avatar_4 = false
	for item in avatars:
		if String(item["id"]) == "avatar_4":
			has_avatar_4 = true
			assert_eq(String(item["name"]), "AVATAR 4", "avatar_4 nome correto")
			assert_not_null(item["art"], "avatar_4 art deve existir")
			break
	assert_true(has_avatar_4, "avatar_4 deve existir no catálogo")

func test_page_count_math_19() -> void:
	var avatars: Array = _page._catalog[0] as Array
	assert_eq(avatars.size(), 19, "total 19")
	assert_eq(_page._page_count(), 2, "19/12 deve dar 2 páginas quando em AVATAR")
	_page._category = 3
	assert_eq(_page._page_count(), 1, "CONSUMABLE 8 deve dar 1 página")
	_page._category = 2
	assert_eq(_page._page_count(), 1, "EMOTE 9 deve dar 1 página")
	_page._category = 1
	assert_eq(_page._page_count(), 1, "FRAME 8 deve dar 1 página")
	_page._category = 0

func test_slice_boundaries_and_pager() -> void:
	_page._category = 0
	_page._page = 0
	assert_eq(_page._page_items().size(), 12, "página 0 deve ter 12")
	_page._page = 1
	assert_eq(_page._page_items().size(), 7, "página 1 deve ter 7 (19-12)")
	_page._page = 0
	_page._on_next_pressed()
	assert_eq(_page._page, 1, "next deve ir para 1")
	_page._on_next_pressed()
	assert_eq(_page._page, 1, "next no limite deve ficar em 1")
	_page._on_prev_pressed()
	assert_eq(_page._page, 0, "prev deve voltar para 0")
	_page._on_prev_pressed()
	assert_eq(_page._page, 0, "prev no limite deve ficar em 0")
	_page._refresh_pager()
	assert_true(_page._prev_btn.disabled, "prev desabilitado na página 0")
	assert_false(_page._next_btn.disabled, "next habilitado na página 0")
	_page._page = 1
	_page._refresh_pager()
	assert_false(_page._prev_btn.disabled, "prev habilitado na página 1")
	assert_true(_page._next_btn.disabled, "next desabilitado na última página")

func test_category_switch_resets_page() -> void:
	_page._category = 0
	_page._page = 1
	_page._on_tab_pressed(3)
	assert_eq(_page._category, 3, "categoria deve mudar")
	assert_eq(_page._page, 0, "troca de categoria deve resetar página")
	assert_eq(_page._page_count(), 1, "CONSUMABLE 8 página única")

