class_name User

var id: String
var email: String
var nickname: String

func _init(p_id: String, p_email: String, p_nickname: String):
	id = p_id
	email = p_email
	nickname = p_nickname

func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"email": email,
		"nickname": nickname
	}

static func from_dictionary(data: Dictionary) -> User:
	return User.new(
		str(data.get("id", "")),
		str(data.get("email", "")),
		str(data.get("nickname", ""))
	)
	
func is_valid() -> bool:
	return not email.is_empty()

func copy() -> User:
	return User.new(id, nickname, email)
