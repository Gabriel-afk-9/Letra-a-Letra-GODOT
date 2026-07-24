extends RefCounted
class_name AuthProvider

func get_token() -> String:
	assert(false, "Must implement AuthProvider.get_token()")
	return ""
