class_name UserUseCase

var repository: UserRepository

func _init() -> void:
	repository = UserRepository.new()

func execute(user_id: String) -> Dictionary:
	return await repository.get_user_by_id(user_id)
