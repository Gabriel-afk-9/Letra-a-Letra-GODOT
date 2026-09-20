extends RefCounted
class_name MainFactory

static func create() -> MainViewModel:
	var services := ServiceRegistry

	var login_repository := RemoteLoginRepository.new(services.http_client())

	var refresh_usecase := RefreshSessionUseCase.new(
		login_repository,
		services.user_repository(),
		SessionStore,
		services.session_persistence()
	)

	return MainViewModel.new(
		services.navigation_service(),
		refresh_usecase,
		SessionStore,
		services.session_persistence()
	)
