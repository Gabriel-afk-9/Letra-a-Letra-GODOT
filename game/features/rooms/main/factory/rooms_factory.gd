extends RefCounted
class_name RoomsFactory

static func create() -> RoomsViewModel:
	var services := ServiceRegistry

	var room_repository := RemoteRoomRepository.new(services.http_client())

	var usecase := RoomsUseCase.new(room_repository)

	return RoomsViewModel.new(usecase)
