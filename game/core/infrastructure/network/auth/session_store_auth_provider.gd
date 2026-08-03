extends AuthProvider
class_name SessionStoreAuthProvider

var _store: Object

func _init(store: Object) -> void:
	_store = store

func get_token() -> String:
	if _store.has_method("get_token"):
		return _store.get_token()
	return ""
