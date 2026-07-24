extends BaseViewModel

class_name LoginViewModel


var _usecase: LoginUseCase
var _navigation: NavigationService


func _init(
	usecase: LoginUseCase,
	navigation: NavigationService
) -> void:

	_usecase = usecase
	_navigation = navigation


func login(
	email: String,
	password: String
) -> void:

	_clear_error()

	_set_loading(true)

	var result: LoginResult = await _usecase.execute(
		email,
		password
	)

	_set_loading(false)

	if result.success:

		_navigation.go_to(AppRoutes.HOME)
		return

	_set_error(result.message)

func go_to_register() -> void:
	_navigation.go_to(AppRoutes.REGISTER)
