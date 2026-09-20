extends RoomRepository
class_name FakeRoomRepository

var browse_result: Dictionary = {"rooms": [], "page": 0, "total_pages": 1, "total_elements": 0}
var search_result: Dictionary = {"rooms": [], "page": 0, "total_pages": 1, "total_elements": 0}
var code_result: Dictionary = {"game_id": "game-1"}
var create_result: Dictionary = {"ok": true}
var join_result: Dictionary = {"ok": true}

var last_page: int = -1
var last_size: int = -1
var last_search_term: String = ""
var last_code: String = ""
var last_create_name: String = ""
var last_create_allow: bool = false
var last_create_private: bool = false
var last_join_game_id: String = ""


func fetch_public_rooms(page: int, size: int) -> Dictionary:
	last_page = page
	last_size = size
	return browse_result


func search_rooms_by_name(room_name: String, page: int, size: int) -> Dictionary:
	last_search_term = room_name
	last_page = page
	last_size = size
	return search_result


func find_game_by_code(code: String) -> Dictionary:
	last_code = code
	return code_result


func create_room(room_name: String, allow_spectators: bool, private_game: bool) -> void:
	last_create_name = room_name
	last_create_allow = allow_spectators
	last_create_private = private_game
	if create_result.has("room"):
		room_created.emit(create_result["room"])
	elif create_result.has("error"):
		create_failed.emit(str(create_result["error"]))


func join_room(game_id: String) -> void:
	last_join_game_id = game_id
	if join_result.has("room"):
		room_joined.emit(join_result["room"])
	elif join_result.has("error"):
		join_failed.emit(str(join_result["error"]))
