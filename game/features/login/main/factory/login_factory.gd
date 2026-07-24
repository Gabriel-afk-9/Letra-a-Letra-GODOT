extends RefCounted

class_name LoginFactory


static func create() -> LoginViewModel:

	var services := ServiceRegistry

	var repository := RemoteLoginRepository.new(
		services.http_client()
	)

	var usecase := LoginUseCase.new(
		repository,
		SessionStore
	)

	return LoginViewModel.new(
		usecase,
		services.navigation_service()
	)
