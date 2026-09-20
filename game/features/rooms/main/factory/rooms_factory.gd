extends RefCounted
class_name RoomsFactory

static func create() -> RoomsViewModel:
	var services := ServiceRegistry

	var room_repository := RemoteRoomRepository.new(
		services.http_client(),
		services.websocket_client()
	)

	var usecase := RoomsUseCase.new(room_repository)

	return RoomsViewModel.new(
		usecase,
		services.navigation_service(),
		services.pending_navigation_payload()
	)
