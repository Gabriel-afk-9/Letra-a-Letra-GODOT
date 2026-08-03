extends RefCounted
class_name MatchmakingFactory

static func bind(view: MatchmakingScreen) -> void:
	var usecase := MatchmakingUseCase.new(
		ServiceRegistry.matchmaking_repository()
	)
	
	var view_model := MatchmakingViewModel.new(usecase)
	var navigation := ServiceRegistry.navigation_service()
	
	view.setup(view_model, navigation)
