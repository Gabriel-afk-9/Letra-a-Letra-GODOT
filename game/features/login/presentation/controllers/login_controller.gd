extends RefCounted

class_name LoginController


var _login_usecase


func _init(login_usecase) -> void:
	_login_usecase = login_usecase


func login(
	email: String,
	password: String
) -> LoginResult:

	var request := LoginRequest.new(email, password)

	return await _login_usecase.execute(request)
