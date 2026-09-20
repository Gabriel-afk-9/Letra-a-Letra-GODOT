extends RefCounted
class_name RoomRepository


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
