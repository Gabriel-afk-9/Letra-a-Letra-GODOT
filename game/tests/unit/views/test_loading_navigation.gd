extends GutTest


func test_routes_contain_loading() -> void:
	assert_true(AppRoutes.LOADING.contains("loading_screen.tscn"), "AppRoutes deve expor LOADING")


func test_login_redirects_to_loading() -> void:
	var gd := FileAccess.get_file_as_string("res://features/login/presentation/viewmodels/login_viewmodel.gd")
	assert_true(gd.contains("AppRoutes.LOADING"), "login deve navegar para LOADING")
	assert_false(gd.contains("AppRoutes.SHELL"), "login não deve navegar direto para SHELL")


func test_register_redirects_to_loading() -> void:
	var gd := FileAccess.get_file_as_string("res://features/register/presentation/viewmodels/register_viewmodel.gd")
	assert_true(gd.contains("AppRoutes.LOADING"), "register deve navegar para LOADING")


func test_loading_navigates_to_shell_and_login() -> void:
	var gd := FileAccess.get_file_as_string("res://features/loading/presentation/viewmodels/loading_viewmodel.gd")
	assert_true(gd.contains("AppRoutes.SHELL"), "loading deve navegar para SHELL no sucesso")
	assert_true(gd.contains("AppRoutes.LOGIN"), "loading deve voltar ao LOGIN em 401")


func test_loading_screen_derives_from_main() -> void:
	var tscn := FileAccess.get_file_as_string("res://features/loading/presentation/views/loading_screen.tscn")
	assert_true(tscn.contains("vertical_clean.jpg"), "loading usa o mesmo background da main")
	assert_true(tscn.contains("l-cell.png"), "loading usa as mesmas células da main")
	assert_true(tscn.contains("lal.png"), "loading usa o mesmo logo da main")
	assert_true(tscn.contains("LoadingBar"), "loading tem barra na região dos botões")
	assert_true(tscn.contains("ProgressBar"), "barra é horizontal programática")
	assert_true(tscn.contains("TENTAR NOVAMENTE"), "loading tem retry")
	assert_false(tscn.contains("GoogleBtn"), "loading remove os botões da main")
	assert_false(tscn.contains("LoginPopup"), "loading não tem popups")
	var gd := FileAccess.get_file_as_string("res://features/loading/presentation/views/loading_screen.gd")
	assert_true(gd.contains("_start_logo_animation"), "loading preserva animação do logo")
	assert_true(gd.contains("CELL_FLIGHT_TIME"), "loading preserva animação das células")
	assert_true(gd.contains("LoadingFactory.create"), "loading monta via factory")


func test_home_uses_cached_user_first() -> void:
	var gd := FileAccess.get_file_as_string("res://features/home/presentation/views/home_screen.gd")
	assert_true(gd.contains("load_initial"), "home deve priorizar o usuário pré-carregado")
	var vm := FileAccess.get_file_as_string("res://features/home/presentation/viewmodels/home_viewmodel.gd")
	assert_true(vm.contains("InitialDataStore"), "home viewmodel deve conhecer o InitialDataStore")
