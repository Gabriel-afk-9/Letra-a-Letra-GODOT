extends RefCounted
class_name RegisterRequest


var email: String
var password: String
var nickname: String


func _init(
	p_email: String,
	p_password: String,
	p_nickname: String = ""
) -> void:
	email = p_email.strip_edges()
	password = p_password
	nickname = p_nickname.strip_edges()


func to_dictionary() -> Dictionary:
	var data := {
		"email": email,
		"password": password
	}

	if not nickname.is_empty():
		data["nickname"] = nickname

	return data
