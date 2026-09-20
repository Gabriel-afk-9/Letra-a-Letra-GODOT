extends RefCounted
class_name LoginResult


var success: bool

var user: User

var access_token: String

var refresh_token: String

var message: String


func _init(
	p_success: bool = false,
	p_user: User = null,
	p_access_token: String = "",
	p_message: String = "",
	p_refresh_token: String = ""
) -> void:

	success = p_success
	user = p_user
	access_token = p_access_token
	message = p_message
	refresh_token = p_refresh_token
