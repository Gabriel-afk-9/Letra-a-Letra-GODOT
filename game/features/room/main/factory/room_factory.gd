extends RefCounted
class_name RoomFactory


static func bind(view: RoomLobbyScreen) -> void:
	var payload: Variant = ServiceRegistry.pending_navigation_payload().take_payload()

	if not payload is RoomCreatedEvent:
		AppLogger.error("RoomFactory: chegou à sala sem passar pela criação.")
		ServiceRegistry.navigation_service().go_to(AppRoutes.SHELL)
		return

	view.setup((payload as RoomCreatedEvent).game_name)
