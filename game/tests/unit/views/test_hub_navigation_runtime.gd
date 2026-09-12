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

func test_order_navigation_goes_next_and_previous() -> void:
	assert_eq(_manager.page_order(), [&"shop", &"inventory", &"social", &"rooms"], "ordem segue o registro")
	_manager.select(&"shop")
	_manager.select_next()
	assert_eq(_manager.current_page(), &"inventory", "next avança")
	_manager.select_previous()
	assert_eq(_manager.current_page(), &"shop", "previous volta")

func test_order_navigation_skips_disabled_pages() -> void:
	_manager.select(&"shop")
	_manager.set_page_enabled(&"inventory", false)
	_manager.select_next()
	assert_eq(_manager.current_page(), &"social", "next pula página bloqueada")

func test_page_changed_emitted_on_select() -> void:
	var received: Array = []
	_manager.page_changed.connect(func(page_id: StringName) -> void: received.append(page_id))
	_manager.select(&"shop")
	_manager.select(&"social")
	assert_eq(received, [&"shop", &"social"], "navbar deve refletir cada troca via page_changed")

func test_shell_clip_and_swipe_wiring() -> void:
	var tscn := FileAccess.get_file_as_string("res://features/shell/presentation/views/shell_screen.tscn")
	assert_true(tscn.contains("clip_contents = true"), "container deve recortar o slide")
	var gd := FileAccess.get_file_as_string("res://features/shell/presentation/views/shell_screen.gd")
	assert_true(gd.contains("select_next"), "shell deve avançar no swipe para a esquerda")
	assert_true(gd.contains("select_previous"), "shell deve voltar no swipe para a direita")
	assert_true(gd.contains("InputEventScreenDrag"), "shell deve suportar arrasto touch")
	assert_true(gd.contains("func _input"), "shell deve capturar o gesto antes da GUI consumir")

func test_shell_factory_registers_visual_navbar_order() -> void:
	var factory := FileAccess.get_file_as_string("res://features/shell/main/factory/shell_factory.gd")
	var expected := [&"shop", &"inventory", &"play", &"social", &"rooms"]
	var last_pos := -1
	for page_id in expected:
		var pos := factory.find("PAGE_" + page_id.to_upper())
		assert_true(pos > last_pos, "registro de %s deve seguir a ordem visual da navbar" % page_id)
		last_pos = pos

func _find_page(page_id: StringName) -> HubPage:
	for child in _container.get_children():
		var page := child as HubPage
		if page != null and page.page_id() == page_id:
			return page
	return null

func test_shell_swipe_input_changes_page() -> void:
	var shell_scene: PackedScene = load("res://features/shell/presentation/views/shell_screen.tscn")
	var shell: ShellScreen = shell_scene.instantiate()
	add_child(shell)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_eq(shell._manager.current_page(), &"play", "shell inicia no play")
	var press := InputEventScreenTouch.new()
	press.pressed = true
	press.index = 0
	press.position = Vector2(300, 400)
	shell._input(press)
	var drag := InputEventScreenDrag.new()
	drag.index = 0
	drag.position = Vector2(100, 410)
	shell._input(drag)
	var release := InputEventScreenTouch.new()
	release.pressed = false
	release.index = 0
	release.position = Vector2(100, 410)
	shell._input(release)
	await get_tree().process_frame
	assert_eq(shell._manager.current_page(), &"social", "arrastar para a esquerda avança")
	shell.queue_free()
