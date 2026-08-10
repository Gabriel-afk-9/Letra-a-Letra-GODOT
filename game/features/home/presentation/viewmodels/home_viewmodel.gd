extends BaseViewModel
class_name HomeViewModel

signal user_loaded(user: User)

var _get_current_user_usecase: GetCurrentUserUseCase
var _navigation: NavigationService

func _init(
	get_current_user_usecase: GetCurrentUserUseCase,
	navigation: NavigationService
) -> void:
	_get_current_user_usecase = get_current_user_usecase
	_navigation = navigation

func load_user() -> void:
	_set_loading(true)
	var user: User = _get_current_user_usecase.execute()
	_set_loading(false)

	if user == null:
		_set_error("Usuário não encontrado.")
		return

	user_loaded.emit(user)

func go_to_matchmaking() -> void:
	_navigation.go_to(AppRoutes.MATCHMAKING)

#func go_to_room() -> void:
	#_navigation.go_to(AppRoutes.ROOM)

func exit_game() -> void:
	_navigation.quit_game()
