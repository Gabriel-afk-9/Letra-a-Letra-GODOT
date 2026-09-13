extends RefCounted
class_name FriendRepository


func fetch_friends(
	page: int,
	size: int
) -> Dictionary:

	assert(false, "Must be implemented.")

	return {}


func fetch_pending() -> Dictionary:

	assert(false, "Must be implemented.")

	return {}


func fetch_sent() -> Dictionary:

	assert(false, "Must be implemented.")

	return {}


func send_request(
	friend_id: String
) -> Dictionary:

	assert(false, "Must be implemented.")

	return {}


func accept_request(
	friend_id: String
) -> Dictionary:

	assert(false, "Must be implemented.")

	return {}


func reject_request(
	friend_id: String
) -> Dictionary:

	assert(false, "Must be implemented.")

	return {}


func cancel_request(
	friend_id: String
) -> Dictionary:

	assert(false, "Must be implemented.")

	return {}


func remove_friend(
	friend_id: String
) -> Dictionary:

	assert(false, "Must be implemented.")

	return {}
