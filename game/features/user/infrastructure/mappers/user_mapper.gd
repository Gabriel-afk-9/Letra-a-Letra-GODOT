extends RefCounted
class_name UserMapper

static func from_response_body(body: Dictionary) -> User:
	var data: Dictionary = body.get("data", {}) as Dictionary
	var user_variant = data.get("user", {})

	if not user_variant is Dictionary:
		return null

	var user_data: Dictionary = user_variant

	if user_data.is_empty():
		return null

	return User.new(
		str(user_data.get("userId", "")),
		str(user_data.get("email", "")),
		str(user_data.get("nickname", ""))
	)
