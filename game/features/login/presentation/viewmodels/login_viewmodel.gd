extends BaseViewModel

class_name LoginViewModel


var _controller: LoginController
var _navigation: NavigationService


func _init(
	controller: LoginController,
	navigation: NavigationService
) -> void:

	_controller = controller
	_navigation = navigation


func login(
	email: String,
	password: String
) -> void:

	_clear_error()

	_set_loading(true)

	var result: LoginResult = await _controller.login(
		email,
		password
	)

	_set_loading(false)

	if result.success:
		_navigation.go_to_home()
		return

	_set_error(result.message)
