extends Node

signal session_started(user: User)
signal session_ended
signal session_changed

var _current_user: User = null
var _access_token: String = ""


func start_session(user: User, access_token: String) -> void:
	_current_user = user
	_access_token = access_token

	session_started.emit(user)
	session_changed.emit()


func end_session() -> void:
	_clear_session()

	session_ended.emit()
	session_changed.emit()


func is_authenticated() -> bool:
	return _current_user != null and not _access_token.is_empty()


func has_user() -> bool:
	return _current_user != null


func has_token() -> bool:
	return not _access_token.is_empty()


func get_user() -> User:
	return _current_user


func get_token() -> String:
	return _access_token


func _clear_session() -> void:
	_current_user = null
	_access_token = ""

func has_session() -> bool:
	return has_user() and has_token()
