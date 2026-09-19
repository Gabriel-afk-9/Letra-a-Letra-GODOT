extends RefCounted
class_name LoadingResult

# Resultado do pré-carregamento da Loading Screen.
var success: bool
var failed_group: String
var message: String
var unauthorized: bool


func _init(
	p_success: bool = false,
	p_failed_group: String = "",
	p_message: String = "",
	p_unauthorized: bool = false
) -> void:
	success = p_success
	failed_group = p_failed_group
	message = p_message
	unauthorized = p_unauthorized


static func ok() -> LoadingResult:
	return LoadingResult.new(true)


static func failure(group: String, message: String, unauthorized: bool = false) -> LoadingResult:
	return LoadingResult.new(false, group, message, unauthorized)
