extends RefCounted
class_name RegisterUseCase

var repository: AuthRepository

func _init() -> void:
	repository = AuthRepository.new()

func execute(email: String, password: String) -> Dictionary:
	var result = await repository.register(email, password)
	if result["success"]:
		var auth_manager = Engine.get_main_loop().root.get_node("AuthManager")
		auth_manager.set_user(result["data"])
	return result
