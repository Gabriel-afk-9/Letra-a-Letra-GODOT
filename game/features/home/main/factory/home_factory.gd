extends RefCounted
class_name HomeFactory

static func create() -> HomeViewModel:
	var services := ServiceRegistry

	var get_current_user_usecase := GetCurrentUserUseCase.new(
		services.user_repository(),
		SessionStore
	)

	var login_repository := RemoteLoginRepository.new(
		services.http_client()
	)

	return HomeViewModel.new(
		get_current_user_usecase,
		services.navigation_service(),
		services.initial_data_store(),
		login_repository,
		SessionStore,
		services.session_persistence()
	)
