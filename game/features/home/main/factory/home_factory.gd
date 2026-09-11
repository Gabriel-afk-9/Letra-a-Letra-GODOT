extends RefCounted
class_name HomeFactory

static func create() -> HomeViewModel:
	var services := ServiceRegistry

	var get_current_user_usecase := GetCurrentUserUseCase.new(
		services.user_repository(),
		SessionStore
	)

	return HomeViewModel.new(
		get_current_user_usecase,
		services.navigation_service()
	)
