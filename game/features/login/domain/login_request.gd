extends RefCounted
class_name LoginRequest


var email: String
var password: String


func _init(
	p_email: String,
	p_password: String
) -> void:
	email = p_email.strip_edges()
	password = p_password


func to_dictionary() -> Dictionary:
	return {
		"email": email,
		"password": password
	}
