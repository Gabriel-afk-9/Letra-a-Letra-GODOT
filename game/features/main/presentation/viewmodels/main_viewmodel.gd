extends BaseViewModel
class_name MainViewModel


var _navigation: NavigationService


func _init(
	navigation: NavigationService
) -> void:
	_navigation = navigation


func go_to_login() -> void:
	_navigation.go_to(AppRoutes.LOGIN)


func login_with_google() -> void:
	AppLogger.debug("MainViewModel: login_with_google ainda não implementado")
	_set_error("Login com Google em breve!")


func continue_as_guest() -> void:
	AppLogger.debug("MainViewModel: continue_as_guest ainda não implementado")
	_set_error("Entrada como convidado em breve!")
