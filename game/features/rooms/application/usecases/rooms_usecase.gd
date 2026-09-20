extends RefCounted
class_name RoomsUseCase

signal room_created(room: Room)
signal create_failed(message: String)
signal room_joined(room: Room)
signal join_failed(message: String)

const ROOM_NAME_MAX_LENGTH := 32

var _room_repository: RoomRepository


func _init(room_repository: RoomRepository) -> void:
	_room_repository = room_repository
	_room_repository.room_created.connect(_on_room_created)
	_room_repository.create_failed.connect(_on_create_failed)
	_room_repository.room_joined.connect(_on_room_joined)
	_room_repository.join_failed.connect(_on_join_failed)


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


func create_room(room_name: String, allow_spectators: bool, private_game: bool) -> Dictionary:
	var clean := room_name.strip_edges()
	if clean.is_empty():
		return {"error": "Digite o nome da sala."}
	if clean.length() > ROOM_NAME_MAX_LENGTH:
		return {"error": "O nome da sala deve ter no máximo %d caracteres." % ROOM_NAME_MAX_LENGTH}
	_room_repository.create_room(clean, allow_spectators, private_game)
	return {"ok": true}


func _on_room_created(room: Room) -> void:
	room_created.emit(room)


func _on_create_failed(message: String) -> void:
	create_failed.emit(message)


func join_room(game_id: String) -> Dictionary:
	var clean := game_id.strip_edges()
	if clean.is_empty():
		return {"error": "Selecione uma sala válida."}
	_room_repository.join_room(clean)
	return {"ok": true}


func _on_room_joined(room: Room) -> void:
	room_joined.emit(room)


func _on_join_failed(message: String) -> void:
	join_failed.emit(message)
