extends RefCounted
class_name UserRepository


func fetch_current_user(
	access_token: String
) -> User:

	assert(false, "Must be implemented.")

	return null


func find_by_username(
	username: String
) -> User:

	assert(false, "Must be implemented.")

	return null


func fetch_users(
	page: int,
	size: int
) -> Dictionary:

	assert(false, "Must be implemented.")

	return {}


func search_users(
	username: String,
	page: int,
	size: int
) -> Dictionary:

	assert(false, "Must be implemented.")

	return {}
