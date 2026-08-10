extends RefCounted
class_name RegisterUseCase

var _register_repository: RegisterRepository
var _login_usecase: LoginUseCase

func _init(
	register_repository: RegisterRepository,
	login_usecase: LoginUseCase
) -> void:
	_register_repository = register_repository
	_login_usecase = login_usecase

func execute(email: String, password: String, nickname: String = "") -> RegisterResult:
	var request := RegisterRequest.new(email, password, nickname)
	var register_result: RegisterResult = await _register_repository.register(request)

	if not register_result.success:
		return register_result

	var login_result: LoginResult = await _login_usecase.execute(email, password)

	if not login_result.success:
		return RegisterResult.new(
			true,
			register_result.user,
			"",
			"Cadastro realizado! Mas houve um problema ao entrar automaticamente, tente fazer login."
		)

	return RegisterResult.new(
		true,
		login_result.user,
		login_result.access_token,
		register_result.message
	)
