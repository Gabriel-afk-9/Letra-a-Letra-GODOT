extends RefCounted
class_name RoomsUseCase

var _room_repository: RoomRepository


func _init(room_repository: RoomRepository) -> void:
	_room_repository = room_repository


func fetch_public_rooms(page: int, size: int) -> Dictionary:
	return await _room_repository.fetch_public_rooms(page, size)


func search_rooms(room_name: String, page: int, size: int) -> Dictionary:
	var clean := room_name.strip_edges()
	if clean.is_empty():
		return {"error": "Digite o nome da sala para buscar."}
	return await _room_repository.search_rooms_by_name(clean, page, size)


func find_game_by_code(code: String) -> Dictionary:
	var clean := code.strip_edges()
	if clean.is_empty():
		return {"error": "Digite o código da sala."}
	return await _room_repository.find_game_by_code(clean)
