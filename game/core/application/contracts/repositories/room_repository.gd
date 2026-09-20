extends RefCounted
class_name RoomRepository


signal room_created(room: Room)
signal create_failed(message: String)


func fetch_public_rooms(
	page: int,
	size: int
) -> Dictionary:

	assert(false, "Must be implemented.")

	return {}


func search_rooms_by_name(
	room_name: String,
	page: int,
	size: int
) -> Dictionary:

	assert(false, "Must be implemented.")

	return {}


func find_game_by_code(
	code: String
) -> Dictionary:

	assert(false, "Must be implemented.")

	return {}


func create_room(
	room_name: String,
	allow_spectators: bool,
	private_game: bool
) -> void:

	assert(false, "Must be implemented.")
