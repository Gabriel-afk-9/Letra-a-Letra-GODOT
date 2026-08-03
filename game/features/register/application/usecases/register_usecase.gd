extends RefCounted
class_name RegisterUseCase


var _register_repository: RemoteRegisterRepository
var _login_repository: RemoteLoginRepository
var _session_store


func _init(
	register_repository: RemoteRegisterRepository,
	login_repository: RemoteLoginRepository,
	session_store
) -> void:
	_register_repository = register_repository
	_login_repository = login_repository
	_session_store = session_store


func execute(
	email: String,
	password: String,
	nickname: String = ""
) -> RegisterResult:

	var request := RegisterRequest.new(email, password, nickname)

	var register_result: RegisterResult = await _register_repository.register(request)

	if not register_result.success:
		return register_result

	var real_nickname: String = ""
	if register_result.user != null:
		real_nickname = register_result.user.nickname

	var login_request := LoginRequest.new(email, password)
	var login_result: LoginResult = await _login_repository.login(login_request)

	if not login_result.success:
		return RegisterResult.new(
			true,
			register_result.user,
			"",
			"Cadastro realizado! Mas houve um problema ao entrar automaticamente, tente fazer login."
		)

	var final_user := User.new(
		login_result.user.id,
		email,
		real_nickname
	)

	_session_store.start_session(final_user, login_result.access_token)

	return RegisterResult.new(
		true,
		final_user,
		login_result.access_token,
		register_result.message
	)
