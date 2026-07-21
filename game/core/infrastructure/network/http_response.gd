extends RefCounted
class_name HttpResponse

var status_code: int
var success: bool
var body: Dictionary
var error_message: String


func _init(
	p_status_code: int = 0,
	p_success: bool = false,
	p_body: Dictionary = {},
	p_error_message: String = ""
) -> void:
	status_code = p_status_code
	success = p_success
	body = p_body
	error_message = p_error_message
