extends RefCounted
class_name GameFactory


static func bind(view: GameScreen) -> void:
	var payload: Variant = ServiceRegistry.pending_navigation_payload().take_payload()

	if not payload is MatchmakingFoundEvent:
		AppLogger.error("GameFactory: chegou à tela de jogo sem passar pelo matchmaking.")
		ServiceRegistry.navigation_service().go_to(AppRoutes.SHELL)
		return

	var event: MatchmakingFoundEvent = payload

	var usecase := GameUseCase.new(
		ServiceRegistry.game_repository(),
		ServiceRegistry.current_user_provider()
	)

	var view_model := GameViewModel.new(usecase, ServiceRegistry.navigation_service())

	view.setup(
		view_model,
		event.game_id,
		event.opponent.id,
		event.me.nickname,
		event.opponent.nickname
	)
