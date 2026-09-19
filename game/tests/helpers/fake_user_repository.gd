extends UserRepository
class_name FakeUserRepository

var scripted_user: User = null
var scripted_profile_result: Dictionary = {"user": null, "status_code": 200}
var users_result: Dictionary = {"users": [], "page": 0, "total_pages": 1, "total_elements": 0}
var search_result: Dictionary = {"users": [], "page": 0, "total_pages": 1, "total_elements": 0}

var last_users_page: int = -1
var last_search_term: String = ""
var last_search_page: int = -1
var last_profile_token: String = ""


func fetch_current_user(access_token: String) -> User:
	return scripted_user


func fetch_current_user_result(access_token: String) -> Dictionary:
	last_profile_token = access_token
	return scripted_profile_result


func find_by_username(username: String) -> User:
	return scripted_user


func fetch_users(page: int, size: int) -> Dictionary:
	last_users_page = page
	return users_result


func search_users(username: String, page: int, size: int) -> Dictionary:
	last_search_term = username
	last_search_page = page
	return search_result
