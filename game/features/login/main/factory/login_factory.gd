extends RefCounted
class_name LoginFactory

static func create() -> LoginViewModel:
	var services := ServiceRegistry

	var login_repository := RemoteLoginRepository.new(services.http_client())

	var usecase := LoginUseCase.new(
		login_repository,
		services.user_repository(),
		SessionStore
	)

	return LoginViewModel.new(usecase, services.navigation_service())
