extends RefCounted
class_name RegisterUseCase

var repository: AuthRepository

func _init() -> void:
	repository = AuthRepository.new()

func execute(email: String, password: String) -> Dictionary:
	return await repository.register(email, password)
