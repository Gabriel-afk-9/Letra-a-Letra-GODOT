extends BaseViewModel
class_name RegisterViewModel


var _usecase: RegisterUseCase
var _navigation: NavigationService


func _init(
	usecase: RegisterUseCase,
	navigation: NavigationService
) -> void:
	_usecase = usecase
	_navigation = navigation


func register(
	email: String,
	password: String,
	nickname: String = ""
) -> void:

	_clear_error()

	_set_loading(true)

	var result: RegisterResult = await _usecase.execute(
		email,
		password,
		nickname
	)

	_set_loading(false)

	if result.success:
		_navigation.go_to(AppRoutes.HOME)
		return

	_set_error(result.message)


func go_to_login() -> void:
	_navigation.go_to(AppRoutes.LOGIN)
