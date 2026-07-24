extends RefCounted
class_name ActiveGamesUseCase

var repository: GameRepository

func _init() -> void:
	repository = GameRepository.new()

func execute() -> Dictionary:
	return await repository.get_public_games()
