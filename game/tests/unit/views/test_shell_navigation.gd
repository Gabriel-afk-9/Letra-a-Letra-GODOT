extends GutTest

func test_routes_exposes_shell_and_pages() -> void:
	var tscn := FileAccess.get_file_as_string("res://core/presentation/navigation/app_routes.gd")
	assert_true(tscn.contains("SHELL"), "AppRoutes deve expor SHELL")
	assert_true(tscn.contains("SHOP"), "AppRoutes deve expor SHOP")
	assert_true(tscn.contains("INVENTORY"), "AppRoutes deve expor INVENTORY")
	assert_true(tscn.contains("SOCIAL"), "AppRoutes deve expor SOCIAL")
	assert_true(tscn.contains("ROOMS"), "AppRoutes deve expor ROOMS")
	assert_true(tscn.contains("shell_screen.tscn"), "SHELL deve apontar para shell_screen")

func test_navbar_emits_page_selected_and_selects() -> void:
	var gd := FileAccess.get_file_as_string("res://shared/components/navbar/navbar.gd")
	assert_true(gd.contains("signal page_selected"), "navbar deve emitir page_selected")
	assert_true(gd.contains("func set_selected"), "navbar deve expor set_selected")
	assert_true(gd.contains("func set_page_enabled"), "navbar deve permitir bloqueio de página")
	assert_false(gd.contains("go_to("), "navbar não deve navegar diretamente")
	assert_false(gd.contains("NavigationManager"), "navbar não deve conhecer o manager")

func test_navbar_tscn_uses_navbar_icons() -> void:
	var tscn := FileAccess.get_file_as_string("res://shared/components/navbar/navbar.tscn")
	assert_true(tscn.contains("navbar-1.png"), "loja usa navbar-1")
	assert_true(tscn.contains("navbar-2.png"), "inventário usa navbar-2")
	assert_true(tscn.contains("navbar-3.png"), "play usa navbar-3")
	assert_true(tscn.contains("navbar-4.png"), "amigos usa navbar-4")
	assert_true(tscn.contains("navbar-5.png"), "salas usa navbar-5")

func test_navigation_manager_supports_guards_and_state() -> void:
	var gd := FileAccess.get_file_as_string("res://core/presentation/navigation/navigation_manager.gd")
	assert_true(gd.contains("func register_page"), "manager registra páginas")
	assert_true(gd.contains("func select"), "manager seleciona página")
	assert_true(gd.contains("can_leave"), "manager respeita guarda can_leave")
	assert_true(gd.contains("set_page_enabled"), "manager permite bloquear página")
	assert_true(gd.contains("signal page_changed"), "manager notifica troca")

func test_shell_wires_navbar_to_manager() -> void:
	var gd := FileAccess.get_file_as_string("res://features/shell/presentation/views/shell_screen.gd")
	assert_true(gd.contains("page_selected.connect"), "shell conecta navbar ao manager")
	assert_true(gd.contains("page_changed.connect"), "shell reflete página ativa na navbar")
	var factory := FileAccess.get_file_as_string("res://features/shell/main/factory/shell_factory.gd")
	assert_true(factory.contains("NavigationManager.new"), "factory monta o manager")
	assert_true(factory.contains("register_page"), "factory registra as 5 páginas")

func test_home_is_play_page_without_navbar() -> void:
	var gd := FileAccess.get_file_as_string("res://features/home/presentation/views/home_screen.gd")
	assert_true(gd.contains("extends HubPage"), "home é página do hub")
	assert_true(gd.contains("return &\"play\""), "home responde pelo page_id play")
	assert_false(gd.contains("BottomNav"), "home não contém navbar embutida")
	var tscn := FileAccess.get_file_as_string("res://features/home/presentation/views/home_screen.tscn")
	assert_false(tscn.contains("BottomNav"), "cena home não contém BottomNav")

func test_auth_redirects_to_shell() -> void:
	var login := FileAccess.get_file_as_string("res://features/login/presentation/viewmodels/login_viewmodel.gd")
	assert_true(login.contains("AppRoutes.SHELL"), "login vai para o shell")
	var register := FileAccess.get_file_as_string("res://features/register/presentation/viewmodels/register_viewmodel.gd")
	assert_true(register.contains("AppRoutes.SHELL"), "registro vai para o shell")
