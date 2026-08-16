extends RefCounted
class_name MatchmakingFactory


static func bind(view: MatchmakingScreen) -> void:
	var current_user_provider := ServiceRegistry.current_user_provider()

	var usecase := MatchmakingUseCase.new(
		ServiceRegistry.matchmaking_repository(),
		current_user_provider
	)

	var navigation := ServiceRegistry.navigation_service()
	var pending_navigation_payload := ServiceRegistry.pending_navigation_payload()
	var view_model := MatchmakingViewModel.new(usecase, navigation, pending_navigation_payload)

	view.setup(view_model)
