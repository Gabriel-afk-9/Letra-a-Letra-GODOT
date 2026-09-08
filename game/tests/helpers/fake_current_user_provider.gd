extends CurrentUserProvider
class_name FakeCurrentUserProvider

var _user: User = null

func _init(p_user: User = null) -> void:
	_user = p_user

func current_user() -> User:
	return _user

func set_user(id: String, nickname: String = "Test") -> void:
	_user = User.new(id, id + "@test.com", nickname)

func set_null() -> void:
	_user = null
