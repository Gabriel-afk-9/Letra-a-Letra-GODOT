extends FriendRepository
class_name FakeFriendRepository

var friends_result: Dictionary = {"friends": [], "page": 0, "total_pages": 1, "total_elements": 0}
var pending_result: Dictionary = {"requests": []}
var sent_result: Dictionary = {"requests": []}
var mutate_result: Dictionary = {"ok": true}

var last_page: int = -1
var last_size: int = -1
var last_sent: String = ""
var last_accepted: String = ""
var last_rejected: String = ""
var last_cancelled: String = ""
var last_removed: String = ""


func fetch_friends(page: int, size: int) -> Dictionary:
	last_page = page
	last_size = size
	return friends_result


func fetch_pending() -> Dictionary:
	return pending_result


func fetch_sent() -> Dictionary:
	return sent_result


func send_request(friend_id: String) -> Dictionary:
	last_sent = friend_id
	return mutate_result


func accept_request(friend_id: String) -> Dictionary:
	last_accepted = friend_id
	return mutate_result


func reject_request(friend_id: String) -> Dictionary:
	last_rejected = friend_id
	return mutate_result


func cancel_request(friend_id: String) -> Dictionary:
	last_cancelled = friend_id
	return mutate_result


func remove_friend(friend_id: String) -> Dictionary:
	last_removed = friend_id
	return mutate_result
