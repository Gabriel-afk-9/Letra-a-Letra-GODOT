extends RefCounted
class_name RegisterFactory

static func create() -> RegisterViewModel:
	var services := ServiceRegistry

	var register_repository := RemoteRegisterRepository.new(services.http_client())
	var login_repository := RemoteLoginRepository.new(services.http_client())

	var login_usecase := LoginUseCase.new(
		login_repository,
		services.user_repository(),
		SessionStore
	)

	var register_usecase := RegisterUseCase.new(
		register_repository,
		login_usecase
	)

	return RegisterViewModel.new(register_usecase, services.navigation_service())
