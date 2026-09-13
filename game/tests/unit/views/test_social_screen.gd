extends GutTest

var _page: SocialScreen


func before_each() -> void:
	var scene: PackedScene = load("res://features/social/presentation/views/social_screen.tscn")
	_page = scene.instantiate()
	add_child(_page)
	await get_tree().process_frame


func after_each() -> void:
	_page.queue_free()


func test_social_page_id_and_sections() -> void:
	assert_eq(_page.page_id(), &"social", "page_id deve ser social")
	assert_eq((_page.get_node("Center/VBox/Title") as Label).text, "Amigos", "título deve ser Amigos")
	assert_not_null(_page.get_node("Center/VBox/TabsRow/FriendsTab"), "aba amigos deve existir")
	assert_not_null(_page.get_node("Center/VBox/TabsRow/PendingTab"), "aba pedidos deve existir")
	assert_not_null(_page.get_node("Center/VBox/TabsRow/SentTab"), "aba enviados deve existir")
	assert_not_null(_page.get_node("Center/VBox/TabsRow/AddTab"), "aba adicionar deve existir")
	assert_not_null(_page.get_node("Center/VBox/ContentPanel/ContentMargin/FriendsSection"), "seção de amigos deve existir")
	assert_not_null(_page.get_node("Center/VBox/ContentPanel/ContentMargin/PendingSection"), "seção de pedidos deve existir")
	assert_not_null(_page.get_node("Center/VBox/ContentPanel/ContentMargin/SentSection"), "seção de enviados deve existir")
	assert_not_null(_page.get_node("Center/VBox/ContentPanel/ContentMargin/AddSection"), "seção de adicionar deve existir")


func test_social_only_active_section_is_visible() -> void:
	assert_true(_page.get_node("Center/VBox/ContentPanel/ContentMargin/FriendsSection").visible, "amigos visível por padrão")
	assert_false(_page.get_node("Center/VBox/ContentPanel/ContentMargin/PendingSection").visible, "pedidos oculto por padrão")
	assert_false(_page.get_node("Center/VBox/ContentPanel/ContentMargin/SentSection").visible, "enviados oculto por padrão")
	assert_false(_page.get_node("Center/VBox/ContentPanel/ContentMargin/AddSection").visible, "adicionar oculto por padrão")
	_page._on_tab_pressed(3)
	assert_true(_page.get_node("Center/VBox/ContentPanel/ContentMargin/AddSection").visible, "adicionar visível após troca")
	assert_false(_page.get_node("Center/VBox/ContentPanel/ContentMargin/FriendsSection").visible, "amigos oculto após troca")
	_page._on_tab_pressed(2)
	assert_true(_page.get_node("Center/VBox/ContentPanel/ContentMargin/SentSection").visible, "enviados visível após troca")
	_page._on_tab_pressed(1)
	assert_true(_page.get_node("Center/VBox/ContentPanel/ContentMargin/PendingSection").visible, "pedidos visível após troca")


func test_social_sent_section_empty_state() -> void:
	assert_eq((_page.get_node("Center/VBox/ContentPanel/ContentMargin/SentSection/SentStatusLabel") as Label).text, "Nenhum pedido enviado.", "sem enviados deve informar")


func test_social_pager_and_search_controls() -> void:
	assert_not_null(_page.get_node("Center/VBox/ContentPanel/ContentMargin/FriendsSection/PagerRow/PrevBtn"), "botão anterior deve existir")
	assert_not_null(_page.get_node("Center/VBox/ContentPanel/ContentMargin/FriendsSection/PagerRow/NextBtn"), "botão próximo deve existir")
	assert_eq((_page.get_node("Center/VBox/ContentPanel/ContentMargin/FriendsSection/PagerRow/PagePill/PageMargin/PageLabel") as Label).text, "Pág 1", "deve iniciar na página 1")
	var grid: GridContainer = _page.get_node("Center/VBox/ContentPanel/ContentMargin/AddSection/UserScroll/UserGrid")
	assert_eq(grid.columns, 2, "grade deve ter 2 colunas")
	assert_not_null(_page.get_node("Center/VBox/ContentPanel/ContentMargin/AddSection/SearchRow/SearchInput"), "campo de busca deve existir")
	assert_not_null(_page.get_node("Center/VBox/ContentPanel/ContentMargin/AddSection/SearchRow/SearchBtn"), "botão buscar deve existir")
	assert_not_null(_page.get_node("Center/VBox/ContentPanel/ContentMargin/AddSection/DiscoverPagerRow/DiscoverPrevBtn"), "paginação da grade deve existir")


func test_social_empty_states_without_backend() -> void:
	assert_eq((_page.get_node("Center/VBox/ContentPanel/ContentMargin/FriendsSection/FriendsStatusLabel") as Label).text, "Você ainda não tem amigos.", "lista vazia deve informar")
	assert_eq((_page.get_node("Center/VBox/ContentPanel/ContentMargin/PendingSection/PendingStatusLabel") as Label).text, "Nenhum pedido no momento.", "sem pedidos deve informar")


func test_social_refresh_buttons_exist_in_all_lists() -> void:
	var refresh_btn: Button = _page.get_node("TopCorner/RefreshBtn")
	assert_not_null(refresh_btn, "botão atualizar deve existir fora do painel")
	assert_eq(refresh_btn.custom_minimum_size, Vector2(65, 65), "tamanho igual ao menu da home")
	assert_not_null(refresh_btn.get("icon"), "botão deve usar ícone")
	assert_true(refresh_btn.visible, "visível na seção de amigos")
	_page._on_tab_pressed(1)
	assert_true(refresh_btn.visible, "visível nos recebidos")
	_page._on_tab_pressed(2)
	assert_true(refresh_btn.visible, "visível nos enviados")
	_page._on_tab_pressed(3)
	assert_false(refresh_btn.visible, "oculto ao adicionar")


func test_social_clearing_search_returns_to_browse() -> void:
	_page._view_model.search_users("zzz")
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(_page._view_model.discover_mode(), "search")
	_page._search_input.text = "zzz"
	_page._on_search_text_changed("")
	assert_eq(_page._view_model.discover_mode(), "browse")
	assert_true(_page._view_model.discover_users().is_empty())


func test_social_script_has_no_hash_comments() -> void:
	var text := FileAccess.get_file_as_string("res://features/social/presentation/views/social_screen.gd")
	for line in text.split("\n"):
		assert_false((line as String).strip_edges().begins_with("#"), "script não deve conter comentários #")
