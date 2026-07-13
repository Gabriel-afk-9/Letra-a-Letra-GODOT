extends RefCounted
class_name LoginUseCase

var repository: AuthRepository

func _init() -> void:
	repository = AuthRepository.new()

func execute(email: String, password: String) -> Dictionary:
	var result = await repository.login(email, password)
	if result["success"]:
		var auth_manager = Engine.get_main_loop().root.get_node("AuthManager")
		auth_manager.load_profile()
		auth_manager.set_user(result["data"])
	return result
