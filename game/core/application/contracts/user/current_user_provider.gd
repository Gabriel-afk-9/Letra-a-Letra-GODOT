extends RefCounted
class_name CurrentUserProvider

func current_user() -> User:
	push_error("CurrentUserProvider.current_user() must be implemented.")
	return null
