extends RoomRepository
class_name FakeRoomRepository

var browse_result: Dictionary = {"rooms": [], "page": 0, "total_pages": 1, "total_elements": 0}
var search_result: Dictionary = {"rooms": [], "page": 0, "total_pages": 1, "total_elements": 0}
var code_result: Dictionary = {"game_id": "game-1"}

var last_page: int = -1
var last_size: int = -1
var last_search_term: String = ""
var last_code: String = ""


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
