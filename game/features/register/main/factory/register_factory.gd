extends RefCounted
class_name RegisterFactory


static func create() -> RegisterViewModel:

	var services := ServiceRegistry

	var register_repository := RemoteRegisterRepository.new(services.http_client())
	var login_repository := RemoteLoginRepository.new(services.http_client())

	var usecase := RegisterUseCase.new(
		register_repository,
		login_repository,
		SessionStore
	)

	return RegisterViewModel.new(usecase, services.navigation_service())
