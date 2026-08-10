extends RefCounted
class_name MatchmakingFactory


static func bind(view: MatchmakingScreen) -> void:
	var current_user_provider := ServiceRegistry.current_user_provider()

	var usecase := MatchmakingUseCase.new(
		ServiceRegistry.matchmaking_repository(),
		current_user_provider
	)

	var navigation := ServiceRegistry.navigation_service()
	var view_model := MatchmakingViewModel.new(usecase, navigation)

	view.setup(view_model)
