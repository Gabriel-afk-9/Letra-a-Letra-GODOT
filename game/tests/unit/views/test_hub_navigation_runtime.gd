extends GutTest

const PAGES := {
	&"shop": ["res://features/shop/presentation/views/shop_screen.tscn", "Loja"],
	&"inventory": ["res://features/inventory/presentation/views/inventory_screen.tscn", "Inventário"],
	&"social": ["res://features/social/presentation/views/social_screen.tscn", "Amigos"],
	&"rooms": ["res://features/rooms/presentation/views/rooms_screen.tscn", "Salas Personalizadas"],
}

var _container: Control
var _manager: NavigationManager

func before_each() -> void:
	_container = Control.new()
	add_child(_container)
	_manager = NavigationManager.new(_container)
	for page_id in PAGES:
		_manager.register_page(page_id, PAGES[page_id][0])

func after_each() -> void:
	_container.queue_free()

func test_select_each_page_shows_identifying_text() -> void:
	for page_id in PAGES:
		_manager.select(page_id)
		assert_eq(_manager.current_page(), page_id, "página atual deve ser %s" % page_id)
		var page := _find_page(page_id)
		assert_not_null(page, "página %s deve estar instanciada" % page_id)
		assert_true(page.visible, "página %s deve estar visível" % page_id)
		assert_eq(page.page_id(), page_id, "page_id deve corresponder")
		var title: Label = page.get_node("Center/VBox/Title")
		assert_eq(title.text, PAGES[page_id][1], "texto deve identificar a página")

func test_only_current_page_is_visible() -> void:
	_manager.select(&"shop")
	_manager.select(&"inventory")
	for child in _container.get_children():
		if (child as HubPage).page_id() == &"inventory":
			assert_true(child.visible, "inventário visível")
		else:
			assert_false(child.visible, "página anterior oculta")

func test_reselect_same_page_is_noop() -> void:
	_manager.select(&"social")
	var count := _container.get_child_count()
	_manager.select(&"social")
	assert_eq(_container.get_child_count(), count, "não deve reinstanciar")

func test_unknown_page_is_ignored() -> void:
	_manager.select(&"shop")
	_manager.select(&"unknown")
	assert_eq(_manager.current_page(), &"shop", "página desconhecida ignorada")

func test_disabled_page_is_blocked() -> void:
	_manager.select(&"shop")
	_manager.set_page_enabled(&"rooms", false)
	_manager.select(&"rooms")
	assert_eq(_manager.current_page(), &"shop", "página bloqueada não abre")
	_manager.set_page_enabled(&"rooms", true)
	_manager.select(&"rooms")
	assert_eq(_manager.current_page(), &"rooms", "página liberada abre")

func _find_page(page_id: StringName) -> HubPage:
	for child in _container.get_children():
		var page := child as HubPage
		if page != null and page.page_id() == page_id:
			return page
	return null
