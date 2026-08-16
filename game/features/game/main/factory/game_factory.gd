extends RefCounted
class_name GameFactory


static func bind(view: GameScreen) -> void:
	var payload: Variant = ServiceRegistry.pending_navigation_payload().take_payload()

	if not payload is MatchmakingFoundEvent:
		AppLogger.error("GameFactory: chegou à tela de jogo sem passar pelo matchmaking.")
		ServiceRegistry.navigation_service().go_to(AppRoutes.HOME)
		return

	var event: MatchmakingFoundEvent = payload

	var usecase := GameUseCase.new(
		ServiceRegistry.game_repository(),
		ServiceRegistry.current_user_provider()
	)

	var view_model := GameViewModel.new(usecase, ServiceRegistry.navigation_service())

	# start() é chamado DE DENTRO de view.setup(), depois que a View já
	# conectou os sinais — chamar aqui perderia as emissões de loading_changed.
	# Nicknames são repassados do evento do matchmaking para a View preencher
	# os PlayerCards sem buscar dados no backend por conta própria.
	view.setup(
		view_model,
		event.game_id,
		event.opponent.id,
		event.me.nickname,
		event.opponent.nickname
	)
