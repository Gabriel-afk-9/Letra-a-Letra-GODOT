extends RefCounted
class_name FriendsUseCase

var _friend_repository: FriendRepository
var _user_repository: UserRepository
var _session_store


func _init(
	friend_repository: FriendRepository,
	user_repository: UserRepository,
	session_store
) -> void:
	_friend_repository = friend_repository
	_user_repository = user_repository
	_session_store = session_store


func my_id() -> String:
	var user: User = _session_store.get_user()
	if user == null:
		return ""
	return user.id


func fetch_friends(page: int, size: int) -> Dictionary:
	return await _friend_repository.fetch_friends(page, size)


func fetch_pending() -> Dictionary:
	return await _friend_repository.fetch_pending()


func fetch_sent() -> Dictionary:
	return await _friend_repository.fetch_sent()


func accept_request(friend_id: String) -> Dictionary:
	return await _friend_repository.accept_request(friend_id)


func reject_request(friend_id: String) -> Dictionary:
	return await _friend_repository.reject_request(friend_id)


func cancel_request(friend_id: String) -> Dictionary:
	return await _friend_repository.cancel_request(friend_id)


func remove_friend(friend_id: String) -> Dictionary:
	return await _friend_repository.remove_friend(friend_id)


func find_user(username: String) -> User:
	return await _user_repository.find_by_username(username.strip_edges())


func fetch_users(page: int, size: int) -> Dictionary:
	return await _user_repository.fetch_users(page, size)


func search_users(username: String, page: int, size: int) -> Dictionary:
	return await _user_repository.search_users(username.strip_edges(), page, size)


func send_request(friend_id: String) -> Dictionary:
	return await _friend_repository.send_request(friend_id)
